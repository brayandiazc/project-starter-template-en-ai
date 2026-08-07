#!/usr/bin/env bash
# git-guardrails.sh — PreToolUse hook that blocks git actions violating the
# branching in CONTRIBUTING.md: commits/merges/pushes on main|master|develop,
# force-push, and creating work branches off main (they must come from develop;
# exceptions: develop itself and hotfix/*). Active by default in settings.json;
# disable it by removing the hook (see docs/conventions/ai-agents.md).
#
# Hook contract: read the event JSON from stdin and return exit 2 to BLOCK the
# tool — the reason (stderr) is shown to the agent. Exit 0 allows. When in
# doubt, fail OPEN (allow) so the workflow isn't stuck.
#
# Coverage: every `git …` invocation in the command (even chained with && or ;),
# honoring `git -C <path>`. Known limitation (fail-open): `cd <other-path> &&
# git …` evaluates the branch of the session's cwd, not the `cd` destination.
set -euo pipefail

payload="$(cat)"

# Extract the Bash command from the event JSON (python3: robust parsing).
cmd="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)"

# We only care about commands that mention git; everything else passes untouched.
case "$cmd" in
  *git*) : ;;
  *) exit 0 ;;
esac

# Analyze the command with shlex: for each git invocation emit a line
# "subcommand<US>force<US>-C-path<US>new-branch<US>base" (US = \x1f; the last two
# fields only apply to branch creation; they are empty for commit/push/merge).
verdicts="$(printf '%s' "$cmd" | python3 -c '
import sys, shlex

try:
    toks = shlex.split(sys.stdin.read())
except ValueError:
    sys.exit(0)  # unparseable command: fail open

SEP = {"&&", "||", ";", "|"}
SEPCH = "\x1f"  # field separator: unlike tab, it does not collapse under IFS
OPT_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
# checkout/switch/branch flags that take their own argument (not positional).
SUB_OPT_WITH_ARG = {"-t", "--track", "-u", "--set-upstream-to"}
# Uses of `git branch` that do NOT create a branch.
BRANCH_NON_CREATE = {"-d", "-D", "--delete", "-m", "-M", "--move", "-c", "--copy",
                     "-l", "--list", "-a", "--all", "-r", "--remotes",
                     "--show-current", "--set-upstream-to", "-u", "--unset-upstream",
                     "--edit-description", "--contains", "--merged", "--no-merged"}

i = 0
while i < len(toks):
    if toks[i] != "git":
        i += 1
        continue
    cdir, sub, force = "", "", "0"
    creates, newbranch, base, positional = False, "", "", []
    non_create_branch = False
    j = i + 1
    while j < len(toks) and toks[j] not in SEP:
        t = toks[j]
        if not sub:
            if t in OPT_WITH_ARG:
                if t == "-C" and j + 1 < len(toks):
                    cdir = toks[j + 1]
                j += 2
                continue
            if t.startswith("-"):
                j += 1
                continue
            sub = t
        else:
            if t in ("--force", "--force-with-lease") or t.startswith("--force-with-lease="):
                force = "1"
            elif t.startswith("-") and not t.startswith("--") and "f" in t and sub == "push":
                force = "1"
            if sub in ("checkout", "switch") and t in ("-b", "-B", "-c", "-C", "--create", "--force-create"):
                creates = True
            elif sub == "branch":
                if t in BRANCH_NON_CREATE:
                    non_create_branch = True
                if t in SUB_OPT_WITH_ARG:
                    j += 2
                    continue
            if not t.startswith("-"):
                positional.append(t)
        j += 1
    if sub == "branch" and not non_create_branch and positional:
        creates = True
    if creates and positional:
        newbranch = positional[0]
        base = positional[1] if len(positional) > 1 else ""
    if sub in ("commit", "push", "merge"):
        print(sub + SEPCH + force + SEPCH + cdir + SEPCH + SEPCH)
    elif creates and newbranch:
        print("create-branch" + SEPCH + "0" + SEPCH + cdir + SEPCH + newbranch + SEPCH + base)
    i = j
' 2>/dev/null || true)"

[ -z "$verdicts" ] && exit 0

protected_re='^(main|master|develop)$'
block() { echo "⛔ git-guardrails: $1" >&2; exit 2; }

while IFS=$'\x1f' read -r sub force cdir newbranch base; do
  [ -z "$sub" ] && continue

  # Branch of the target repo; symbolic-ref resolves it even with no commits. If
  # it is not a git repo (or is in detached HEAD), there is no protected branch.
  if [ -n "$cdir" ]; then
    branch="$(git -C "$cdir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
  else
    branch="$(git symbolic-ref --short -q HEAD 2>/dev/null || true)"
  fi

  # 1. No commits (nor local merges) directly on protected branches.
  if { [ "$sub" = "commit" ] || [ "$sub" = "merge" ]; } && [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]]; then
    block "Don't $sub directly on '$branch'. Changes reach '$branch' through a PR (CONTRIBUTING.md)."
  fi

  # 2. No direct pushes from protected branches, no force-push to anything shared.
  if [ "$sub" = "push" ]; then
    if [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]]; then
      block "Don't push directly from '$branch'. Open a PR from your branch (CONTRIBUTING.md)."
    fi
    if [ "$force" = "1" ]; then
      block "Force-push blocked: rewriting shared history breaks others (CONTRIBUTING.md)."
    fi
  fi

  # 3. Work branches are born from develop, not from main. Only exceptions:
  # creating develop itself (a clone of main) and hotfix/* (CONTRIBUTING.md).
  if [ "$sub" = "create-branch" ] && [ -n "$newbranch" ]; then
    eff_base="$base"
    [ -z "$eff_base" ] && eff_base="$branch"
    if [[ "$eff_base" =~ ^(main|master)$ ]] \
      && [ "$newbranch" != "develop" ] \
      && [[ "$newbranch" != hotfix/* ]]; then
      if git ${cdir:+-C "$cdir"} show-ref --verify -q refs/heads/develop 2>/dev/null; then
        block "Branch '$newbranch' must be born from 'develop', not from '$eff_base'. Use: git checkout -b $newbranch develop (CONTRIBUTING.md)."
      else
        block "Don't create '$newbranch' from '$eff_base': create 'develop' first (git checkout -b develop $eff_base && git push -u origin develop) and branch off from there (CONTRIBUTING.md)."
      fi
    fi
  fi
done <<<"$verdicts"

exit 0

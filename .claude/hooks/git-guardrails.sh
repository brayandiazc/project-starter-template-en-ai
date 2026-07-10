#!/usr/bin/env bash
# git-guardrails.sh — OPT-IN PreToolUse hook that blocks git actions violating
# the branching in CONTRIBUTING.md. Off by default; enable it from settings.json /
# settings.local.json (see docs/conventions/ai-agents.md).
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
# "subcommand<TAB>force<TAB>-C-path" (only for commit/push).
verdicts="$(printf '%s' "$cmd" | python3 -c '
import sys, shlex

try:
    toks = shlex.split(sys.stdin.read())
except ValueError:
    sys.exit(0)  # unparseable command: fail open

SEP = {"&&", "||", ";", "|"}
OPT_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}

i = 0
while i < len(toks):
    if toks[i] != "git":
        i += 1
        continue
    cdir, sub, force = "", "", "0"
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
            elif t.startswith("-") and not t.startswith("--") and "f" in t:
                force = "1"
        j += 1
    if sub in ("commit", "push"):
        print(sub + "\t" + force + "\t" + cdir)
    i = j
' 2>/dev/null || true)"

[ -z "$verdicts" ] && exit 0

protected_re='^(main|master|develop)$'
block() { echo "⛔ git-guardrails: $1" >&2; exit 2; }

while IFS=$'\t' read -r sub force cdir; do
  [ -z "$sub" ] && continue

  # Branch of the targeted repo; symbolic-ref resolves it even without commits.
  # If it's not a git repo (or in detached HEAD), there's no protected branch
  # to guard.
  if [ -n "$cdir" ]; then
    branch="$(git -C "$cdir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
  else
    branch="$(git symbolic-ref --short -q HEAD 2>/dev/null || true)"
  fi

  # 1. No direct commits on protected branches.
  if [ "$sub" = "commit" ] && [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]]; then
    block "Don't commit directly on '$branch'. Create a feat/…|fix/…|docs/…|chore/… branch (CONTRIBUTING.md)."
  fi

  # 2. No direct push from protected branches, and no force-push to anything shared.
  if [ "$sub" = "push" ]; then
    if [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]]; then
      block "Don't push directly from '$branch'. Open a PR from your branch (CONTRIBUTING.md)."
    fi
    if [ "$force" = "1" ]; then
      block "Force-push blocked: rewriting shared history breaks others (CONTRIBUTING.md)."
    fi
  fi
done <<<"$verdicts"

exit 0

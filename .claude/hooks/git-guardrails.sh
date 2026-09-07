#!/usr/bin/env bash
# git-guardrails.sh — PreToolUse hook that blocks git actions violating the
# branching model in CONTRIBUTING.md: commits/merges/pulls-of-another-branch/push
# on main|master|develop, force-push, and creating work branches off main (they
# must be born off develop; exceptions: develop itself and hotfix/*). A merge or
# pull with `--ff-only` passes: it creates no history, it just moves the branch to
# an already published state — that is the post-release back-merge from
# CONTRIBUTING.md. Enabled by default in settings.json; it can be disabled by
# removing the hook (see docs/conventions/ai-agents.md).
#
# Hook contract: reads the event JSON on stdin and returns exit 2 to BLOCK the
# tool — the reason (stderr) is shown to the agent. Exit 0 allows. When in any
# doubt, it fails OPEN (allows) so as not to jam the flow.
#
# Coverage: every `git …` invocation in the command (even chained with && or ;),
# honoring `git -C <path>`. Known limitation (fail-open): `cd <other-path> &&
# git …` evaluates the branch of the session's cwd, not that of the `cd` target.
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

# Parses the command with shlex: for each git invocation it emits one line
# "subcommand<US>force<US>-C-path<US>new-branch<US>base<US>refs" (US = \x1f).
# `new-branch`/`base` only apply to branch creation; `refs` only to push, and it
# carries the refspecs (what is being pushed) so a tag can be told from a branch.
verdicts="$(printf '%s' "$cmd" | python3 -c '
import re, sys, shlex

raw = sys.stdin.read()

# The NEWLINE separates commands just like `&&` or `;`, but shlex.split() treats
# it as whitespace and drops it. Without this, one command`s arguments were
# attributed to the PREVIOUS one: a two-line script
#
#     git checkout -q develop && git pull -q origin develop
#     git checkout -b feat/x
#
# was read as a `git pull` of branch feat/x —which did not even exist yet— and got
# blocked as a "disguised merge". It is the most common sequence there is (sync
# develop and branch off it), and the /instantiate skill prescribes it. A guardrail
# that accuses falsely teaches people to bypass it, and then it stops protecting
# when it is right.
#
# So it tokenizes line by line and interleaves an explicit separator. If some line
# cannot be read on its own —a quoted string spanning several— it falls back to
# parsing the whole command, which is the previous behavior.
#
# It also skips heredoc BODIES: that is content, not commands. A commit message or
# a document mentioning `git push --force` is not force-pushing, and until now the
# hook blocked it (its sibling secret-guardrails already handled the case). It skips
# only up to the delimiter, not the rest of the script: a real command written AFTER
# the heredoc is still analyzed.
def tokenize(text):
    pieces, until = [], None
    for n, line in enumerate(text.split("\n")):
        if until is not None:
            if line.strip() == until:
                until = None
            continue
        try:
            chunks = shlex.split(line)
        except ValueError:
            return None
        if n:
            pieces.append("\n")
        pieces.extend(chunks)
        # \x22 and \x27 are " and : a literal quote here would close the python3 -c.
        m = re.search(r"<<-?\s*[\x22\x27]?([A-Za-z_][A-Za-z0-9_]*)", line)
        if m:
            until = m.group(1)
    return pieces

toks = tokenize(raw)
if toks is None:
    try:
        toks = shlex.split(raw)
    except ValueError:
        sys.exit(0)  # unparseable command: fail open

REDIR = __import__("re").compile(r"^(?:\d*[<>]|&>|>>|<<)")
SEP = {"&&", "||", ";", "|", "\n"}
SEPCH = "\x1f"  # field separator: does not collapse the way tab does in IFS
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
    only_tags_flag = False
    delete_flag = False
    ffonly = False
    non_create_branch = False
    j = i + 1
    while j < len(toks) and toks[j] not in SEP:
        t = toks[j]
        # A bare `git` starts ANOTHER invocation: it is never an argument of this one.
        # Belt and braces in case a separator we did not account for shows up.
        if t == "git":
            break
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
            if t in ("--tags", "--follow-tags") and sub == "push":
                only_tags_flag = True
            if t in ("--delete", "-d") and sub == "push":
                delete_flag = True
            if t in ("--force", "--force-with-lease") or t.startswith("--force-with-lease="):
                force = "1"
            if t == "--ff-only" and sub in ("merge", "pull"):
                ffonly = True
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
            # A REDIRECTION is not a refspec. Without this, `git push origin v1.0 2>&1`
            # left refs="v1.0,2>&1", only_tags() found no tag named "2>&1" and the tag
            # push was blocked as if it moved a protected branch. It happens whenever
            # output is redirected, which is normal when automating.
            if REDIR.match(t):
                break
            if not t.startswith("-"):
                positional.append(t)
        j += 1
    if sub == "branch" and not non_create_branch and positional:
        creates = True
    if creates and positional:
        newbranch = positional[0]
        base = positional[1] if len(positional) > 1 else ""
    if sub == "push":
        # positional[0] is the remote; the rest are the refspecs.
        refs = ",".join(positional[1:])
        if only_tags_flag and not refs:
            refs = "--tags"
        # The `new-branch` field carries the --delete flag on pushes: a delete push
        # does not push the current branch state and follows another rule.
        print(sub + SEPCH + force + SEPCH + cdir + SEPCH + ("1" if delete_flag else "0") + SEPCH + SEPCH + refs)
    elif sub in ("commit", "merge", "pull"):
        # `newbranch` carries the --ff-only flag; `refs` the pull refspecs
        # (positional[0] is the remote), to tell syncing your own branch from
        # pulling ANOTHER branch (a disguised merge).
        pull_refs = ",".join(positional[1:]) if sub == "pull" else ""
        print(sub + SEPCH + force + SEPCH + cdir + SEPCH + ("1" if ffonly else "0") + SEPCH + SEPCH + pull_refs)
    elif creates and newbranch:
        print("create-branch" + SEPCH + "0" + SEPCH + cdir + SEPCH + newbranch + SEPCH + base + SEPCH)
    i = j
' 2>/dev/null || true)"

[ -z "$verdicts" ] && exit 0

protected_re='^(main|master|develop)$'
block() { echo "⛔ git-guardrails: $1" >&2; exit 2; }

# Does this push move only tags? A tag updates no branch, so pushing one from
# `develop` skips no PR — and it is exactly what step 8 of the /release skill asks
# for when release.yml is not active.
only_tags() { # $1 = comma-separated refspecs
  local refs="$1" r
  [ -z "$refs" ] && return 1                 # bare push: moves the current branch
  [ "$refs" = "--tags" ] && return 0
  local IFS=,
  for r in $refs; do
    r="${r#+}"; r="${r%%:*}"                 # drop the force '+' and the destination
    r="${r#refs/tags/}"
    git ${cdir:+-C "$cdir"} show-ref --verify -q "refs/tags/$r" 2>/dev/null && continue
    # PreToolUse evaluates the WHOLE line before anything runs: in
    # `git tag v0.1.0 … && git push origin v0.1.0` the tag does not exist yet when the
    # push is classified, and the refspec fell through as a branch — blocking exactly
    # the /release step 8 that only_tags exists to allow. Anything shaped like a
    # version (v?X.Y.Z, optional suffix) is treated as a tag even if it does not exist
    # yet. A branch named 'v1.2.3' would slip through, but that name does not exist in
    # this flow (feat/*, fix/*, docs/*, chore/*, hotfix/*).
    [[ "$r" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || return 1
  done
  return 0
}

# Does this push only DELETE remote refs? `--delete` turns every refspec into a
# deletion; the old form is the refspec with an empty source (':branch'). Deleting
# an already merged branch is exactly what Git Flow prescribes when you are done, and
# the state you push from is not the destination of the push: it pushes nothing of
# the current branch, so it skips no PR even if run while standing on develop.
only_deletions() { # $1 = --delete flag, $2 = comma-separated refspecs
  local del="$1" refs="$2" r
  [ -z "$refs" ] && return 1
  local IFS=,
  for r in $refs; do
    if [ "$del" != "1" ]; then
      # ':branch' deletes; a bare ':' is "matching branches" and is NOT a deletion.
      case "$r" in :?*) ;; *) return 1 ;; esac
    fi
  done
  return 0
}

# If a protected branch is among the deletions, print it (to block by name).
protected_deletion() { # $1 = --delete flag, $2 = refspecs
  local refs="$2" r
  local IFS=,
  for r in $refs; do
    r="${r#:}"; r="${r#refs/heads/}"
    if [[ "$r" =~ $protected_re ]]; then printf '%s' "$r"; return 0; fi
  done
  return 1
}

while IFS=$'\x1f' read -r sub force cdir newbranch base refs; do
  [ -z "$sub" ] && continue

  # Branch of the target repo; symbolic-ref resolves it even with no commits. If it
  # is not a git repo (or it is in detached HEAD), there is no protected branch to
  # look after.
  if [ -n "$cdir" ]; then
    branch="$(git -C "$cdir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
  else
    branch="$(git symbolic-ref --short -q HEAD 2>/dev/null || true)"
  fi

  # 1. No commits and no merges (explicit or via pull) straight onto protected
  # branches. Exception: `--ff-only` creates no history — it only moves the branch to
  # an already published state, which is precisely the post-release back-merge.
  # Without the exception the hook blocked the safe form and let the dangerous one
  # through: `git pull origin main` on develop was a disguised merge that passed clean.
  if { [ "$sub" = "commit" ] || [ "$sub" = "merge" ] || [ "$sub" = "pull" ]; } && [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]]; then
    ffonly="$newbranch"
    case "$sub" in
      commit)
        block "Do not commit straight onto '$branch'. Changes reach '$branch' via PR (CONTRIBUTING.md)." ;;
      merge)
        [ "$ffonly" = "1" ] || block "Do not merge straight into '$branch': a merge with a commit skips the PR. The post-release back-merge is 'git merge --ff-only origin/main' (it creates no history); if the branches diverged, open the main → develop PR (CONTRIBUTING.md)." ;;
      pull)
        # A bare `git pull` — or one of your own branch — syncs with upstream and
        # passes. Pulling ANOTHER branch is a merge and follows its rules.
        if [ "$ffonly" != "1" ] && [ -n "$refs" ]; then
          other=""
          IFS=, read -ra _prefs <<<"$refs"
          for r in "${_prefs[@]}"; do
            [ "$r" = "$branch" ] || other="$r"
          done
          [ -z "$other" ] || block "Do not 'git pull' '$other' while on '$branch': it is a disguised merge that skips the PR. Use 'git pull --ff-only' for the post-release back-merge, or open the main → develop PR (CONTRIBUTING.md)."
        fi ;;
    esac
  fi

  # 2. No pushing straight from protected branches, and no force-push to anything
  # shared. Exceptions: moving only tags (only_tags) and deleting already merged
  # branches (only_deletions) — unless what is deleted is a protected one, which is
  # what the rule really wants to prevent.
  if [ "$sub" = "push" ]; then
    del="$newbranch"  # on pushes, the field carries the --delete flag
    if only_deletions "$del" "$refs"; then
      if prot="$(protected_deletion "$del" "$refs")"; then
        block "Do not delete the protected branch '$prot' from the remote (CONTRIBUTING.md)."
      fi
    elif [ -n "$branch" ] && [[ "$branch" =~ $protected_re ]] && ! only_tags "$refs"; then
      block "Do not push straight from '$branch'. Open a PR from your branch (CONTRIBUTING.md)."
    fi
    if [ "$force" = "1" ]; then
      block "Force-push blocked: rewriting shared history breaks other people (CONTRIBUTING.md)."
    fi
  fi

  # 3. Work branches are born off develop, not off main. The only exceptions: creating
  # develop itself (a clone of main) and hotfix/* branches (CONTRIBUTING.md).
  # The base is NORMALIZED before comparing: `origin/main`, `remotes/origin/main` and
  # `refs/(heads|remotes/origin)/main` are all main — the most idiomatic form after a
  # fetch (`git checkout -b feat/x origin/main`) used to slip through.
  # Known limitation (fail-open): `git worktree add -b branch path main` is not
  # analyzed; the new worktree falls under these same rules as soon as it is used.
  if [ "$sub" = "create-branch" ] && [ -n "$newbranch" ]; then
    eff_base="$base"
    [ -z "$eff_base" ] && eff_base="$branch"
    eff_base="${eff_base#refs/}"
    eff_base="${eff_base#remotes/}"
    eff_base="${eff_base#heads/}"
    eff_base="${eff_base#origin/}"
    eff_base="${eff_base#upstream/}"
    if [[ "$eff_base" =~ ^(main|master)$ ]] \
      && [ "$newbranch" != "develop" ] \
      && [[ "$newbranch" != hotfix/* ]]; then
      if git ${cdir:+-C "$cdir"} show-ref --verify -q refs/heads/develop 2>/dev/null; then
        block "Branch '$newbranch' must be born off 'develop', not off '$eff_base'. Use: git checkout -b $newbranch develop (CONTRIBUTING.md)."
      else
        block "Do not create '$newbranch' off '$eff_base': first create 'develop' (git checkout -b develop $eff_base && git push -u origin develop) and branch from there (CONTRIBUTING.md)."
      fi
    fi
  fi
done <<<"$verdicts"

exit 0

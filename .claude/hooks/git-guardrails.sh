#!/usr/bin/env bash
# git-guardrails.sh — OPT-IN PreToolUse hook that blocks git actions violating the
# branching in CONTRIBUTING.md. Off by default; enable it from settings.json /
# settings.local.json (see docs/conventions/ai-agents.md).
#
# Hook contract: read the event JSON from stdin and return exit 2 to BLOCK the tool —
# the reason (stderr) is shown to the agent. Exit 0 allows. When in doubt, fail OPEN
# (allow) so the workflow isn't stuck.
set -euo pipefail

payload="$(cat)"

# Extract the Bash command from the event JSON (python3: robust parsing).
cmd="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)"

# We only care about git commands; everything else passes untouched.
case "$cmd" in
  *git\ *) : ;;
  *) exit 0 ;;
esac

# Current branch; symbolic-ref resolves it even in a repo without commits. If this is
# not a git repo (or in detached HEAD), there's no protected branch to guard.
branch="$(git symbolic-ref --short -q HEAD 2>/dev/null || true)"
[ -z "$branch" ] && exit 0

protected_re='^(main|master|develop)$'
block() { echo "⛔ git-guardrails: $1" >&2; exit 2; }

# 1. No direct commits on protected branches.
if printf '%s' "$cmd" | grep -Eq 'git( +-[^ ]+)* +commit' \
   && [[ "$branch" =~ $protected_re ]]; then
  block "Don't commit directly on '$branch'. Create a feat/…|fix/…|docs/…|chore/… branch (CONTRIBUTING.md)."
fi

# 2. No direct push from protected branches, and no force-push to anything shared.
if printf '%s' "$cmd" | grep -Eq 'git( +-[^ ]+)* +push'; then
  if [[ "$branch" =~ $protected_re ]]; then
    block "Don't push directly from '$branch'. Open a PR from your branch (CONTRIBUTING.md)."
  fi
  if printf '%s' "$cmd" | grep -Eq -- '--force([^-]|$)|--force-with-lease|(^| )-[a-zA-Z]*f'; then
    block "Force-push blocked: rewriting shared history breaks others (CONTRIBUTING.md)."
  fi
fi

exit 0

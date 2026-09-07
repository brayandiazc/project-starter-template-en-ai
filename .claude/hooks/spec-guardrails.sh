#!/usr/bin/env bash
# spec-guardrails.sh — PreToolUse hook (Write|Edit|NotebookEdit) that makes specs
# MANDATORY: on feat/* and fix/* branches you cannot touch code unless the matching
# spec exists under specs/ **and is written**. The branch and the spec share a slug:
#   feat/login-google  →  specs/NNNN-login-google/
# "Written" = its proposal.md no longer holds unfilled lines from
# specs/_template/proposal.md (including the CONTINUATIONS of a multi-line
# placeholder), and design.md/tasks.md hold no lines with [like this] placeholders
# from their templates. A folder with the template intact is not a contract.
# Documentation (docs/), specs, tooling (.claude/, .github/, .githooks/) and the
# root Markdown are exempt: they can always be edited.
# Enabled by default in settings.json (see docs/conventions/ai-agents.md).
#
# Hook contract: reads the event JSON on stdin and returns exit 2 to BLOCK — the
# reason (stderr) is shown to the agent. Exit 0 allows.
# When in any doubt, it fails OPEN (allows) so as not to jam the flow.
set -euo pipefail

payload="$(cat)"

file_path="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; ti=json.load(sys.stdin).get("tool_input",{}); print(ti.get("file_path") or ti.get("notebook_path") or "")' \
  2>/dev/null || true)"

[ -z "$file_path" ] && exit 0

dir="$(dirname "$file_path")"
# The folder may not exist yet — that is the NORMAL case when creating a file in a new
# folder: a spec, a component. We climb to the nearest ancestor that does exist, rather
# than falling back to $PWD, which may be ANOTHER repository: if that happens the hook
# reads the wrong branch and its verdict depends on where you are standing, not on the
# file.
while [ ! -d "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "." ] && [ -n "$dir" ]; do
  dir="$(dirname "$dir")"
done
[ -d "$dir" ] || dir="$PWD"

# Root and branch of the target repo; if it is not a git repo, there is no rule to apply.
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && exit 0
branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null || true)"

# The rule only applies to feature/fix branches.
case "$branch" in
  feat/*|fix/*) : ;;
  *) exit 0 ;;
esac

# If the project does not use specs (the folder was deleted), we impose nothing.
[ -d "$root/specs" ] || exit 0

# Exempt paths: the spec itself, documentation and tooling — relative to the root.
# realpath: without canonicalizing, symlinks (e.g. /var → /private/var on macOS)
# prevent trimming the root prefix.
file_path_real="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$file_path" 2>/dev/null || printf '%s' "$file_path")"
rel="${file_path_real#"$root"/}"
case "$rel" in
  specs/*|docs/*|.claude/*|.github/*|.githooks/*) exit 0 ;;
  # Any other nested path follows the rule, including its Markdown: in many projects
  # the .md content IS the product (design/, content/).
  */*) : ;;
  # Root Markdown (README, CHANGELOG, AGENTS…): always editable.
  *.md) exit 0 ;;
esac

# Expected slug: whatever follows the type prefix, with inner / turned into -.
slug="${branch#*/}"
slug="${slug//\//-}"

# Does specs/NNNN-<slug>/ exist (or under specs/archive/)? The numeric prefix is free.
spec_dir=""
for d in "$root/specs/"*"-$slug" "$root/specs/archive/"*"-$slug"; do
  if [ -d "$d" ]; then
    spec_dir="$d"
    break
  fi
done

if [ -z "$spec_dir" ]; then
  echo "⛔ spec-guardrails: branch '$branch' has no spec under specs/. \
No spec, no change (docs/conventions/workflow.md): create the spec first with \
/new-spec '$slug' (it must be named specs/NNNN-$slug/), complete it, and only then \
edit code. If this is pure documentation, use a docs/* branch." >&2
  exit 2
fi

# ── The spec exists: is it written? ──────────────────────────────────────────
# Without the reference template there is nothing to compare against: fail OPEN.
tmpl="$root/specs/_template/proposal.md"
[ -f "$tmpl" ] || exit 0

proposal="$spec_dir/proposal.md"
spec_rel="${spec_dir#"$root"/}"

if [ ! -f "$proposal" ]; then
  echo "⛔ spec-guardrails: '$spec_rel' has no proposal.md. It is the contract of the \
change (problem, goal, scope, roadmap item): copy it from \
specs/_template/proposal.md and complete it before touching code." >&2
  exit 2
fi

# Template lines that are markers to be filled in. If any survives literally in the
# spec file, the spec is still the template.
#
# Two rules (python3: the filter needs to tell structure from content):
#   1. Lines with a [like this] placeholder that are not markdown links. The
#      "- [ ]" checkbox does not count as a placeholder on its own — there are
#      legitimate checkboxes that survive filled in (tasks.md §Documentation).
#   2. Only with "prose": the CONTINUATIONS of a multi-line placeholder — prose
#      lines that are not a heading, quote, table or **like this** label.
#      Without this, filling the first line of "Roadmap item" and leaving the
#      other two intact passed the check (a real regression of proposal.md:6-8).
#      It applies to proposal.md and design.md — all their loose template prose
#      is a placeholder continuation. NOT in tasks.md: its line 3 is instructional
#      prose that survives filled in.
tmpl_markers() { # $1 = template, $2 = "prose" to include continuations
  python3 - "$1" "${2:-}" <<'PY' 2>/dev/null || true
import re, sys
prose = len(sys.argv) > 2 and sys.argv[2] == "prose"
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.rstrip("\n")
    s = line.strip()
    if not s:
        continue
    core = re.sub(r"^-\s*\[[ xX]\]\s*", "", s)
    if "[" in core and "](" not in core:
        print(line)
    elif prose and not (s.startswith(("#", ">", "|")) or re.fullmatch(r"\*\*[^*]+\*\*:?", s)):
        print(line)
PY
}

# check_pending <spec-file> <template> [prose]: blocks if the file still holds
# markers. Missing file or template: fails OPEN.
check_pending() {
  local target="$1" template="$2" mode="${3:-}" markers pending count
  [ -f "$target" ] && [ -f "$template" ] || return 0
  markers="$(tmpl_markers "$template" "$mode")"
  [ -n "$markers" ] || return 0
  pending="$(grep -Fxf <(printf '%s\n' "$markers") "$target" 2>/dev/null || true)"
  [ -z "$pending" ] && return 0
  count="$(printf '%s\n' "$pending" | wc -l | tr -d ' ')"
  echo "⛔ spec-guardrails: '$spec_rel/$(basename "$target")' still holds $count line(s) from \
the template — the spec is not written yet. Complete them (or delete the sections that \
do not apply) before editing code:" >&2
  # The first 5 are enough to orient. sed -n instead of `head` so the pipe is not
  # closed early with pipefail on.
  printf '%s\n' "$pending" | sed -n '1,5s|^|   · |p' >&2
  exit 2
}

check_pending "$proposal" "$tmpl" prose
check_pending "$spec_dir/design.md" "$root/specs/_template/design.md" prose
check_pending "$spec_dir/tasks.md" "$root/specs/_template/tasks.md"

exit 0

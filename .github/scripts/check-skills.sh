#!/usr/bin/env bash
# check-skills.sh — validates the structure of the Claude skills and subagents.
#
# Rules (see .claude/skills/README.md):
#   - Every `.claude/skills/<dir>/SKILL.md` has YAML frontmatter with `name` (in
#     kebab-case and equal to its folder name) and a `description` that is
#     non-empty and usefully long (≥ 40 characters: it must say when to invoke
#     the skill, not just what it is).
#   - Every `.claude/agents/<name>.md` has frontmatter with `name` (equal to the
#     filename without extension) and a non-empty `description`.
#
# Usage:
#   bash .github/scripts/check-skills.sh [repo-root]
#
# Exits 1 if it finds problems. If the repo has no AI layer, there is nothing
# to validate and it exits 0.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

fail=0
err() { echo "❌ $1"; fail=1; }

# Extracts a field from the frontmatter (between the first pair of `---`).
front() { # $1 = file, $2 = field
  awk -v f="$2" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    NR>1 && index($0, f":")==1 {
      sub("^" f ":[[:space:]]*", ""); print; exit
    }
  ' "$1"
}

# ── Skills ────────────────────────────────────────────────────────────────────
if [ -d .claude/skills ]; then
  for dir in .claude/skills/*/; do
    [ -d "$dir" ] || continue
    slug="$(basename "$dir")"
    file="$dir/SKILL.md"
    if [ ! -f "$file" ]; then
      err "skills/$slug: missing SKILL.md"
      continue
    fi
    name="$(front "$file" name)"
    desc="$(front "$file" description)"
    [ "$name" = "$slug" ] || err "skills/$slug: name '$name' does not match the folder"
    printf '%s' "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' \
      || err "skills/$slug: the name is not in kebab-case"
    [ -n "$desc" ] || err "skills/$slug: description empty or missing"
    [ "${#desc}" -ge 40 ] || err "skills/$slug: description too short — it must say when to invoke it"
    # Length: a skill must fit in ~150 lines (.claude/skills/README.md) — the body is
    # loaded whole into context every time the skill activates. No exceptions: even
    # `instantiate` fit, by moving the encyclopedic part to a reference.md that is
    # read at the step that cites it.
    lines="$(wc -l <"$file" | tr -d ' ')"
    [ "$lines" -le 160 ] || err "skills/$slug: SKILL.md has $lines lines (limit ~150 — split the encyclopedic part into a reference.md, see .claude/skills/README.md)"
  done
fi

# ── Subagents ─────────────────────────────────────────────────────────────────
if [ -d .claude/agents ]; then
  for file in .claude/agents/*.md; do
    [ -f "$file" ] || continue
    base="$(basename "$file" .md)"
    [ "$base" = "README" ] && continue
    name="$(front "$file" name)"
    desc="$(front "$file" description)"
    model="$(front "$file" model)"
    [ "$name" = "$base" ] || err "agents/$base: name '$name' does not match the file"
    [ -n "$desc" ] || err "agents/$base: description empty or missing"
    effort="$(front "$file" effort)"
    # The model is DECLARED, always. Without the field the subagent inherits the
    # session's — which is a legitimate choice, but it has to be a choice: half the
    # roster omitted it and nobody noticed, so they all ran on the expensive model
    # without anyone having decided that. `inherit` is still valid; what stops being
    # valid is the silence.
    #
    # Short aliases, `inherit` and full `claude-*` IDs are accepted. Mind the
    # difference, because it matters: **aliases move**. `opus` points at the
    # recommended version of the moment and changes when Anthropic updates it; a full
    # ID pins it. For a subagent you almost always want the alias.
    case "$model" in
      opus | sonnet | haiku | fable | inherit) : ;;
      claude-*) : ;;
      "") err "agents/$base: missing 'model' in the frontmatter — declare it (opus, sonnet, haiku, fable, inherit or a claude-* ID)" ;;
      *) err "agents/$base: model '$model' is not valid (opus, sonnet, haiku, fable, inherit or a claude-* ID)" ;;
    esac
    # `effort` is optional: omitting it is equivalent to `high`. It is only declared
    # when it deviates from that default, so that declaring it means something.
    case "$effort" in
      "" | low | medium | high | xhigh | max) : ;;
      *) err "agents/$base: effort '$effort' is not valid (low, medium, high, xhigh or max)" ;;
    esac
  done
fi

if [ "$fail" -ne 0 ]; then
  echo "→ Fix the frontmatter (see .claude/skills/README.md)."
  exit 1
fi
echo "✅ Skills and agents: frontmatter valid."

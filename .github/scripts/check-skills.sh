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
    [ "$name" = "$base" ] || err "agents/$base: name '$name' does not match the file"
    [ -n "$desc" ] || err "agents/$base: description empty or missing"
  done
fi

if [ "$fail" -ne 0 ]; then
  echo "→ Fix the frontmatter (see .claude/skills/README.md)."
  exit 1
fi
echo "✅ Skills and agents: frontmatter valid."

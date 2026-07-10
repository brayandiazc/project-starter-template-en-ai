#!/usr/bin/env bash
# check-placeholders.sh — verifies the template's `[LIKE_THIS]` placeholders.
#
# Two modes, autodetected:
#   - TEMPLATE mode (TEMPLATE-USAGE.md exists): every placeholder used in the
#     repo must be documented in the TEMPLATE-USAGE.md catalog (§3), either
#     literally or covered by a wildcard like `[*_COMMAND]` or `[LINK_*]`.
#   - INSTANCE mode (TEMPLATE-USAGE.md already deleted): no placeholder may be
#     left unfilled, except in the intentional skeletons.
#
# Usage:
#   bash .github/scripts/check-placeholders.sh [repo-root]
#
# Requires: git, perl. Exits 1 if it finds problems.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

CATALOG="TEMPLATE-USAGE.md"

# Paths skipped in both modes:
#   - skeletons that keep placeholders on purpose (doc templates);
#   - .github/ (its brackets are issue-title prefixes like "[BUG] …");
#   - .claude/ (agent instructions, not project documentation).
SKIP='^(\.github/|\.claude/|docs/conventions/_template\.md|docs/decisions/0000-template\.md|specs/_template/)'

# "Meta" mentions of the placeholder system itself (not placeholders to fill
# in; they appear in the template's instructions).
META='^(PLACEHOLDER|PLACEHOLDERS|BRACKETS_IN_UPPERCASE)$'

# Extract [UPPERCASE] placeholders from a file, ignoring markdown links
# `[TEXT](target)` thanks to the negative lookahead.
extract() {
  perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]{2,})\](?!\()/g) { print "$ARGV:$.: [$1]\n" }' "$1"
}

files() {
  git ls-files '*.md' '.env.example' | grep -Ev "$SKIP" || true
}

if [ -f "$CATALOG" ]; then
  # ── TEMPLATE mode: catalog consistency ─────────────────────────────────────
  # Wildcard prefixes documented in the catalog, e.g. `[LINK_*]` → LINK_,
  # and wildcard suffixes, e.g. `[*_COMMAND]` → _COMMAND.
  prefixes="$(perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]+_)\*\]/g) { print "$1\n" }' "$CATALOG" | sort -u)"
  suffixes="$(perl -CSD -ne 'while (/\[\*(_[A-ZÁÉÍÓÚÑ0-9_\/]+)\]/g) { print "$1\n" }' "$CATALOG" | sort -u)"

  missing=0
  placeholders="$(
    files | grep -v "^$CATALOG$" | while IFS= read -r f; do extract "$f"; done \
      | sed -E 's/^.*\[([^]]+)\]$/\1/' | sort -u
  )"

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%s' "$p" | grep -Eq "$META" && continue
    grep -qF "[$p]" "$CATALOG" && continue
    covered=0
    while IFS= read -r w; do
      [ -n "$w" ] && case "$p" in "$w"*) covered=1 ;; esac
    done <<<"$prefixes"
    while IFS= read -r w; do
      [ -n "$w" ] && case "$p" in *"$w") covered=1 ;; esac
    done <<<"$suffixes"
    [ "$covered" -eq 1 ] && continue
    echo "❌ [$p] is used in the repo but is not in the $CATALOG catalog (§3)."
    missing=1
  done <<<"$placeholders"

  if [ "$missing" -ne 0 ]; then
    echo "→ Add the missing placeholders to the $CATALOG catalog."
    exit 1
  fi
  echo "✅ Placeholders: every one in use is documented in the catalog."
else
  # ── INSTANCE mode: no placeholder may be left unfilled ─────────────────────
  leftovers="$(files | while IFS= read -r f; do extract "$f"; done || true)"
  # Here too, meta mentions don't count as pending.
  leftovers="$(printf '%s' "$leftovers" | grep -Ev '\[(PLACEHOLDER|PLACEHOLDERS|BRACKETS_IN_UPPERCASE)\]' || true)"

  if [ -n "$leftovers" ]; then
    echo "❌ Unfilled placeholders remain:"
    printf '%s\n' "$leftovers"
    echo "→ Fill them in or delete the document if it doesn't apply (the original template ships the guide in TEMPLATE-USAGE.md)."
    exit 1
  fi
  echo "✅ Placeholders: none left unfilled."
fi

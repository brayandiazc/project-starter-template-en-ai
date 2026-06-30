#!/bin/sh
# i18n parity check — STUB.
#
# This is a placeholder. You MUST adapt it to your project's i18n format
# (e.g. JSON, YAML, .po, .arb, .properties) and your locale directory layout
# before relying on it. As shipped it does nothing and exits successfully.
#
# Suggested behavior to implement:
#   1. Pick a reference locale (the source of truth for the key set).
#   2. For each other locale, diff its key set against the reference.
#   3. Print missing and orphaned keys, then exit non-zero if any are found.
#
# Example (JSON locales, requires `jq`):
#   ref=locales/en.json
#   for f in locales/*.json; do
#     [ "$f" = "$ref" ] && continue
#     missing=$(comm -23 \
#       <(jq -r 'keys[]' "$ref" | sort) \
#       <(jq -r 'keys[]' "$f" | sort))
#     [ -n "$missing" ] && printf '%s missing:\n%s\n' "$f" "$missing"
#   done

echo "i18n-parity check.sh is a stub — adapt it to your i18n format."
exit 0

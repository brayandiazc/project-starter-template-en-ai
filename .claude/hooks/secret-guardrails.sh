#!/usr/bin/env bash
# secret-guardrails.sh — OPT-IN PreToolUse hook for Write|Edit that blocks
# agent writes to secret files: the real `.env` and private keys. It turns the
# "never feed secrets to an agent" rule from docs/conventions/ai-agents.md into
# a hard guarantee. Off by default; enable it from settings.json /
# settings.local.json.
#
# Hook contract: read the event JSON from stdin and return exit 2 to BLOCK the
# tool — the reason (stderr) is shown to the agent. Exit 0 allows. When in
# doubt, fail OPEN (allow) so the workflow isn't stuck.
set -euo pipefail

payload="$(cat)"

path="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' \
  2>/dev/null || true)"
[ -z "$path" ] && exit 0

base="$(basename "$path")"
block() { echo "⛔ secret-guardrails: $1" >&2; exit 2; }

case "$base" in
  # Config templates are fine to edit: they are the contract, with no real values.
  .env.example|.env.sample|.env.template) exit 0 ;;
  # The real .env (and variants like .env.local, .env.production) is off-limits.
  .env|.env.*)
    block "Don't write to '$base': real environment values are never touched or read. Edit .env.example instead (docs/conventions/secrets.md)." ;;
  # Private keys and certificates.
  *.pem|*.key|id_rsa|id_rsa.*|id_ed25519|id_ed25519.*|id_ecdsa|id_ecdsa.*)
    block "Don't write to '$base': it looks like a private key or certificate (SECURITY.md)." ;;
esac

exit 0

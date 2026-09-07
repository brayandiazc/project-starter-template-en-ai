#!/usr/bin/env bash
# secret-guardrails.sh — PreToolUse hook (Write|Edit|NotebookEdit|Bash) that blocks
# agent access to secret files: the real `.env` and private keys. It turns the rule
# "never hand secrets to an agent" from docs/conventions/ai-agents.md into a hard
# guarantee. ENABLED by default in settings.json; disable it by removing it from
# there. It is complemented by `permissions.deny` in settings.json, which covers
# direct reads (Read).
#
# For Bash it is declared best-effort: it detects the common ways of reading or
# writing a secret (redirections, cat/sed/cp/tee/source…), not every possible one.
# The goal is to stop the accident, not an adversary.
#
# Hook contract: reads the event JSON on stdin and returns exit 2 to BLOCK the
# tool — the reason (stderr) is shown to the agent. Exit 0 allows. When in any
# doubt, it fails OPEN (allows) so as not to jam the flow.
set -euo pipefail

payload="$(cat)"

block() { echo "⛔ secret-guardrails: $1" >&2; exit 2; }

# Is this a secret file basename? (0 = yes)
is_secret() {
  case "$1" in
    # Config templates are fair game: they are the contract, with no real values.
    .env.example|.env.sample|.env.template) return 1 ;;
    .env|.env.*) return 0 ;;
    *.pem|*.key|id_rsa|id_rsa.*|id_ed25519|id_ed25519.*|id_ecdsa|id_ecdsa.*) return 0 ;;
  esac
  return 1
}

# ── Write / Edit / NotebookEdit: the path comes in the event itself ──────────
path="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; ti=json.load(sys.stdin).get("tool_input",{}); print(ti.get("file_path") or ti.get("notebook_path") or "")' \
  2>/dev/null || true)"

if [ -n "$path" ]; then
  base="$(basename "$path")"
  if is_secret "$base"; then
    case "$base" in
      .env|.env.*) block "Do not write to '$base': real environment values are neither touched nor read. Edit .env.example instead (docs/conventions/secrets.md)." ;;
      *) block "Do not write to '$base': it looks like a private key or certificate (SECURITY.md)." ;;
    esac
  fi
  exit 0
fi

# ── Bash: look for command tokens naming a secret file ───────────────────────
cmd="$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# It only detects uses that read or write the file: a redirection whose target is a
# secret, or a known reader/writer command with a secret as a FILE ARGUMENT. Three
# nuances, all of them real regressions:
#   - In grep/sed/awk the first positional argument is the PATTERN or the program,
#     not a file: `grep -n ".env" .gitignore` searches for the string.
#   - A heredoc (`<<EOF … EOF`) is CONTENT, not arguments: a document mentioning
#     .env thirty times is not reading it. On seeing `<<` analysis stops
#     (fail-open; the output redirection was already evaluated before).
#   - `cp .env.example .env` is the normal setup: it creates the .env from the
#     template, with no real values involved.
# Mentioning the name does not block — `echo .env >> .gitignore` is legitimate and
# frequent. shlex honors quotes; unparseable = fail open.
offense="$(printf '%s' "$cmd" | python3 -c '
import os, re, shlex, sys

try:
    toks = shlex.split(sys.stdin.read())
except ValueError:
    sys.exit(0)

SEP = {"&&", "||", ";", "|"}
READERS = {"cat", "less", "more", "head", "tail", "grep", "egrep", "fgrep",
           "sed", "awk", "cut", "sort", "uniq", "strings", "xxd", "od",
           "source", "."}
WRITERS = {"tee", "cp", "mv", "ln", "install", "dd", "vi", "vim", "nano",
           "code", "open"}
# Their first positional is not a file (pattern, program, inline script).
FIRST_ARG_NOT_A_FILE = {"grep", "egrep", "fgrep", "sed", "awk"}
TEMPLATES = {".env.example", ".env.sample", ".env.template"}

# shlex does not split `;`, `&` or `|` when they are STUCK to the previous token, so
# `printf x > .env.example; ls` leaves the separator inside the name: the basename
# becomes `.env.example;`, stops matching the list of exempt templates and falls into
# `.env.*` → blocked. Writing to `.env.example` is legitimate (it is the contract,
# with no real values) and this prevented it as soon as the command continued on the
# same line. Same family as the git-guardrails parser: punctuation read as part of a
# name.
def clean(b):
    return b.rstrip(";&|")


def secret(b):
    b = clean(b)
    if b in TEMPLATES:
        return False
    if b == ".env" or b.startswith(".env."):
        return True
    if b.endswith((".pem", ".key")):
        return True
    return b in ("id_rsa", "id_ed25519", "id_ecdsa") \
        or b.startswith(("id_rsa.", "id_ed25519.", "id_ecdsa."))

cmdword, prev_redir, args_seen, from_template = None, False, 0, False
for t in toks:
    if t.startswith("<<"):
        sys.exit(0)  # heredoc: what follows is content, not files
    if t in SEP:
        cmdword, prev_redir, args_seen, from_template = None, False, 0, False
        continue
    if re.fullmatch(r"\d*(>>?|<)", t):
        prev_redir = True
        continue
    stuck = re.fullmatch(r"\d*(?:>>?|<)(.+)", t)
    tgt = stuck.group(1) if stuck else (t if prev_redir else None)
    prev_redir = False
    if tgt is not None:
        if secret(os.path.basename(tgt)):
            print(os.path.basename(tgt))
            sys.exit(0)
        continue
    if cmdword is None:
        cmdword = os.path.basename(t)
        continue
    if t.startswith("-"):
        continue
    args_seen += 1
    if cmdword in FIRST_ARG_NOT_A_FILE and args_seen == 1:
        continue
    if os.path.basename(t) in TEMPLATES:
        from_template = True
    if cmdword in READERS or cmdword in WRITERS:
        if secret(os.path.basename(t)):
            if cmdword in ("cp", "mv", "install") and from_template:
                continue  # cp .env.example .env: setup from the template
            print(os.path.basename(t))
            sys.exit(0)
' 2>/dev/null || true)"

if [ -n "$offense" ]; then
  block "The command reads or writes '$offense': real secret values are not touched from the agent (docs/conventions/secrets.md). If you need a new variable, declare it in .env.example and ask the person to set its value."
fi

exit 0

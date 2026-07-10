#!/usr/bin/env bash
# run-tests.sh — tests for the template's scripts and hooks.
# They run in CI (quality.yml workflow) and locally with:
#   bash .github/scripts/tests/run-tests.sh
#
# Requires: git, perl, python3. Exits 1 if any test fails.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GIT_HOOK="$REPO_ROOT/.claude/hooks/git-guardrails.sh"
SECRET_HOOK="$REPO_ROOT/.claude/hooks/secret-guardrails.sh"
CHECK_PLACEHOLDERS="$REPO_ROOT/.github/scripts/check-placeholders.sh"
CHECK_LINKS="$REPO_ROOT/.github/scripts/check-links.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

# check <description> <expected-exit> <actual-exit>
check() {
  if [ "$2" -eq "$3" ]; then
    echo "  ✅ $1"
    pass=$((pass + 1))
  else
    echo "  ❌ $1 (expected exit=$2, got exit=$3)"
    fail=$((fail + 1))
  fi
}

# Simulates the JSON payload of a Bash PreToolUse event.
bash_payload() { printf '{"tool_input":{"command":"%s"}}' "$1"; }
# Simulates the payload of a Write/Edit PreToolUse event.
write_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

# Fixture git repos: one on main, another on a feature branch.
git -C "$TMP" init -q -b main repo-main
git -C "$TMP" init -q -b feat/x repo-feat

# ── git-guardrails.sh ─────────────────────────────────────────────────────────
if [ -f "$GIT_HOOK" ]; then
  echo "git-guardrails.sh:"
  run_git_hook() { (cd "$1" && bash "$GIT_HOOK" <<<"$(bash_payload "$2")" 2>/dev/null); }

  run_git_hook "$TMP/repo-main" "ls -la"; check "non-git command → allows" 0 $?
  run_git_hook "$TMP/repo-main" "git commit -m x"; check "commit on main → blocks" 2 $?
  run_git_hook "$TMP/repo-feat" "git commit -m x"; check "commit on feat branch → allows" 0 $?
  run_git_hook "$TMP/repo-main" "git push origin main"; check "push from main → blocks" 2 $?
  run_git_hook "$TMP/repo-feat" "git push origin feat/x"; check "push from feat → allows" 0 $?
  run_git_hook "$TMP/repo-feat" "git push --force origin feat/x"; check "force-push → blocks" 2 $?
  run_git_hook "$TMP" "git -C $TMP/repo-main commit -m x"; check "git -C <repo on main> commit → blocks" 2 $?
  run_git_hook "$TMP" "git -C $TMP/repo-feat commit -m x"; check "git -C <repo on feat> commit → allows" 0 $?
fi

# ── secret-guardrails.sh ──────────────────────────────────────────────────────
if [ -f "$SECRET_HOOK" ]; then
  echo "secret-guardrails.sh:"
  run_secret_hook() { bash "$SECRET_HOOK" <<<"$(write_payload "$1")" 2>/dev/null; }

  run_secret_hook "/project/.env"; check "write .env → blocks" 2 $?
  run_secret_hook "/project/.env.local"; check "write .env.local → blocks" 2 $?
  run_secret_hook "/project/.env.example"; check "write .env.example → allows" 0 $?
  run_secret_hook "/project/certs/server.pem"; check "write *.pem → blocks" 2 $?
  run_secret_hook "/project/README.md"; check "write README.md → allows" 0 $?
fi

# ── check-placeholders.sh ─────────────────────────────────────────────────────
echo "check-placeholders.sh:"
make_repo() { # $1 = name; creates a git repo at $TMP/$1
  mkdir -p "$TMP/$1" && git -C "$TMP/$1" init -q -b main
}
commit_all() { git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -qm t; }

# Template mode: cataloged placeholder → passes.
make_repo tpl-ok
printf '| `[PROJECT_NAME]` | name |\n' >"$TMP/tpl-ok/TEMPLATE-USAGE.md"
printf '# [PROJECT_NAME]\n' >"$TMP/tpl-ok/README.md"
commit_all "$TMP/tpl-ok"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-ok" >/dev/null); check "template: cataloged → passes" 0 $?

# Template mode: uncataloged placeholder → fails.
make_repo tpl-bad
printf '| `[PROJECT_NAME]` | name |\n' >"$TMP/tpl-bad/TEMPLATE-USAGE.md"
printf '# [NOT_CATALOGED]\n' >"$TMP/tpl-bad/README.md"
commit_all "$TMP/tpl-bad"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-bad" >/dev/null); check "template: uncataloged → fails" 1 $?

# Template mode: the `[*_COMMAND]` wildcard covers TEST_COMMAND → passes.
make_repo tpl-wild
printf '| `[*_COMMAND]` | commands |\n' >"$TMP/tpl-wild/TEMPLATE-USAGE.md"
printf 'Run [TEST_COMMAND]\n' >"$TMP/tpl-wild/README.md"
commit_all "$TMP/tpl-wild"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-wild" >/dev/null); check "template: wildcard covers → passes" 0 $?

# Instance mode: a placeholder remains → fails.
make_repo inst-bad
printf '# My project\nMissing [TEST_COMMAND]\n' >"$TMP/inst-bad/README.md"
commit_all "$TMP/inst-bad"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-bad" >/dev/null); check "instance: pending placeholder → fails" 1 $?

# Instance mode: clean (markdown links [X](y) don't count) → passes.
make_repo inst-ok
printf '# My project\nSee [MIT](LICENSE).\n' >"$TMP/inst-ok/README.md"
commit_all "$TMP/inst-ok"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-ok" >/dev/null); check "instance: clean → passes" 0 $?

# ── check-links.sh ────────────────────────────────────────────────────────────
echo "check-links.sh:"
make_repo links-ok
printf 'See [docs](docs/guide.md) and [web](https://example.com) and [anchor](#usage).\n' >"$TMP/links-ok/README.md"
mkdir -p "$TMP/links-ok/docs" && printf 'hello\n' >"$TMP/links-ok/docs/guide.md"
commit_all "$TMP/links-ok"
(bash "$CHECK_LINKS" "$TMP/links-ok" >/dev/null); check "valid links → passes" 0 $?

make_repo links-bad
printf 'See [docs](docs/does-not-exist.md).\n' >"$TMP/links-bad/README.md"
commit_all "$TMP/links-bad"
(bash "$CHECK_LINKS" "$TMP/links-bad" >/dev/null); check "broken link → fails" 1 $?

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Result: $pass OK, $fail failed."
[ "$fail" -eq 0 ] || exit 1

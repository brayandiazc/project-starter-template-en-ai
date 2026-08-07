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
CHECK_SKILLS="$REPO_ROOT/.github/scripts/check-skills.sh"

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
  run_git_hook "$TMP/repo-main" "git merge feat/x"; check "local merge on main → blocks" 2 $?
  run_git_hook "$TMP/repo-main" "git checkout -b feat/y"; check "create feat/* from main → blocks" 2 $?
  run_git_hook "$TMP/repo-main" "git switch -c fix/z"; check "switch -c fix/* from main → blocks" 2 $?
  run_git_hook "$TMP/repo-main" "git branch feat/y"; check "git branch feat/* on main → blocks" 2 $?
  run_git_hook "$TMP/repo-main" "git checkout -b develop"; check "create develop from main → allows" 0 $?
  run_git_hook "$TMP/repo-main" "git checkout -b hotfix/urgent"; check "create hotfix/* from main → allows" 0 $?
  run_git_hook "$TMP/repo-feat" "git checkout -b feat/z"; check "create branch from feat → allows" 0 $?
  run_git_hook "$TMP/repo-feat" "git checkout -b feat/z main"; check "create branch with explicit main base → blocks" 2 $?
  run_git_hook "$TMP/repo-main" "git branch --list"; check "git branch --list on main → allows" 0 $?
  run_git_hook "$TMP/repo-main" "git checkout feat/x"; check "checkout without creating a branch → allows" 0 $?
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

# ── check-skills.sh ───────────────────────────────────────────────────────────
if [ -f "$CHECK_SKILLS" ]; then
  echo "check-skills.sh:"
  make_skill() { # $1 = repo, $2 = folder, $3 = full frontmatter
    mkdir -p "$TMP/$1/.claude/skills/$2"
    printf '%s\n\nbody\n' "$3" >"$TMP/$1/.claude/skills/$2/SKILL.md"
  }
  DESC_OK="description: Does X. Use this when the user asks for X or Y (e.g. \"do X\")."

  mkdir -p "$TMP/sk-ok"
  make_skill sk-ok my-skill "$(printf -- '---\nname: my-skill\n%s\n---' "$DESC_OK")"
  (bash "$CHECK_SKILLS" "$TMP/sk-ok" >/dev/null); check "valid skill → passes" 0 $?

  mkdir -p "$TMP/sk-mismatch"
  make_skill sk-mismatch my-skill "$(printf -- '---\nname: other-name\n%s\n---' "$DESC_OK")"
  (bash "$CHECK_SKILLS" "$TMP/sk-mismatch" >/dev/null); check "name ≠ folder → fails" 1 $?

  mkdir -p "$TMP/sk-nodesc"
  make_skill sk-nodesc my-skill "$(printf -- '---\nname: my-skill\ndescription: short\n---')"
  (bash "$CHECK_SKILLS" "$TMP/sk-nodesc" >/dev/null); check "short description → fails" 1 $?

  mkdir -p "$TMP/sk-agent/.claude/agents"
  printf -- '---\nname: reviewer\ndescription: Reviews the project diffs.\n---\nbody\n' \
    >"$TMP/sk-agent/.claude/agents/other.md"
  (bash "$CHECK_SKILLS" "$TMP/sk-agent" >/dev/null); check "agent name ≠ file → fails" 1 $?

  mkdir -p "$TMP/sk-none"
  (bash "$CHECK_SKILLS" "$TMP/sk-none" >/dev/null); check "repo without AI layer → passes" 0 $?
fi

# ── check-inheritance.sh ─────────────────────────────────────────────────────────
CHECK_INHERITANCE="$REPO_ROOT/.github/scripts/check-inheritance.sh"
if [ -f "$CHECK_INHERITANCE" ]; then
  echo "check-inheritance.sh:"

  instance() { # $1 = nombre, $2 = fecha de instanciación
    mkdir -p "$TMP/$1/docs/decisions"
    printf 'repo=https://github.com/x/y\ncommit=abc\nfecha=%s\n' "$2" >"$TMP/$1/.template-origin"
  }
  run_inheritance() { (bash "$CHECK_INHERITANCE" "$TMP/$1" > /dev/null 2>&1); }

  # Without .template-origin it is not an instance: the template is untouched.
  mkdir -p "$TMP/hr-plantilla"
  run_inheritance hr-plantilla; check "no .template-origin → allows" 0 $?

  # Freshly instantiated, clean project.
  instance hr-ok 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2026-08-08\n\n- Start.\n' \
    >"$TMP/hr-ok/CHANGELOG.md"
  run_inheritance hr-ok; check "instance limpia → pasa" 0 $?

  # A CHANGELOG version older than the instantiation = inherited.
  instance hr-changelog 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.3.0] - 2026-08-02\n\n- From the template.\n' \
    >"$TMP/hr-changelog/CHANGELOG.md"
  run_inheritance hr-changelog; check "CHANGELOG with older version → fails" 1 $?

  # An ADR older than the instantiation = the template's decision.
  instance hr-adr 2026-08-07
  printf '# 0004. Guardrails\n\n- **Date**: 2026-08-02\n' \
    >"$TMP/hr-adr/docs/decisions/0004-guardrails.md"
  run_inheritance hr-adr; check "ADR with older date → fails" 1 $?

  # …but 0001 is the canonical ADR and IS inherited.
  instance hr-adr-canonico 2026-08-07
  printf '# 0001. Record decisions\n\n- **Date**: 2026-07-01\n' \
    >"$TMP/hr-adr-canonico/docs/decisions/0001-record-architecture-decisions.md"
  run_inheritance hr-adr-canonico; check "canonical ADR 0001 → inherited, passes" 0 $?

  # Files exclusive to the template repository.
  instance hr-parity 2026-08-07
  mkdir -p "$TMP/hr-parity/.github/scripts"
  printf '#!/bin/bash\n' >"$TMP/hr-parity/.github/scripts/check-parity.sh"
  run_inheritance hr-parity; check "leftover check-parity.sh → fails" 1 $?

  # Unreadable date: fails open, does not block the flow.
  mkdir -p "$TMP/hr-fecha"
  printf 'repo=x\nfecha=ayer\n' >"$TMP/hr-fecha/.template-origin"
  run_inheritance hr-fecha; check "invalid date → allows" 0 $?
fi

# ── .github/workflows/ structure ──────────────────────────────────────────────
# GitHub runs ANY .yml/.yaml in that folder, regardless of the rest of the name:
# a `ci.example.yml` actually runs, and passes green without testing anything.
# Whatever must not run cannot end in .yml/.yaml.
WORKFLOWS="$REPO_ROOT/.github/workflows"
if [ -d "$WORKFLOWS" ]; then
  echo ".github/workflows structure:"
  runnable_examples="$(ls "$WORKFLOWS" | grep -Ei '(example|sample|template)\.ya?ml$' || true)"
  [ -z "$runnable_examples" ]
  check "no example workflow ends in .yml/.yaml" 0 $?
  [ -n "$runnable_examples" ] && printf '     · %s\n' $runnable_examples
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Result: $pass OK, $fail failed."
[ "$fail" -eq 0 ] || exit 1

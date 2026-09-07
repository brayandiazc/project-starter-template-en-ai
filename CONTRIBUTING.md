# Contributing Guide

Workflow, branching and commit format for **[PROJECT_NAME]**. The branching and spec
rules are not suggestions: the hooks in `.claude/hooks/` block them deterministically.
By taking part you accept the [Code of Conduct](CODE_OF_CONDUCT.md).

## Environment setup

Follow the install instructions in the [README](README.md#installation). Make sure the tests pass locally before starting work.

Enable the repository's git hooks (**once per clone**; they do not travel in the repo):

```bash
git config core.hooksPath .githooks
```

Two hooks: **`pre-commit` formats** what is staged and re-stages it —it never blocks— and
**`pre-push` runs the same checks as CI** (~15 s) and **does block**. With that you reach
the PR knowing it will pass, which is what makes CI cost a single run per feature.
See [`docs/conventions/quality-tooling.md`](docs/conventions/quality-tooling.md).

## Workflow

We use a simplified **Git Flow**.

### Branching strategy

| Branch     | Purpose                                    | From      | To                   |
| ---------- | ------------------------------------------ | --------- | -------------------- |
| `main`     | Production code. Always stable.            | —         | —                    |
| `develop`  | Feature integration. Pre-release.          | `main`    | `main`               |
| `feat/*`   | New feature.                               | `develop` | `develop`            |
| `fix/*`    | Non-urgent bug fix.                        | `develop` | `develop`            |
| `hotfix/*` | Urgent production fix.                     | `main`    | `main` and `develop` |
| `docs/*`   | Documentation-only changes.                | `develop` | `develop`            |
| `chore/*`  | Maintenance, tooling, configuration tasks. | `develop` | `develop`            |

### Feature flow

```bash
# 1. Start from an up-to-date develop
git checkout develop
git pull origin develop

# 2. Create your branch
git checkout -b feat/descriptive-name

# 3. Work and commit (format below)
git add .
git commit -m "feat: add X"

# 4. Push your branch as many times as needed — this consumes NO CI
git push origin feat/descriptive-name

# 5. When the feature is finished, open the PR toward develop
```

> **Open the PR when the feature is ready, not when you start.** The workflows only
> trigger on `push` to `main`/`develop` and on PR events: while the PR does not exist,
> pushing to your branch **costs zero CI**. With the PR open, on the other hand, every
> push relaunches the whole batch. If you need to open it earlier to take notes, use a
> **draft**.

### Hotfix flow

Hotfixes start from `main`, get merged to `main` and are then synced to `develop`. Since
they go straight to production, they **also publish a version** (always a `patch`): the
cut is done on the hotfix branch itself, before the PR.

```bash
git checkout main
git pull origin main
git checkout -b hotfix/description-of-the-fix
# ... fix + commit ...
# entry in CHANGELOG.md (Unreleased → Fixed) and version cut with /release
git push origin hotfix/description-of-the-fix
# PR toward main → on merging, release.yml publishes the tag and the release
# and afterwards: PR main → develop to sync the fix and the CHANGELOG
```

### Releases

Every merge to `main` publishes a version. The cut is done **before** merging, with the
`/release` skill (it moves `## [Unreleased]` to `## [X.Y.Z] - date`, syncs the manifest
version if the stack has one, and commits); on reaching `main`, the `release.yml` workflow
creates the `vX.Y.Z` tag and the GitHub release with that section's notes.

The `release` job in `quality.yml` blocks PRs toward `main` in three cases: if the topmost
version is already published, if entries are left loose under `## [Unreleased]`, or if
that version is **inherited from the template** rather than the project's. **Nothing
reaches production without a version, and no version belongs to another repository.**

**After merging the release, sync `develop`**: the PR's merge commit leaves it behind
`main` and GitHub starts suggesting an empty PR. Since there is no new content, a
fast-forward is enough (it creates no history and the guardrail allows it):

```bash
git checkout develop && git pull --ff-only origin main
```

That syncs your **local** `develop`; GitHub's stays behind until somebody moves it. A push
from `develop` is blocked (hook and policy), so the remote's fast-forward is done through
the API — without `force`, the server only accepts fast-forwards, which is exactly the
guarantee we want:

```bash
gh api -X PATCH repos/[GITHUB_USER]/[REPOSITORY_SLUG]/git/refs/heads/develop \
  -f sha="$(git rev-parse origin/main)" -F force=false
```

If the fast-forward is not possible, the branches diverged (e.g. a hotfix): then yes, a
`main` → `develop` PR, as in the hotfix flow.

### Branch naming

- Lowercase, with a type prefix and a `kebab-case` description: `feat/login-google`, `fix/payments-timeout`, `docs/update-readme`.

### Branch policies

- **`develop` is the repository's default branch on GitHub**: new PRs and Dependabot's
  point there; `main` only receives merges from `develop` (a release) or `hotfix/*`.
- `main` and `develop` are protected: no direct pushes, only via an approved PR.
- Keep your branch up to date with `develop` (rebase or merge) before opening the PR.

## Code standards

Formatting and indentation are set by [`.editorconfig`](.editorconfig) and the linter;
per-language style, by [`docs/conventions/`](docs/conventions/README.md). The one thing
that cannot be automated: **comment the _why_, not the _what_**, and link to the ADR when
the decision is not obvious.

## Commits and messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <short imperative description>

<optional body>

<optional footer: BREAKING CHANGE, Closes #123>
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

Examples:

```
feat(auth): add login with Google
fix(api): fix timeout on the payments endpoint
docs: update the installation guide
```

## Pull requests

- Use the [PR template](.github/PULL_REQUEST_TEMPLATE.md) (it loads automatically).
- One PR per logical change; keep them small and focused.
- Link the related issues (`Closes #123`).
- Make sure CI passes (tests, linting, build).

## Review

Review here is **of results, not line by line**: tests, the error monitor and uptime as
the automated layer; the admin panel as the inspection layer; and by hand only the data
schema, which is the only thing neither tests nor monitoring catch. The three layers and
the checklist of where generated code fails are in
[`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md).

Before opening the PR, run `/code-review` over the diff. One person is responsible for
every merge: that does not mean reading every line, it means nobody else carries the
outcome.

## Testing

- Accompany every functional change with tests.
- Run the full suite before opening the PR ([TEST_COMMAND]).
- Follow the [testing conventions](docs/conventions/testing.md).

## Spec-driven changes (mandatory)

**Every feature or fix (`feat/*`, `fix/*`) is born from a spec** sharing the branch's slug
(`feat/login-google` ↔ `specs/NNNN-login-google/`); the `spec-guardrails.sh` hook blocks
editing code without it or with the spec half filled in.
The full rule lives in [`docs/conventions/workflow.md`](docs/conventions/workflow.md) and
the spec flow in [`specs/README.md`](specs/README.md) — a single copy of each. Pure
documentation goes on `docs/*` branches (no spec); tooling, on `chore/*`.

## Working with AI agents

Most of this repository's code is written by an agent (see [`AGENTS.md`](AGENTS.md)). That
does not change the flow —same branch, same spec, same PR, same CI— and it requires
respecting [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md): the three
verification layers, never secrets in the agent's context, and a `Co-Authored-By` trailer
on every assisted commit.

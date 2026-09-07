<!--
  Canonical instructions for [PROJECT_NAME]'s agents.
  This is the single source of truth for AI coding agents (Claude Code, Copilot,
  Cursor, etc.). CLAUDE.md imports this file. Keep it concise (<150 lines) and
  include only non-obvious, project-specific guidance — people read the README.
-->

# AGENTS.md — [PROJECT_NAME]

Instructions for the AI coding agents working in this repository.

## Project summary

[One or two lines on what this project is and does.] The full documentation lives in
`docs/` — this file is its only index; read it before any non-trivial work.

## Repository map (read this first)

| You need to know…                         | Read                                                                     |
| ----------------------------------------- | ------------------------------------------------------------------------ |
| How to work here without reviewing code   | [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md)         |
| The work cycle, from spec to release      | [`docs/conventions/workflow.md`](docs/conventions/workflow.md)           |
| Why the product exists and how it is paid | [`docs/product/business-model.md`](docs/product/business-model.md)       |
| What is done and what comes next          | [`docs/product/roadmap.md`](docs/product/roadmap.md)                     |
| Which stack was chosen **here**           | [`docs/architecture/stack.md`](docs/architecture/stack.md)               |
| How the system is built                   | [`docs/architecture/architecture.md`](docs/architecture/architecture.md) |
| Data model                                | [`docs/architecture/database.md`](docs/architecture/database.md)         |
| Authentication and permissions            | [`docs/architecture/auth.md`](docs/architecture/auth.md)                 |
| The API contract                          | [`docs/architecture/api.md`](docs/architecture/api.md)                   |
| Which screens exist and where each one is | [`docs/architecture/screens.md`](docs/architecture/screens.md)           |
| How we write code                         | [`docs/conventions/`](docs/conventions/README.md)                        |
| Why each decision was taken               | [`docs/decisions/`](docs/decisions/README.md)                            |
| Visual identity and tokens                | [`design/`](design/README.md)                                            |
| The design system, for AI agents          | [`DESIGN.md`](DESIGN.md)                                                 |

> **`architecture/` vs `conventions/`**: `architecture/` answers **what this project
> builds** (its data model, its API, its screens); `conventions/` answers **how the work
> is done** (how it is tested, how it is deployed, how secrets are handled). Both are
> filled in when instantiating — the difference is not "reusable vs own" but the question
> they answer. When a topic does not warrant both questions, it lives in a single
> document (auth lives entirely in `architecture/auth.md`, rules included); only the
> database keeps the pair, and each rule lives on exactly one side.

> **Why `design/` is not inside `docs/`**: `docs/` is what you **read** to build;
> `design/` is **consumed** — `design/tokens.css` is imported by the application's CSS.
> When the project has an application, its content will migrate inside it
> (`app/assets/`) and only its guide will stay at the root.

> Always defer to `docs/conventions/` for style and rules — they are the source of
> truth, not your priors.

## Setup & commands

```bash
[INSTALL_DEPENDENCIES_COMMAND]   # install dependencies
[START_DEV_COMMAND]              # run locally
[TEST_COMMAND]                   # run the test suite
[LINT_COMMAND]                   # lint / format
```

## Working agreement

- **Accompany actively.** Ask when scope or priority is ambiguous instead of assuming;
  suggest what the person did not ask for but will need. Priority is set by
  [`docs/product/roadmap.md`](docs/product/roadmap.md).
  The full cycle is in [`docs/conventions/workflow.md`](docs/conventions/workflow.md).
- **No spec, no change (mandatory).** Every feature or fix (`feat/*`, `fix/*`) is born
  from a spec in [`specs/`](specs/README.md) sharing the branch's slug (create it with
  `/new-spec` or delegate to the `architect` subagent), and its `proposal.md` declares
  which roadmap item it completes. The `spec-guardrails.sh` hook guarantees it: with no
  spec —or with a half-filled `proposal.md`— you cannot edit code.
- **Follow Git Flow.** Work branches (`feat/…`, `fix/…`, `docs/…`, `chore/…`) are ALWAYS
  born off `develop`, never off `main` (only `hotfix/*` starts from `main`). If `develop`
  does not exist, create it from `main` and publish it before any work. See
  [`CONTRIBUTING.md`](CONTRIBUTING.md). Never commit directly to `main` or `develop`. The
  `git-guardrails.sh` hook blocks the violations.
- **Code is written in English.** Variables, functions, classes, files, tables, columns
  and paths go in English, regardless of the project's or the conversation's language.
- **Conventional Commits.** `type(scope): summary`. Add the AI co-author line for
  AI-assisted commits (see [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md)).
- **Issues and PRs from the templates.** When creating an issue or a pull request, ALWAYS
  use the templates in [`.github/`](.github) (`ISSUE_TEMPLATE/` and
  `PULL_REQUEST_TEMPLATE.md`) and respect the branching in
  [`CONTRIBUTING.md`](CONTRIBUTING.md). The `/open-issue` and `/open-pr` skills do it for
  you.
- **Tests with every change.** Follow [`docs/conventions/testing.md`](docs/conventions/testing.md).
- **"Done" has a definition.** Before calling a change done, go through
  [`docs/conventions/definition-of-done.md`](docs/conventions/definition-of-done.md).
- **Keep the documentation in sync.** Update the relevant `docs/` and `CHANGELOG.md`;
  record notable decisions as an ADR in `docs/decisions/`.

## Strict rules — never do this

- Never leave a change undocumented: every change updates `CHANGELOG.md` and the affected
  `docs/` in the same PR, and every implemented spec ticks its item in
  [`docs/product/roadmap.md`](docs/product/roadmap.md); every notable decision leaves an
  ADR. A change with no documentation is not done — the `changelog` job in `quality.yml`
  verifies it on every PR.
- Never commit secrets or real `.env` values. See [`SECURITY.md`](SECURITY.md) and
  [`docs/conventions/secrets.md`](docs/conventions/secrets.md).
- Never invent dependencies, files or APIs — verify they exist first.
- Never edit code on a `feat/*`/`fix/*` branch without its spec in `specs/`, nor create
  work branches off `main` — the hooks block those two rules.
- Never bypass authorization checks or weaken security to make something work.
- Never push to `main` or force-push to shared branches.
- Do not reformat unrelated code or make sweeping changes outside the task.

## AI assistants and tooling

- This file is the canonical context and the single documentation index. Tool-specific
  files (`CLAUDE.md`, etc.) point here.
- The subagents live in [`.claude/agents/`](.claude/agents) and the skills in
  [`.claude/skills/`](.claude/skills). **Interviews and anything that requires asking the
  person something go in a skill**: a subagent runs in its own context and has no way to
  ask anything.
- Working method, where to verify and where you fail silently:
  [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md).

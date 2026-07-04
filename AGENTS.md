<!--
  Canonical agent instructions for [PROJECT_NAME].
  This is the single source of truth for AI coding agents (Claude Code, Copilot,
  Cursor, etc.). CLAUDE.md imports this file. Keep it concise (<150 lines) and
  only include non-obvious, project-specific guidance — humans read the README.
-->

# AGENTS.md — [PROJECT_NAME]

Instructions for AI coding agents working in this repository.

## Project overview

[One or two lines on what this project is and does.] Full documentation lives
in [`docs/`](docs/README.md) — read it before non-trivial work.

## Repository map (read these first)

| Need to know…           | Read                                                                     |
| ----------------------- | ------------------------------------------------------------------------ |
| How the system is built | [`docs/architecture/architecture.md`](docs/architecture/architecture.md) |
| Stack & versions        | [`docs/architecture/stack.md`](docs/architecture/stack.md)               |
| Data model              | [`docs/architecture/database.md`](docs/architecture/database.md)         |
| Auth & permissions      | [`docs/architecture/auth.md`](docs/architecture/auth.md)                 |
| API contract            | [`docs/architecture/api.md`](docs/architecture/api.md)                   |
| How we write code       | [`docs/conventions/`](docs/conventions/README.md)                        |
| Why decisions were made | [`docs/decisions/`](docs/decisions/README.md)                            |

> Always defer to `docs/conventions/` for style and rules — they are the source
> of truth, not your priors.

## Setup & commands

```bash
[INSTALL_DEPENDENCIES_COMMAND]   # install dependencies
[START_DEV_COMMAND]              # run locally
[TEST_COMMAND]                   # run the test suite
[LINT_COMMAND]                   # lint / format
```

## Working agreement

- **Plan before large changes.** For non-trivial work, draft a lightweight spec
  in [`specs/`](specs/README.md) (or delegate to the `architect` subagent).
- **Follow Git Flow.** Branch from `develop` as `feat/…`, `fix/…`, etc. See
  [`CONTRIBUTING.md`](CONTRIBUTING.md). Never commit directly to `main`.
- **Conventional Commits.** `type(scope): summary`. Add the AI co-author line
  for AI-assisted commits (see [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md)).
- **Templated issues & PRs.** When creating an issue or a pull request, ALWAYS use the
  [`.github/`](.github) templates (`ISSUE_TEMPLATE/` and `PULL_REQUEST_TEMPLATE.md`) and
  respect the branching in [`CONTRIBUTING.md`](CONTRIBUTING.md). The `/open-issue` and
  `/open-pr` skills do this for you.
- **Tests with every change.** Follow [`docs/conventions/testing.md`](docs/conventions/testing.md).
- **Keep docs in sync.** Update the relevant `docs/` and `CHANGELOG.md`; record
  notable decisions as an ADR in `docs/decisions/`.

## Hard rules — never do these

- Never commit secrets or real `.env` values. See [`SECURITY.md`](SECURITY.md)
  and [`docs/conventions/secrets.md`](docs/conventions/secrets.md).
- Never invent dependencies, files, or APIs — verify they exist first.
- Never bypass authorization checks or weaken security to make something work.
- Never push to `main` or force-push shared branches.
- Don't reformat unrelated code or make sweeping changes outside the task.

## AI assistants & tooling

- This file is the canonical context. Tool-specific files (`CLAUDE.md`, etc.)
  point here.
- Reusable subagents live in [`.claude/agents/`](.claude/agents) and skills in
  [`.claude/skills/`](.claude/skills) — they are **examples**; adapt or delete
  them per project.
- Rules for working with AI: [`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md).

# How to use this template

This guide explains how to turn this template into your project's real documentation. Once instantiated, **you can delete this file** (`TEMPLATE-USAGE.md`).

## 1. What it is and what it isn't

- **It is** a documentation base ready to start any project: folder structure, governance files, and document skeletons with placeholders.
- **It is not** a code boilerplate, nor is it tied to a specific stack. It includes no dependencies or language-specific configuration — your project provides that.
- This variant is the **AI-ready** one: on top of the documentation base it adds agent instructions, reusable subagents/skills, and a lightweight spec flow. See §9. If you don't want any AI tooling, use the no-AI variant (also in §9).

## 2. Instantiate the template

**Option A — GitHub (recommended):** click **"Use this template" → Create a new repository**. GitHub copies the content without the commit history.

**Option B — Clone and reset the history:**

```bash
git clone [THIS_TEMPLATE_URL] my-project
cd my-project
rm -rf .git
git init
```

## 3. Replace the placeholders

All placeholders use the `[BRACKETS_IN_UPPERCASE]` format. Find them with:

```bash
grep -rno '\[[A-Z0-9_/]\+\]' --include='*.md' --include='.env.example' .
```

### Placeholder catalog

| Placeholder                                        | Meaning                                          |
| -------------------------------------------------- | ------------------------------------------------ |
| `[PROJECT_NAME]`                                   | Project name                                     |
| `[COMPANY_NAME]`                                   | Company or organization name                     |
| `[AUTHOR]`                                         | Author or lead maintainer name                   |
| `[GITHUB_USER]`                                    | GitHub user or organization                      |
| `[REPOSITORY_URL]`                                 | Repository URL                                   |
| `[YEAR]`                                           | Copyright year in the license                    |
| `[VERSION]`                                        | Version (of a dependency or the project)         |
| `[DATE]`                                           | Date (`YYYY-MM-DD` format)                       |
| `[SUPPORT_EMAIL]`                                  | Contact/support email                            |
| `[SECURITY_EMAIL]`                                 | Email to report vulnerabilities                  |
| `[RUNTIME]`                                        | Language/runtime (Node.js, Python, Ruby…)        |
| `[PACKAGE_MANAGER]`                                | npm, pnpm, bundler, pip…                         |
| `[DATABASE]`                                       | PostgreSQL, MySQL, MongoDB…                      |
| `[PORT]`                                           | Local development port                           |
| `[*_COMMAND]`                                      | Project commands (install, test, build, deploy…) |
| `[DEV_URL]` / `[STAGING_URL]` / `[PRODUCTION_URL]` | URLs per environment                             |
| `[SERVICE/API]`, `[LINK_*]`, `[OTHER_*]`           | Resources specific to your project               |

> Keep this catalog up to date: any new `[PLACEHOLDER]` you introduce should appear here.

> The Spanish variant uses the same placeholders translated into Spanish (e.g. `[PROJECT_NAME]` → `[NOMBRE_DEL_PROYECTO]`). You replace them with real values either way.

## 4. Recommended fill-in order

1. `README.md` — the project's front page.
2. `docs/architecture/stack.md` — define the stack.
3. `docs/architecture/architecture.md` — high-level view.
4. `docs/architecture/database.md` — data model.
5. `docs/architecture/auth.md` — authentication and authorization.
6. `docs/architecture/api.md` — API contract.
7. `docs/architecture/design.md` — technical / UI-UX design.
8. `docs/product/business-model.md` — business model.
9. `docs/product/roadmap.md` — roadmap.
10. `docs/decisions/` — create an ADR whenever you make a relevant decision.

## 5. File inventory

| File                          | Purpose                        | Required?                 |
| ----------------------------- | ------------------------------ | ------------------------- |
| `README.md`                   | Project front page             | Yes                       |
| `CONTRIBUTING.md`             | How to contribute and Git flow | Recommended               |
| `CODE_OF_CONDUCT.md`          | Code of conduct                | Recommended               |
| `SECURITY.md`                 | Security policy                | Recommended               |
| `CHANGELOG.md`                | Change history                 | Recommended               |
| `LICENSE`                     | License                        | Yes                       |
| `.env.example`                | Environment-variable contract  | If there is configuration |
| `.gitignore`, `.editorconfig` | Repo hygiene                   | Recommended               |
| `.github/`                    | Issue/PR templates, automation | Optional                  |
| `docs/architecture/*`         | Technical documentation        | As needed                 |
| `docs/product/*`              | Business and roadmap           | As needed                 |
| `docs/decisions/*`            | Decision log (ADR)             | Recommended               |
| `docs/conventions/*`          | Working conventions            | As needed                 |

### What to delete if it doesn't apply

- Conventions in `docs/conventions/` you don't use (e.g. `i18n.md` if you don't internationalize).
- Sections of `README.md` that don't apply (e.g. the Deployment table).
- Documents in `docs/architecture/` that don't correspond (e.g. `api.md` if you don't expose an API).
- The example workflows in `.github/workflows/` if you don't use GitHub Actions.

## 6. `architecture/X.md` vs `conventions/X.md`

There are two documents about "database" and two about "authentication", **on purpose**:

- `docs/architecture/database.md` describes **your project's data model** (entities, relationships, ERD). It changes per project.
- `docs/conventions/database.md` describes the **reusable rules** for how you model data (naming, indexes, types). It is cross-cutting.

The same distinction applies to `architecture/auth.md` (how it works here) vs `conventions/authentication.md` (authentication rules).

## 7. Adapt by project type

This template is **multi-platform**: the core (governance, architecture, decisions, product, and most conventions) applies equally to web, mobile, and desktop projects. What changes is a handful of web-leaning documents. Adjust to your case:

### Web

- Works as is. Take advantage of `conventions/seo.md`, `conventions/views-and-layouts.md`, `conventions/transactional-emails.md`, and `architecture/api.md`.

### Mobile (iOS / Android / cross-platform)

- **Delete**: `conventions/seo.md`.
- **Refocus**: `conventions/views-and-layouts.md` → navigation and screens; `architecture/api.md` → API consumption (your app is usually a client); `conventions/deploy.md` → App Store / Play Store publishing; the `README` _Deployment_ table → channels/tracks (beta, production).
- **Create** (with [`_template.md`](docs/conventions/_template.md)): store releases (versioning, signing/code-signing, screenshots and ASO), device permissions, push notifications, offline mode.

### Desktop (Electron / Tauri / native)

- **Delete**: `conventions/seo.md`.
- **Refocus**: `conventions/views-and-layouts.md` → windows and views; `conventions/deploy.md` → packaging and installers; the `README` _Deployment_ table → signed releases.
- **Create**: per-OS packaging, code signing and notarization, auto-update, telemetry / crash reporting.

> In all cases the general rule applies: **delete what doesn't apply** and create new conventions with `docs/conventions/_template.md`. There is a list of suggested optional conventions in [`docs/conventions/README.md`](docs/conventions/README.md).

## 8. Keep the documentation alive

- Update the **"Last updated: [DATE]"** line when you edit a document.
- Record every relevant architectural decision as an **ADR** in `docs/decisions/` (see its [README](docs/decisions/README.md)).
- Keep `CHANGELOG.md` up to date following [Keep a Changelog](https://keepachangelog.com/en/).
- Additional conventions (payments, webhooks, multi-tenancy, PWA, etc.) can be added using [`docs/conventions/_template.md`](docs/conventions/_template.md).

## 9. The AI layer

This is the **AI-ready** variant. On top of the documentation base it adds:

- **[`AGENTS.md`](AGENTS.md)** — the canonical instruction file for any AI coding
  agent. **[`CLAUDE.md`](CLAUDE.md)** is a one-line bridge that imports it (Claude
  Code reads `CLAUDE.md`; other tools read `AGENTS.md` — same content, two names).
- **[`.claude/agents/`](.claude/agents)** — example **subagents** (architect,
  code-reviewer, test-author, doc-keeper, security-reviewer, debugger, explorer).
- **[`.claude/skills/`](.claude/skills)** — example **skills** (new-adr, new-spec,
  commit, open-pr, seo-audit, i18n-parity, design-system-audit, copywriting,
  changelog, accessibility-audit, refactor, migration-guard).
- **[`specs/`](specs/README.md)** — a lightweight spec-driven flow for non-trivial
  changes.
- **[`docs/conventions/ai-agents.md`](docs/conventions/ai-agents.md)** — the rules
  for working with AI (review, secrets, attribution).

> The subagents and skills are **examples**: they stay stack-agnostic by deferring
> to your `docs/`. Adapt or delete them per project. Need a heavier, formal
> spec process? See the alternatives noted in [`specs/README.md`](specs/README.md).

### Variants in this family

- 🇬🇧 English with AI: this repository (`project-starter-template-en-ai`).
- 🇪🇸 Spanish with AI: <https://github.com/brayandiazc/project-starter-template-es-ai>
- 🇬🇧 English without AI: <https://github.com/brayandiazc/project-starter-template-en>
- 🇪🇸 Spanish without AI: <https://github.com/brayandiazc/project-starter-template-es>

# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

This is the CHANGELOG of the template repo [brayandiazc/project-starter-template-en-ai](https://github.com/brayandiazc/project-starter-template-en-ai).
It is reset when you instantiate: your project inherits the template's
tooling, not its life (see `TEMPLATE-USAGE.md`).

## [Unreleased]

### Added

- **`check-git-flow.sh` — that `develop` exists on the remote.** `CONTRIBUTING.md`
  requires every working branch to be born from `develop` and `AGENTS.md` repeats it;
  nothing checked it. A `develop` that only exists locally satisfies the rule when you
  branch and breaks it when you open the PR: `gh pr create --base develop` fails with
  "Base ref must be a branch", and the obvious way out of that error — opening it against
  `main` — is exactly what the convention forbids. The failure landed late and its
  apparent fix broke the flow.
- **`check-workflow-identity.sh` — that no workflow claims to be another repository.**
  Template-repo-only workflows are gated with `if: github.repository == 'user/repo'`.
  When one is copied between repositories that condition travels along as is, and then
  the job does not fail: it **skips**. In a PR's checks list a grey "skipping" reads
  almost like a green, so a check can go months without running once. It only has an
  opinion in the template repo: in an instance, the condition names the template on
  purpose.

  The two are the same criterion said twice: **a rule that only lives in prose does not
  hold**, and a check that does not run is worse than one that fails, because the failing
  one tells you. The test bench goes from 280 to 292 cases.

## [2.0.0] - 2026-09-07

### Added

- **`design/` — visual identity with semantic tokens**, plus `DESIGN.md` at the root
  (generated from `design/tokens.css`, never by hand) so any AI agent can read the design
  system. **Framework-agnostic on purpose**: the tokens are standard CSS custom
  properties and the hook into a specific library lives in a single block marked as an
  adapter, which you replace. Design can be built however you like.
  With them come `docs/architecture/screens.md` (view map), the `designer` subagent and
  the `/identity` and `/prototype` skills.
- **`spec-guardrails.sh`**: with no spec in `specs/` —or with a half-filled
  `proposal.md`— you cannot edit code on `feat/*` or `fix/*`. With it, `specs/` stops
  being a recommendation.
- **Seven new checks**, because a rule that is only kept by reading is not kept:
  `check-changelog`, `check-design-tokens`, `check-hooks-enabled`, `check-instructions`,
  `check-project-tests`, `check-release` and `design-md.sh`. The test bench goes from
  zero to 280 cases.
- **`.githooks/pre-commit` and `pre-push`**: the same checks as CI, before pushing.
  Locally they are free; in Actions, they are minutes.
- **`docs/conventions/workflow.md`** — the full work cycle, from spec to release. It does
  not say what to build nor with what: that belongs to the project.

### Changed

- **`architecture/` answers what the project builds; `conventions/`, how the work is
  done.** The pairs that were always filled in and pruned together got merged.

  **If you are updating a project that already used an earlier version, this table is
  what has to be applied by hand.** A renamed document is not replaced: **it is
  duplicated**. Both stay —yours with content and the new one empty—, both are valid
  markdown, the links resolve and no check detects it.

  | Before                                  | Now                            | What to do with your content                                                                                                                            |
  | --------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `docs/architecture/design.md`           | `docs/architecture/screens.md` | Migrate the screen map and delete the old one. `design.md` is now reserved for each spec's **technical** design (`specs/*/design.md`)                   |
  | `docs/conventions/design-system.md`     | `docs/conventions/ui.md`       | Merge: `ui.md` gathers design system, brand and layouts                                                                                                 |
  | `docs/conventions/branding.md`          | `docs/conventions/ui.md`       | Same                                                                                                                                                    |
  | `docs/conventions/views-and-layouts.md` | `docs/conventions/ui.md`       | Same                                                                                                                                                    |
  | `docs/conventions/authentication.md`    | `docs/architecture/auth.md`    | Move the cross-cutting rules into `auth.md`'s "Rules" section and delete the old one. The pair was filled in and pruned together — the same table twice |
  | `docs/README.md`                        | `AGENTS.md`                    | It was a second copy of the documentation map, and the two drifted apart                                                                                |
  | `docs/glossary.md`                      | —                              | Removed (orphan). If yours has content, move it to `docs/product/business-model.md`                                                                     |
  | `.claude/skills/refactor/`              | —                              | Removed: it duplicated the `/simplify` builtin. If your copy has its own rules, move them to `docs/conventions/`                                        |
  | `.claude/agents/explorer.md`            | —                              | Removed: it duplicated the built-in `Explore` agent                                                                                                     |
  | `.claude/agents/code-reviewer.md`       | —                              | Removed: it duplicated the built-in `/code-review` skill                                                                                                |
  | `.github/labeler.yml`                   | —                              | Removed: orphan configuration; no workflow read it                                                                                                      |

- **`docs/architecture/stack.md` is the single source of the stack**, with the why behind
  each choice in `docs/decisions/`. The conventions no longer point at any catalog: this
  template **documents the decisions of whoever uses it, it does not propose stacks**.
- **The two principles of working with AI** —verify > recall; fewer unreviewed decisions
  = less risk— move to `conventions/ai-agents.md`, which is what they are about.
- **`AGENTS.md` is the single documentation index.** `docs/README.md` was a second copy
  of the same map, and the two drifted apart.
- **Every subagent declares its model**, and the template leaves them all on `inherit`:
  the allocation depends on your plan, not on this template. The criterion for going up
  or down —"does the error get caught on its own?"— is in `conventions/ai-agents.md`.
- **The service variables in `.env.example` go by category, not by provider**
  (`PAYMENTS_API_KEY`, `STORAGE_*`, `ERROR_TRACKING_DSN`…), and `scripts/backup-db.sh`
  speaks generic S3 instead of naming a provider.

### Deprecated

### Removed

- The `explorer` and `code-reviewer` subagents and the `/refactor` skill: they
  **duplicated functionality Claude Code ships out of the box** (`Explore`,
  `/code-review`, `/simplify`), in poorer versions.
- `docs/glossary.md` (orphan: nothing referenced it) and `.github/labeler.yml`
  (82 lines of configuration for an auto-labeling workflow that never existed — no
  workflow read it).
- `.github/FUNDING.yml`, `.github/CODEOWNERS.example` and the `support_question` and
  `documentation_request` issue templates. Bug, feature and task remain.

### Fixed

- **Two `quality.yml` steps carried no `!cancelled()`** and hid the ones after them when
  they failed: the point of the single job is to see every problem at once.
- **`check-design-tokens.sh` could only read one framework.** It now detects the
  **notation** —hyphenated utility, preprocessor variable, custom property— instead of a
  library, so a project that does not use the template's stops passing green without a
  single one of its violations being looked at. And it does not swallow the system's own
  tokens: `--neutral` is a role, not a color.

### Security

## v1.4.0 and earlier

The history up to `v1.4.0` lives in the repository's [release notes](https://github.com/brayandiazc/project-starter-template-en-ai/releases).
It is not reconstructed here: making it up would be worse than not having it.

<!--
Version comparison links:
[Unreleased]: https://github.com/brayandiazc/project-starter-template-en-ai/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/brayandiazc/project-starter-template-en-ai/compare/v1.4.0...v2.0.0
-->

---
name: instantiate
description: Instantiates this template into a real project through a guided interview — it detects whether the project is new or existing, fills in the placeholders, adapts the docs to the project type and decides the permissions policy. Use this when the user clones/adopts this template and wants to configure it for their project (e.g. "instantiate this template", "set this template up for my project", "start the project from this base").
---

Turn this template into a real project's documentation through an interview.
Read `TEMPLATE-USAGE.md` first: it is the source of truth for the placeholder catalog
(§3), the deletion rules by type (§7) and the adoption flow (§2). Follow that document
if it differs from the steps below.

## Step 0 — Safety guard (before anything)

Stop and warn if you are on the template's SOURCE REPO (not an instance):

- Check `git remote -v`. If origin is the template repository
  (`project-starter-template-en-ai`), do NOT instantiate: you would be destroying the
  template.
- In that case, ask explicitly whether the original template is really meant to be
  modified before continuing.

## Step 1 — Detect the context (new vs. existing)

Without asking yet, inspect the repo to infer the context:

- Is there real code? (`package.json`, `Gemfile`, `pyproject.toml`, `go.mod`, `src/`, …)
- Does the git history have the project's own commits, or is it a freshly started clone?
- Are the `[PLACEHOLDERS]` still intact?
  (`grep -rno '\[[A-Z0-9_/]\+\]' --include='*.md' .`)

Infer **NEW** (empty repo / intact placeholders) or **EXISTING** (there is code already).

## Step 2 — Confirm and interview (use AskUserQuestion)

Show your Step 1 inference and let it be corrected. Then ask ONLY what you cannot infer.
In existing projects, pre-fill the answers by reading the code.

- **Batch A · Context and type:** new/existing; type (Web · Mobile · Desktop ·
  API/service · Library).
- **Batch B · Identity:** name, author, GitHub user/org, company (optional), support
  email, security email, license and year. Infer author/user from `git config` and the
  year from the system date.
- **Batch C · Stack:** runtime, package manager, database (or "none"), port, commands
  (install / dev / test / lint). In an existing project: READ it from the code, do not ask.
- **Batch D · Capabilities:** API? authentication? i18n? SEO/public web? transactional
  emails? design system/UI? (Every "no" means deleting its convention.)
- **Batch E · Permissions:** keep the conservative `ask:[Bash]` in
  `.claude/settings.json`, or create `.claude/settings.local.json` with a read-only
  allowlist?

  The **three guardrails** (git, secrets and specs) ship **enabled**: they are only
  touched if the person expressly asks, and then it is written down in the Step 6 ADR.

  Also enable the clone's git hooks, which do not travel in the repository:
  `bash .github/scripts/check-hooks-enabled.sh --fix`. Without that, `pre-commit` does
  not format and `pre-push` does not verify: failures get found in CI.

## Step 3 — Fill in / merge depending on the context

Replace the catalog placeholders (`TEMPLATE-USAGE.md §3`) with the answers:
`[PROJECT_NAME]`, `[AUTHOR]`, `[GITHUB_USER]`, `[COMPANY_NAME]`, `[REPOSITORY_URL]`,
`[YEAR]`, `[SUPPORT_EMAIL]`, `[SECURITY_EMAIL]`, `[RUNTIME]`, `[PACKAGE_MANAGER]`,
`[DATABASE]`, `[PORT]`, `[*_COMMAND]`, `[*_URL]`, `[DATE]`.

Files that get updated: `README.md`, `AGENTS.md` (summary + commands),
`docs/architecture/*`, `docs/product/*`, `.env.example`, `LICENSE` (year + author),
`SECURITY.md` (emails), `CHANGELOG.md` (first entry).

- **NEW:** write straight from the answers. Work in the repo as it is.
- **EXISTING:** read the code and infer so no `[…]` is left. Do **NOT overwrite**
  `README.md`, `LICENSE` or `.gitignore` — propose the merge by hand. Work on a
  `chore/adopt-doc-template` branch. Suggest running `/init` to integrate the code's
  context.

Also write `.template-origin` at the root so `/update-template` can bring future
template improvements:

```
repo=<URL of this template>
commit=<SHA of the template HEAD used as the base>
date=<YYYY-MM-DD of today>
```

## Step 4 — Apply the permissions decision (Batch E)

If "automatic" was chosen, create `.claude/settings.local.json` with an allowlist of
read-only commands (`ls, cat, head, tail, wc, grep, rg, find, tree, sort, uniq, echo,
pwd, which`, and `git status/log/diff/branch/show/remote`). Verify that
`.claude/settings.local.json` is in `.gitignore`. If "conservative" was chosen, do not
touch permissions at all.

## Step 5 — Cleanup by type (TEMPLATE-USAGE.md §7 rule)

Delete the docs/conventions that do not apply:

- Mobile / Desktop → delete `docs/conventions/seo.md`; refocus `ui`, `api`, `deploy`.
- API / Library → delete the UI docs (`conventions/seo.md`, `conventions/ui.md`,
  `architecture/screens.md`) and the `design/` folder with `DESIGN.md`.
- Every capability answered "no" in Batch D → delete its convention (e.g. no i18n →
  `docs/conventions/i18n.md`) **and its associated skill**: no i18n → `i18n-parity`; no
  database → `migration-guard`; no SEO/public web → `seo-audit`; no UI (API or library)
  → `design-system-audit`, `accessibility-audit`, `copywriting`, `identity`, `prototype`
  and the `designer` subagent.
- **Always** delete the files exclusive to the template repo: the
  `.github/workflows/template-parity.yml` workflow, the `.github/scripts/check-parity.sh`
  script and the `.claude/skills/port-change/` skill — they only serve to maintain the
  family of variants, not an instantiated project.

Ask before deleting in bulk if there is any ambiguity.

## Step 6 — Close

Record the instantiation as ADR `0002` (use `docs/decisions/0000-template.md`): the
project's context, chosen stack, type, deleted conventions and the permissions/guardrails
policy — that way the project opens its own decision log.

Show a summary of the diff and the list of placeholders that still need a human
decision. Do NOT commit — let the person review. In "existing", remind them everything
is on the branch, ready for a PR. Suggest deleting `TEMPLATE-USAGE.md` when done.

Example: `/instantiate` → interview → a repo with real documentation and pruned `docs/`.

Do NOT instantiate over the template's source repo (Step 0), do NOT overwrite production
code in existing projects, do NOT commit or push on your own, and do NOT invent data: if
you cannot infer a value and the person does not provide it, leave the placeholder and
**mark it as pending on its line** —`[SECURITY_EMAIL] <!-- pending: no mailbox yet -->`,
or with `#` inside a code block—. `check-placeholders.sh` tells apart what you decided to
leave from what you forgot; without the mark, it fails.

And do not leave the template's CHANGELOG or ADRs: they belong to another repository.
Reset the CHANGELOG keeping its `## [Unreleased]` (without an entry,
`check-changelog.sh` blocks the first PR) and delete every ADR except `0001`.
`check-inheritance.sh` verifies it.

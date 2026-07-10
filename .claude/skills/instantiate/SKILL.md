---
name: instantiate
description: Instantiates this template into a real project through a guided interview — detects whether the project is new or existing, fills in the placeholders, adapts the docs to the project type, and decides the permissions policy. Use this when someone clones/adopts this template and wants to configure it for their project (e.g. "instantiate this template", "set up this template for my project", "bootstrap the project from this base").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Turn this template into a project's real documentation through an interview.
Read `TEMPLATE-USAGE.md` first: it is the source of truth for the placeholder catalog (§3),
the delete-by-type rules (§7), and the adoption flow (§2). Follow that document if it
differs from the steps below.

## Step 0 — Safety guard (before anything)

Stop and warn if you are on the template SOURCE repo (not an instance):

- Check `git remote -v`. If the origin is the template repository
  (`project-starter-template-en-ai`), do NOT instantiate: you would be destroying the
  template.
- In that case, explicitly ask whether the person really wants to modify the original
  template before continuing.

## Step 1 — Detect context (new vs. existing)

Without asking yet, inspect the repo to infer the context:

- Is there real code? (`package.json`, `Gemfile`, `pyproject.toml`, `go.mod`, `src/`, etc.)
- Does the git history have the project's own commits, or is it a freshly initialized clone?
- Are the `[PLACEHOLDERS]` still intact? (`grep -rno '\[[A-Z0-9_/]\+\]' --include='*.md' .`)

Infer **NEW** (empty repo / placeholders intact) or **EXISTING** (code already present).

## Step 2 — Confirm and interview (use AskUserQuestion)

Show your Step 1 inference and let it be corrected. Then ask ONLY what you can't infer.
For existing projects, pre-fill answers by reading the code.

- **Batch A · Context and type:** new/existing; type (Web · Mobile · Desktop ·
  API/service · Library).
- **Batch B · Identity:** name, author, GitHub user/org, company (optional),
  support email, security email, license and year. Infer author/user from
  `git config` and the year from the system date.
- **Batch C · Stack:** runtime, package manager, database (or "none"), port,
  commands (install / dev / test / lint). For existing: READ it from the code, don't ask.
- **Batch D · Capabilities:** API? auth? i18n? SEO/public web? transactional emails?
  design system/UI? (Each "no" means deleting its convention.)
- **Batch E · Permissions and guardrails:** keep the conservative `ask:[Bash]` in
  `.claude/settings.json`, or create `.claude/settings.local.json` with a read-only
  allowlist? Enable the **git guardrails** (opt-in hook that blocks commits/push to
  `main`/`develop` and force-push)? And the **secret guardrails** (opt-in hook that
  blocks agent writes to real `.env` files and private keys)?

## Step 3 — Fill / merge by context

Replace the catalog placeholders (`TEMPLATE-USAGE.md §3`) with the answers:
`[PROJECT_NAME]`, `[AUTHOR]`, `[GITHUB_USER]`, `[COMPANY_NAME]`, `[REPOSITORY_URL]`,
`[YEAR]`, `[SUPPORT_EMAIL]`, `[SECURITY_EMAIL]`, `[RUNTIME]`, `[PACKAGE_MANAGER]`,
`[DATABASE]`, `[PORT]`, `[*_COMMAND]`, `[*_URL]`, `[DATE]`.

Files that get updated: `README.md`, `AGENTS.md` (overview + commands),
`docs/architecture/*`, `docs/product/*`, `.env.example`, `LICENSE` (year + author),
`SECURITY.md` (emails), `CHANGELOG.md` (first entry).

- **NEW:** write directly from the answers. Work in the repo as is.
- **EXISTING:** read the code and infer so you don't leave `[…]`. Do **NOT** overwrite
  `README.md`, `LICENSE`, or `.gitignore` — propose the merge by hand. Work on a
  `chore/adopt-doc-template` branch. Suggest running `/init` to merge existing context.

Also write `.template-origin` at the root so `/update-template` can bring in future
template improvements:

```
repo=<URL of this template>
commit=<SHA of the template HEAD used as base>
date=<today's YYYY-MM-DD>
```

## Step 4 — Apply the permissions decision (Batch E)

If "automatic" was chosen, create `.claude/settings.local.json` with a read-only allowlist
(`ls, cat, head, tail, wc, grep, rg, find, tree, sort, uniq, echo, pwd, which`, and
`git status/log/diff/branch/show/remote`). Verify that `.claude/settings.local.json` is in
`.gitignore`. If "conservative" was chosen, don't touch permissions.

If the **git guardrails** and/or the **secret guardrails** were accepted, add the
`hooks.PreToolUse` blocks pointing to `.claude/hooks/git-guardrails.sh` (matcher `Bash`)
and `.claude/hooks/secret-guardrails.sh` (matcher `Write|Edit`) — the full JSON is in
`docs/conventions/ai-agents.md`. They require `python3`.

## Step 5 — Delete by type (TEMPLATE-USAGE.md §7 rule)

Delete the docs/conventions that don't apply:

- Mobile / Desktop → delete `docs/conventions/seo.md`; refocus `views-and-layouts`,
  `api`, `deploy`.
- API / Library → delete UI docs (`seo`, `views-and-layouts`, `design-system`,
  `branding`).
- Each capability answered "no" in Batch D → delete its convention (e.g. no i18n →
  `docs/conventions/i18n.md`) **and its associated skill**: no i18n → `i18n-parity`;
  no database → `migration-guard`; no SEO/public web → `seo-audit`; no UI (API or
  library) → `design-system-audit`, `accessibility-audit`, and `copywriting`.
- **Always** delete the template-repo-only files: the
  `.github/workflows/template-parity.yml` workflow, the
  `.github/scripts/check-parity.sh` script, and the `.claude/skills/port-change/`
  skill — they only serve to maintain the family of variants, not an instantiated
  project.

Ask before deleting in bulk if there is ambiguity.

## Step 6 — Wrap-up

Record the instantiation as ADR `0002` (use `docs/decisions/0000-template.md`): project
context, chosen stack, type, deleted conventions, and the permissions/guardrails policy —
so the project starts its own decision log.

Show a diff summary and the list of placeholders that still need a human decision.
Do NOT commit — let the person review. For "existing", remind them everything is on the
branch to open a PR. Suggest deleting `TEMPLATE-USAGE.md` when done.

Example: `/instantiate` → interview → repo with real documentation and pruned `docs/`.

Do NOT instantiate on the template source repo (Step 0), do NOT overwrite production code
in existing projects, do NOT commit or push on your own, and do NOT invent data: if you
can't infer a value and the person doesn't provide it, leave the placeholder and flag it.

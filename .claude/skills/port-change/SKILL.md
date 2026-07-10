---
name: port-change
description: Ports the current branch's change to this template's sibling variants (es/en × with-AI/no-AI) — translates the content, adapts or removes the AI layer depending on the target, and leaves each variant with a PR-ready branch. Use this when a template change must be replicated in the other variants (e.g. "port this change to the Spanish template", "replicate this in the variants").
---

<!-- TEMPLATE-REPO-ONLY skill: it exists to maintain the family of variants.
     /instantiate removes it in instantiated projects. -->

Replicate the current branch's change in the family's sibling variants:

- 🇬🇧 with AI: `project-starter-template-en-ai` · 🇪🇸 with AI: `project-starter-template-es-ai`
- 🇬🇧 no AI: `project-starter-template-en` · 🇪🇸 no AI: `project-starter-template-es`

## Step 1 — Scope the change

Take the current branch's diff against `main` (`git diff main...HEAD`) and classify each
file: general documentation, AI layer (`.claude/`, `AGENTS.md`, `CLAUDE.md`, `specs/`),
or neutral tooling (`.github/`, scripts)?

## Step 2 — Choose targets

Ask which variants to port to and where their local copies live (or clone them). Rules
per target:

- **Same language, no AI**: strip from the port everything that depends on the AI layer
  (skills, `.claude/` hooks, mentions of agents). If a native equivalent exists
  (e.g. `.githooks/`), adapt there.
- **Other language**: translate content and names following the rename map in
  `.github/scripts/check-parity.sh` (e.g. `instantiate` ↔ `instanciar`,
  `port-change` ↔ `portar-cambio`, `update-template` ↔ `actualizar-plantilla`).
  Placeholders get translated too (`[PROJECT_NAME]` ↔ `[NOMBRE_DEL_PROYECTO]`):
  respect the target's TEMPLATE-USAGE catalog.

## Step 3 — Apply in each target

In each variant: create a branch with the same name as the origin one, apply the adapted
change, and run its checks (`.github/scripts/check-links.sh`, `check-placeholders.sh`,
tests if they exist).

**Attribution**: in the **with-AI** variants, commits carry the co-authorship trailer
from `docs/conventions/ai-agents.md`; in the **no-AI** variants, commits carry NO
attribution or mention of AI (neither in the message nor in the ported content).

## Step 4 — Wrap-up

Summarize per variant: branch created, files ported, what was adapted or omitted and
why. Remind them to open the PRs (`/open-pr` skill in the with-AI variants).

Example: branch `feat/new-hook` here → `/port-change` → `feat/new-hook` branches in
the other 3 variants, translated and with the AI layer removed where it doesn't apply.

Do NOT push or open PRs without confirmation, do NOT blindly port AI-layer files to the
no-AI variants, and do NOT leave variants half-done: if a target fails, report it
explicitly.

---
name: new-adr
description: Scaffolds a new Architecture Decision Record (ADR) by copying the ADR template into the next-numbered file and registering it in the decisions index. Use this when the user wants to record an architecture decision, create/add an ADR, or document a technical choice (e.g. "write an ADR for switching the database", "add a decision record").
argument-hint: "[short title]"
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Create a new ADR for the decision titled in `$ARGUMENTS`.

1. Read `docs/decisions/README.md` to learn the numbering scheme, file-name convention, and how the index is maintained. Follow that doc if it differs from the steps below.
2. Find the highest existing `NNNN-*.md` in `docs/decisions/` and compute the next zero-padded number (e.g. `0007`).
3. Copy `docs/decisions/0000-template.md` to `docs/decisions/<NNNN>-<kebab-title>.md`, where `<kebab-title>` is the slugified `$ARGUMENTS` (lowercase, hyphen-separated).
4. In the new file, fill in:
   - Title (the human-readable form of `$ARGUMENTS`)
   - Status: `Proposed`
   - Date: today's date (`YYYY-MM-DD`)
   - Leave Context / Decision / Consequences as guided prompts for the author to complete.
5. Add a link to the new ADR in the index inside `docs/decisions/README.md`, in number order.
6. Report the created file path and remind the author to fill in Context, Decision, and Consequences.

Example: `/new-adr use server-side rendering` → `docs/decisions/0007-use-server-side-rendering.md`.

Do NOT mark the ADR `Accepted` yourself, do NOT edit or supersede existing ADRs, and do NOT invent content for sections the author must decide.

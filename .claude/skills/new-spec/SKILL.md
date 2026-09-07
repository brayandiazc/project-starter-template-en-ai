---
name: new-spec
description: Scaffolds a new lightweight change spec by copying the spec template directory into a named spec folder. Use this when the user wants to start a spec, plan a change/feature, or create a design doc before implementing (e.g. "spec out the checkout redesign", "create a spec for the new auth flow").
argument-hint: "[change name]"
---

Create a new change spec named in `$ARGUMENTS`.

1. Read `specs/README.md` to learn the spec workflow, the folder naming convention, and what each template section expects. Follow that doc if it differs from the steps below.
2. Slugify `$ARGUMENTS` into `<change-name>` (lowercase, hyphen-separated).
3. Compute `NNNN`: the highest existing 4-digit numeric prefix across `specs/` **and**
   `specs/archive/` (if it exists), plus one; if there are none, `0001`.
4. Copy the entire `specs/_template/` directory to `specs/NNNN-<change-name>/` (preserve every file in the template).
5. In the copied files, fill in obvious metadata:
   - The change title (human-readable form of `$ARGUMENTS`)
   - Status: `Draft`
   - Date: today's date (`YYYY-MM-DD`)
   - Leave problem, goals, non-goals, and approach as prompts for the author.
6. **Fill in "Evidence"** before the goal: who would pay and what backs that up, whether
   it already exists, and what experiment was run. Look at
   [`docs/product/roadmap.md`](../../../docs/product/roadmap.md) first — the answer may
   already be there. On a `fix/*` or tooling spec, write "N/A: a fix": the section exists
   to decide what to build, not to stage theater around what is already broken.
7. **Tie the spec to the roadmap.** Read `docs/product/roadmap.md` and fill the
   _Roadmap item_ field of `proposal.md` with the version and the literal item this spec
   completes. If several candidates fit, ask with AskUserQuestion instead of picking on
   your own. If no item fits, say so: either it gets added to the roadmap now, or the
   change should first be weighed against the roadmap (does it belong in this version?,
   what comes out in exchange?). Note the spec next to the item in the roadmap too
   (`(specs/NNNN-<slug>/)`).
8. If `specs/README.md` maintains an index of specs, add an entry for the new spec.
9. Report the created directory path and list the files the author still needs to complete.

Example: `/new-spec checkout redesign` → `specs/0007-checkout-redesign/` (if the
latest spec was `0006`).

**Branch ↔ spec:** the branch that implements this spec must be named
`feat/<change-name>` (or `fix/<change-name>`) — same slug. The `spec-guardrails.sh` hook
blocks editing code on `feat/*`/`fix/*` branches whose spec does not exist, so create the
spec BEFORE creating the implementation branch (or from the branch, before touching
code). The hook also blocks while `proposal.md`, `design.md` or `tasks.md` still hold
unfilled template lines: leave the files complete (or delete the sections that do not
apply) before implementing.

Do NOT start implementing the change, and do NOT delete or overwrite an existing spec
folder — if any `specs/*-<change-name>/` already exists (with any `NNNN-` prefix; the
un-prefixed name will never exist), stop and ask.

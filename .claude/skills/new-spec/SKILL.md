---
name: new-spec
description: Scaffolds a new lightweight change spec by copying the spec template directory into a named spec folder. Use this when the user wants to start a spec, plan a change/feature, or create a design doc before implementing (e.g. "spec out the checkout redesign", "create a spec for the new auth flow").
argument-hint: "[change name]"
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Create a new change spec named in `$ARGUMENTS`.

1. Read `specs/README.md` to learn the spec workflow, the folder naming convention, and what each template section expects. Follow that doc if it differs from the steps below.
2. Slugify `$ARGUMENTS` into `<change-name>` (lowercase, hyphen-separated).
3. Copy the entire `specs/_template/` directory to `specs/<change-name>/` (preserve every file in the template).
4. In the copied files, fill in obvious metadata:
   - The change title (human-readable form of `$ARGUMENTS`)
   - Status: `Draft`
   - Date: today's date (`YYYY-MM-DD`)
   - Leave problem, goals, non-goals, and approach as prompts for the author.
5. If `specs/README.md` maintains an index of specs, add an entry for the new spec.
6. Report the created directory path and list the files the author still needs to complete.

Example: `/new-spec checkout redesign` → `specs/checkout-redesign/`.

Do NOT start implementing the change, and do NOT delete or overwrite an existing spec folder — if `specs/<change-name>/` already exists, stop and ask.

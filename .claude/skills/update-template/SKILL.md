---
name: update-template
description: Brings into this project the improvements its origin template received after instantiation — reads .template-origin, computes the tooling diff (skills, hooks, scripts, workflows) against the current template and offers to apply it. Use this when someone wants to update/sync the project with the template (e.g. "update the template", "pull in the template's new improvements").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Sync this project's **tooling** with the current version of its origin template. It
only touches the reusable layer — never the already-filled documentation or the code.

## Step 1 — Read the origin

Read `.template-origin` at the root (`/instantiate` writes it):

```
repo=https://github.com/brayandiazc/project-starter-template-en-ai
commit=<template-sha-at-instantiation>
date=YYYY-MM-DD
```

If it doesn't exist, ask which template/variant the project came from and roughly when,
and use the tag/commit from that time as the base.

## Step 2 — Compute the tooling diff

Clone the template to a temporary directory and compute what changed since the origin
commit, **limited to the tooling paths**:

```bash
git clone --quiet <repo> /tmp/tpl-update && cd /tmp/tpl-update
git diff --stat <origin-commit>..HEAD -- \
  .claude/ .github/scripts/ .github/workflows/ specs/_template/ \
  docs/conventions/_template.md
```

Always exclude: `README.md`, filled-in `docs/`, `CHANGELOG.md`, `LICENSE`, and any file
the project has adapted (compare before overwriting; if the local file differs from the
template's old version, it's a local adaptation — show it and ask).

## Step 3 — Propose and apply

Present a per-file summary (new / updated / deleted in the template) and let the person
choose what to apply. Work on a `chore/update-template` branch. Apply what's accepted,
run the suite `bash .github/scripts/tests/run-tests.sh` if it exists, and update
`.template-origin` with the new commit and today's date.

## Step 4 — Wrap-up

Show the final diff and remind them to open a PR. Do NOT commit or push without
confirmation.

Example: `/update-template` → "the template has 3 tooling improvements since your
instantiation (new hook, links script, quality workflow); apply all 3?"

Do NOT overwrite local adaptations without asking, do NOT touch already-filled
documentation or production code, and do NOT apply template changes the project chose to
remove (e.g. conventions deleted on purpose).

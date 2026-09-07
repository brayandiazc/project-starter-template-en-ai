---
name: update-template
description: Brings into this project the improvements the origin template received after instantiation — it reads .template-origin, computes the tooling diff (skills, hooks, scripts, workflows) against the current template and proposes applying it. Use this when the user wants to update/sync the project with the template (e.g. "update the template", "bring the new improvements from the template").
---

Sync this project's **tooling** with the current version of its origin template. It only
touches the reusable layer — never the already-filled documentation nor the code.

> The `.github/workflows/template-update-check.yml` workflow checks weekly whether the
> template published improvements and opens a notice issue — this skill is what applies
> them.

## Step 1 — Read the origin

Read `.template-origin` at the root (written by `/instantiate`):

```
repo=https://github.com/brayandiazc/project-starter-template-en-ai
commit=<template-sha-at-instantiation>
date=YYYY-MM-DD
versions=<the template's CHANGELOG versions at instantiation, comma-separated>
```

If it does not exist, ask which template/variant the project came from and roughly from
what date, and use that era's tag/commit as the base.

## Step 2 — Compute the tooling diff

Clone the template into a temporary directory and compute what changed since the origin
commit, **limited to the tooling paths**:

```bash
git clone --quiet <repo> /tmp/tpl-update && cd /tmp/tpl-update
git diff --stat <origin-commit>..HEAD -- \
  .claude/ .github/scripts/ .github/workflows/ specs/_template/ \
  docs/conventions/_template.md
```

Always exclude: `README.md`, filled-in `docs/`, `CHANGELOG.md`, `LICENSE` and any file
the project has adapted (compare before overwriting; if the local file differs from the
template's old version, it is a local adaptation — show it and ask).

### Documents: tell NEW from EXISTING apart

"Do not touch the documentation" is the right rule for the documents the project already
has filled in. **It is not for the ones that do not exist.** A project that adopted the
template a while ago may be sixteen documents behind —new conventions, the definition of
done— and today nobody brings them: this skill excludes them by design and `/instantiate`
thinks the project is untouched.

```bash
# Template documents the project does NOT have: bringing them is safe.
(cd /tmp/tpl-update && find docs design -type f -name "*.md" 2>/dev/null) \
  | while IFS= read -r f; do [ -e "$f" ] || echo "NEW: $f"; done
```

- **Does not exist** → propose bringing it, with its placeholders unfilled. It is
  documentation that is missing, not documentation that gets overwritten.
- **Exists** → do not touch it. List it as "review by hand" and the intervention ends there.

### And check the renames

**This is this skill's silent failure**, so it comes before proposing anything: a
document the template renamed or merged is not replaced, **it is duplicated**. Both stay
—yours with content and the new one empty—, both are valid markdown, the links resolve
and no check makes a sound.

Look in the template's `CHANGELOG.md`, between your version and the current one, for the
`### Changed` and `### Removed` entries that mention file paths. Compare them with what
the project has and propose the migration pair by pair: move the content and delete the
old one, **never leave both**.

### Checks that got stricter

This is the case that most easily breaks somebody else's project: a check that already
existed **starts demanding things it did not demand before**, and the first PR goes red
for dozens of reasons at once. A red like that does not get fixed: it gets ignored, and
from then on the check stops being useful.

**Before bringing a new or updated check, run it and see what it would say**, without
adopting it yet. If it flags a lot, resolve that in **a separate, earlier commit**.

Today's concrete case: `check-placeholders.sh` started seeing **prose gaps**
(`[A paragraph describing…]`), which used to be invisible. In a real project that is
about 160 at once. It has a migration mode:

```bash
bash .github/scripts/check-placeholders.sh --mark
```

It marks them in one pass **saying they are unreviewed**, so CI goes back to green
without hiding anything: they keep being listed on every run until somebody writes them.
It only touches prose — `[UPPERCASE]` placeholders are values to substitute and marking
those in bulk would indeed be hiding them.

That commit goes **before** the one that brings the check, and its message should say
they are inherited.

**Recent hardenings** — what the new tooling will flag in a project instantiated before
they arrived:

- `check-inheritance.sh`: your `.template-origin` has no `versions=` — add it with the
  versions the template had when you instantiated (they are in its CHANGELOG).
- `check-placeholders.sh`: it now checks `.github/` (except scripts/workflows) — the
  `[REPOSITORY_URL]` in `ISSUE_TEMPLATE/config.yml` will show up; fill it in.
- `spec-guardrails.sh`: it also requires `design.md` and `tasks.md` free of template
  lines before editing code on `feat/*`/`fix/*`.
- `secret-guardrails.sh`: it blocks reading/writing `.env` and keys via Bash too.

## Step 3 — Propose and apply

Present a per-file summary (new / updated / deleted in the template) and let the person
choose what to apply. Work on a `chore/update-template` branch. Apply what is accepted,
run the suite `bash .github/scripts/tests/run-tests.sh` if it exists, and update
`.template-origin` with the new commit and today's date.

## Step 4 — Close

Show the final diff and remember to open a PR. Do NOT commit or push without confirmation.

Example: `/update-template` → "the template has 3 tooling improvements since your
instantiation (a new hook, the links script, the quality workflow); apply all 3?"

Do NOT overwrite local adaptations without asking, do NOT touch already-filled
documentation or production code, and do NOT apply template changes the project
deliberately removed (e.g. conventions deleted on purpose).

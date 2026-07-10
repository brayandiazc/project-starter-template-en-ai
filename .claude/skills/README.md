# Skills

The skills in this folder are **examples** that ship with the template: they stay
stack-agnostic because they defer to your [`docs/`](../../docs/README.md).
Adapt or delete them per project.

## Structure rules (CI validates them)

`quality.yml` runs [`check-skills.sh`](../../.github/scripts/check-skills.sh) on
every push/PR:

- Each skill lives in `<kebab-name>/SKILL.md`.
- The frontmatter `name` equals the folder name, in kebab-case.
- The `description` is non-empty and says **when to invoke it** — the agent routes
  on that field, so write it as a trigger ("Use this when the user asks…"), with
  example phrases, not as a marketing summary.
- The same applies to the subagents in [`../agents/`](../agents) (`name` = file
  name, non-empty `description`).

## How to write a new skill

Create `new-skill/SKILL.md` from this template and keep the body short (under
~150 lines: the body is loaded into the agent's context every time the skill
activates). Don't duplicate another skill (link to it) and don't inline project
rules (those live in `docs/conventions/`).

```markdown
---
name: new-skill
description: What it does in one sentence. Use this when the user asks for X or Y (e.g. "phrase the user would say", "another phrase"). What it does NOT do, if it could be confused.
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

One line on the problem this skill prevents and which `docs/` document it defers to.

## Steps

1. Read the relevant convention in `docs/conventions/…` — it is the source of truth.
2. [concrete, verifiable steps]
3. [how to check the result before finishing]

Example: `/new-skill argument` → expected result in one line.

Do NOT [forbidden action 1], do NOT [forbidden action 2] without explicit confirmation.
```

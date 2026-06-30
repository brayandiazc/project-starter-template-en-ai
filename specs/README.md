# Specs — lightweight spec-driven changes

This folder holds **change specs**: a short, structured way to capture _what_ a
change does and _why_ **before** writing code. It gives both humans and AI agents
a clear target and a review gate, without a heavy process.

> Optional but recommended for non-trivial changes. Tiny fixes don't need a spec.

## When to write a spec

Write one when a change is non-trivial, touches several parts of the system, or
is worth aligning on before implementation. Skip it for typos and one-liners.

## How it works

1. Copy [`_template/`](_template) to `specs/<change-name>/`
   (kebab-case, e.g. `specs/user-invites/`). Or run the `/new-spec` skill.
2. Fill in the three files:
   - `proposal.md` — the what and the why (problem, goal, scope).
   - `tasks.md` — the implementation checklist.
   - `design.md` — technical decisions (link to ADRs in [`../docs/decisions/`](../docs/decisions/README.md)).
3. Get it reviewed, then implement following `tasks.md`.
4. When done, the spec stays as a record (optionally move completed specs to an
   `archive/` subfolder).

## Relationship to ADRs

- A **spec** describes a unit of work (a change).
- An **ADR** ([`../docs/decisions/`](../docs/decisions/README.md)) records a
  durable decision. A spec's `design.md` may produce one or more ADRs.

## Heavier alternatives

This is intentionally minimal. If your team wants a formal, tool-backed
framework, consider [OpenSpec](https://github.com/Fission-AI/OpenSpec) or
[GitHub spec-kit](https://github.com/github/spec-kit). Adopt one of those _instead
of_ this folder if you need that rigor.

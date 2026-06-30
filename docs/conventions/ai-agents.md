# AI agents convention

> How we work with AI coding agents in [PROJECT_NAME].
> **Last updated**: [DATE]

## Source of truth

- [`AGENTS.md`](../../AGENTS.md) is the canonical instruction file for any agent.
- [`CLAUDE.md`](../../CLAUDE.md) is a one-line bridge that imports `AGENTS.md`
  (Claude Code reads `CLAUDE.md`; other tools read `AGENTS.md`).
- Reusable [subagents](../../.claude/agents) and [skills](../../.claude/skills)
  are versioned and shared with the team.

## What we delegate to AI

- ✅ Drafting code, tests, and docs; exploring the codebase; reviewing diffs;
  proposing designs and ADRs; routine refactors.
- ⚠️ Anything touching auth, cryptography, payments, or data migrations →
  requires extra human scrutiny.
- ❌ Final approval. **A human owns every merge.**

## Rules

- **Human review is mandatory.** AI-generated code goes through the same PR and
  review process as any other change ([`../../CONTRIBUTING.md`](../../CONTRIBUTING.md)).
- **Never feed secrets to an agent** (keys, tokens, real `.env`, customer data).
  See [`secrets.md`](secrets.md) and [`../../SECURITY.md`](../../SECURITY.md).
- **Agents defer to the docs.** Conventions in `docs/` override the model's
  defaults.
- **Verify before trusting.** Dependencies, APIs, and file paths an agent cites
  must be checked — agents can hallucinate.
- **Keep changes scoped.** One logical change per PR; no unrelated reformatting.

## Attribution

Mark AI-assisted commits with a trailer so authorship is transparent:

```
Co-Authored-By: [AI_TOOL] <[AI_TOOL_EMAIL]>
```

## Spec-driven changes (optional)

For non-trivial work, capture intent before coding using the lightweight flow in
[`../../specs/`](../../specs/README.md): a short proposal, a task checklist, and
a design note. This gives agents (and humans) a clear target and a review gate.

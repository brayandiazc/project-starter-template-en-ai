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

## MCP servers (optional)

This template ships a [`.mcp.json.example`](../../.mcp.json.example) with one
recommended, stack-agnostic server:

- **Context7** (Upstash) — fetches up-to-date, version-specific library docs so
  agents don't rely on stale API knowledge. No API key required.

To enable it, copy the file and restart Claude Code:

```bash
cp .mcp.json.example .mcp.json
```

Claude Code asks for approval before using any project MCP server.

- **Don't** add MCP servers for files, search, or web — Claude Code's built-in
  tools already cover those.
- **Never** put secrets in `.mcp.json`. Reference environment variables (e.g.
  `${GITHUB_TOKEN}`) and document them in `.env.example` (see [`secrets.md`](secrets.md)).
- Add project-specific servers (GitHub, Playwright, a database MCP, etc.) as your
  stack needs them.

## Git guardrails (optional)

The rules in [`AGENTS.md`](../../AGENTS.md) tell the agent what it **should** do, but don't
force it. For a hard guarantee, this template ships an opt-in hook,
[`.claude/hooks/git-guardrails.sh`](../../.claude/hooks/git-guardrails.sh), that
**deterministically blocks** actions that break the branching in
[`../../CONTRIBUTING.md`](../../CONTRIBUTING.md): direct commits or pushes to `main`/`develop`
and force-push to shared branches. The agent can't skip it.

It is off by default. To enable it, add the hook to `.claude/settings.local.json`
(personal) or `.claude/settings.json` (shared):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/git-guardrails.sh" }
        ]
      }
    ]
  }
}
```

Requires `python3` (to read the event's command). The script fails *open*: when in doubt it
allows, so the workflow isn't stuck. The `/instantiate` skill offers to enable it in its
permissions step.

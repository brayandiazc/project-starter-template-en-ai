# AI agents convention

> How work is done with coding agents here, given that **review is of results, not of
> code**.
> **Last updated**: [DATE]

## The two principles

Everything else in this document follows from here.

**Verify > recall.** An agent performs well when it can verify (read existing code,
consult a schema, check a type) and fails when it has to recall (reconstructing an API, a
version, a flag from memory). The failure mode is **plausible but wrong**: it compiles,
it sounds reasonable, it does not work or works badly. It does not fail loudly.

**Fewer unreviewed decisions = less risk.** If nobody reviews the code, every decision
the agent takes freely is accumulated risk. A tool with a strong convention **takes
freedom away from it**, and that loss of freedom is what protects the project.

> **Corollary, when choosing a stack**: whatever has a strong convention, a stable API and
> lots of public code performs better with an agent. It is a bias toward the mature and
> boring — right for shipping product, wrong for being on the cutting edge. **The choice
> is yours**; this only says what makes it cheaper.

## Source of truth

- [`AGENTS.md`](../../AGENTS.md) is the canonical instructions file for any agent.
  [`CLAUDE.md`](../../CLAUDE.md) is a one-line bridge that imports it (Claude Code reads
  `CLAUDE.md`; other tools read `AGENTS.md`).
- The [subagents](../../.claude/agents) and the [skills](../../.claude/skills) are
  versioned in the repo.
- **Every subagent declares its model**, even if only to inherit the session's
  (`model: inherit`). `check-skills.sh` requires it: without the field, a heavy subagent
  ends up running on an expensive model nobody decided on. The template leaves them all on
  `inherit` on purpose — the allocation depends on your plan, not on this template.

  **The criterion for going up or down a model is not "which one is smarter"** (the
  smartest always is), but **what happens when that subagent fails**:

  | If its failure…                                 | Then         |
  | ----------------------------------------------- | ------------ |
  | Shows up on screen, or a check catches it       | You can save |
  | Passes every check green and reaches production | Do not save  |
  | Conditions everything built afterwards          | Do not save  |

  In one line: **if the error is caught on its own, save; if it is caught late or not at
  all, do not.** That is why `designer` can sit on a middle tier even though it writes a
  lot of code —its error is visible— and `doc-keeper` cannot, even though it only writes
  Markdown: out-of-sync documentation passes every check.

  And a case that criterion does not cover, because it invites overspending: when a
  subagent's failure is **being permissive** —saying yes to something it should have cut—
  a more capable model does not help. The extra capability helps where the problem is
  **hard**, not where the problem is **holding your ground**. That is fixed with a clearer
  prompt, not with more budget.

- **Documentation prevails over the model's defaults.** On a conflict between what `docs/`
  says and what the agent "knows", `docs/` wins.

## How things get verified, if code is not reviewed

Three layers. **None is optional** — together they replace line-by-line review.

### The automated layer

- **Tests** — here they are not a best practice, they are **infrastructure**: they are
  the part of the review that runs itself. See [`testing.md`](testing.md).
- **The error monitor** — what tells you something broke in production.
- **Uptime + the jobs panel** — background failures are the ones that hide the most.

### The inspection layer

- **An admin panel** — it lets you see the application's real state without reading code.
  In this scheme it is worth far more than it looks; it is not an extra.

### The human layer — the minimum that IS reviewed by hand

**The database schema.** It is little (a migration, a schema file), it is the most
expensive thing to change later, and it is the only thing **neither tests nor monitoring
catch**: a badly thought-out data model passes every test and produces not one single
error in the monitor. That is why **it is designed on paper before the code**: what is the
product's central entity? If there is a structured document describing the state
(manifest, schema), that too.

> **One person is responsible for every merge.** That does not mean reading every line; it
> means nobody else carries the outcome.

## Where the agent fails — risk checklist

### It fails silently (high risk)

It comes out fine on the surface and wrong underneath. This is what really needs looking at.

| Area                     | What to review                                                                                                                                                                     |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Custom UI components** | Where the stack has no headless layer that solves it: focus trap, the Escape key, ARIA, keyboard navigation. There are few in the whole app and they are reused — worth reviewing. |
| **Authorization**        | Policies that look right with holes in them. Test with other roles, not only your own.                                                                                             |
| **Concurrency**          | Isolation, deadlocks, locks. Happy path right, edge wrong.                                                                                                                         |
| **Idempotency**          | Especially with queues and on mobile: the network fails and requests get retried.                                                                                                  |
| **Temporal sync**        | If there is media: off-by-one-frame errors, timestamp drift. They pass the tests and look wrong in the result.                                                                     |

### It goes stale (medium risk)

**Verify against the official documentation, not against the agent**: any piece of your
stack that has released a major version in the last two years, the deployment tools, and
AI provider SDKs (the ones that break their API fastest).

It is not that the agent handles them badly — it is that its knowledge is more likely to
be old **without it noticing**. That is what the Context7 MCP is for (below).

> Write yours down here when you choose the stack. A generic list protects you from
> nothing: what protects you is the concrete name of the library that already generated
> stale syntax for you.

#### Syntax drift — watch rules

The most treacherous case of the previous risk: pieces where the training corpus is
dominated by an **older version of the same library**, so the agent generates obsolete
syntax with total confidence and everything seems to work. A rule written here prevents
most of it; the rest is caught by review with this table as the checklist.

**The table that follows are real EXAMPLES**, from concrete stacks, so you can see the
shape of a useful watch rule. **Delete them and write your stack's** — a row about a
library you do not use is noise, and the one you are missing is the failure.

| Piece                                 | Typical agent drift                                                                   | Rule                                                                                                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tailwind v4**                       | Generates v3 syntax: `tailwind.config.js`, `@tailwind base/components/utilities`      | Tokens via `@theme` in CSS (see [`design/`](../../design/README.md)). **There must be no JS config**: if the agent proposes creating `tailwind.config.js`, that is drift in action |
| **SQLAlchemy 2.x**                    | Mixes in the legacy 1.x style: `session.query(...)`, untyped models                   | Declarative 2.x style only: `select()`, `Mapped[]` + `mapped_column()`                                                                                                             |
| **Pydantic v2**                       | Uses the v1 API: `class Config`, `.dict()`, `@validator`                              | `model_config = ConfigDict(...)`, `.model_dump()`, `@field_validator`                                                                                                              |
| **Young JS libraries**                | Small public corpus and young APIs: it invents plausible methods that do not exist    | Verify the signature against Context7 before using any non-trivial API; **exact** versions in `package.json` (no `^`)                                                              |
| **Rails 8** (Solid Queue/Cache, auth) | Proposes the usual pieces out of habit: Redis, Sidekiq, Devise                        | The framework's current-version defaults win. Bringing in the classic alternative is not a shortcut: it is a deviation and requires its ADR                                        |
| **better-auth**                       | A post-2023 library: little corpus, the agent falls back to NextAuth/Auth.js patterns | Verify every signature with Context7. It holds for any young library: auth gets reviewed by hand anyway (checklist above)                                                          |
| **AI SDKs**                           | They break their API across major versions; it generates the old one                  | Exact version in the manifest; verify signatures with Context7 when bumping a major                                                                                                |

When instantiating, delete the rows for the stacks the product does not use and add your
own — same as in [`../architecture/stack.md`](../architecture/stack.md).

### Structural weakness

- **Visual design with no direction** → converges on a generic SaaS template. That is why
  the tokens are defined outside the agent, in [`design/`](../../design/README.md).
- **Query optimization** → it writes correct SQL, not necessarily fast SQL. Without
  `EXPLAIN ANALYZE` it is guesswork.
- **Hand-written CSS at volume** → it has global state and the agent only sees the
  fragment it touches. Cumulative degradation.

### And never

- **Never hand secrets to an agent** (keys, tokens, a real `.env`, customer data). See
  [`secrets.md`](secrets.md) and [`../../SECURITY.md`](../../SECURITY.md).
- **Never leave a change unbounded.** One logical change per PR, with no reformatting
  unrelated to the task.

## The medium-term risk

With the agent writing most of the code and no code review, around 18 months in **nobody
holds the system's mental model**: not you (you did not write it) and not the agent (it
has no memory between sessions).

It does not hurt in month 3. It hurts when something structural has to change.

**Minimum mitigation** — the three things that actually compensate for the gap:

1. Reviewing the data schema (above).
2. Keeping `AGENTS.md` up to date with the project's live decisions and conventions.
3. Documenting the **why** of structural decisions, not the what. The what is in the code;
   the why gets lost. That is what [ADRs](../decisions/README.md) are for.

## Attribution

AI-assisted commits carry a trailer, so authorship is transparent:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Agent memory vs. documentation

Some tools keep a **persistent memory** per project (e.g. Claude Code's auto-memory). Use
it only for the personal and ephemeral (preferences, recurring corrections) and prune it
often. All **durable** knowledge — decisions, conventions, domain context — belongs to the
repository: `docs/`, the ADRs in [`../decisions/`](../decisions/README.md) and the
`CHANGELOG.md`.

If an agent "remembers" something the project needs to know, that memory is in the wrong
place: turn it into versioned documentation.

## Spec-driven changes (mandatory)

**No spec, no change** — the full rule lives in [`workflow.md`](workflow.md) (a single
copy; it is guaranteed by the `spec-guardrails.sh` hook, see below). For the agent, what
matters is the why: the spec gives it a closed objective and a review point **before**
there is any code to review.

## MCP servers (optional)

This repository includes a [`.mcp.json.example`](../../.mcp.json.example) with servers to
start from:

- **Context7** (Upstash) — fetches library documentation **up to date and per version**.
  It is the direct answer to the "it goes stale" risk above. It requires no API key. It is
  the only one that holds for any stack.

And two **examples** of the other class of MCP that is justified —tools with a data model
to query—, as they ship in `.mcp.json.example`. Replace them with your providers' or
delete them:

- **The error monitor**, so agents can query the product's errors and stack traces
  directly. The example's server authenticates over OAuth the first time it connects; no
  token in files.
- **The analytics tool**, to query metrics, feature flags and run queries from the
  conversation. The example's reads `ANALYTICS_PERSONAL_API_KEY` from the environment (a
  **personal** API key, not the project's — documented in `.env.example`).

To enable it, copy the file and restart Claude Code:

```bash
cp .mcp.json.example .mcp.json
```

Claude Code asks for approval before using any of the project's MCP servers.

- Do **not** add MCP servers for files, search or the web — the built-in tools already
  cover that.
- **Never** put secrets in `.mcp.json`. Reference environment variables (e.g.
  `${GITHUB_TOKEN}`) and document them in `.env.example` (see [`secrets.md`](secrets.md)).

> **Write the map of your services** —each one with its access route, its credential, its
> owner and the split between what the agent does alone, what it asks permission for and
> what the person always does—. A silent gap reads as solved.

### Infrastructure MCP (DNS, CDN, server)

There is no provider recommendation here, but there is a criterion that repeats across all
of them:

- **If the provider publishes an official plugin or MCP** (typical for DNS and CDN), use
  it: that is where it adds the most, because those are web panels that leave no trace in
  the repository.
- **If it only has a CLI**, use it over Bash. Provisioning (creating a server, firewall,
  networks) is a rare, accompanied event: the write token is only used then, and the rest
  of the time it goes **read-only**.
- **Day-to-day server administration** (deploy, logs, containers) goes **without MCP**:
  `ssh` directly over Bash. SSH MCPs only make sense on clients with no shell; here there
  is a shell.

Each of these, with its credential and its owner, is recorded in
[`../architecture/stack.md`](../architecture/stack.md) → "Active services".

## Deterministic guardrails (enabled by default)

The rules in [`AGENTS.md`](../../AGENTS.md) tell the agent what it **should** do, but they
do not force it. For a hard guarantee there are three hooks that **block
deterministically** — the agent cannot bypass them — and they ship **enabled in
`.claude/settings.json`**:

- [`.claude/hooks/git-guardrails.sh`](../../.claude/hooks/git-guardrails.sh) — blocks what
  breaks the branching in [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md): commits, local
  merges or direct pushes to `main`/`develop`, force-pushes to shared branches, and
  **creating work branches off `main`** (they must be born off `develop`; the only
  exceptions: creating `develop` itself and `hotfix/*`). It also covers
  `git -C <path>`, commands chained with `&&` and **multi-line scripts** — each command is
  judged with ITS arguments, not the next one's. The **body of a heredoc is not
  analyzed**: a commit message mentioning a `git push --force` is not doing one.
- [`.claude/hooks/secret-guardrails.sh`](../../.claude/hooks/secret-guardrails.sh) —
  blocks writes to secret files: the real `.env` (and variants such as `.env.local`) and
  private keys (`*.pem`, `id_rsa`…). `.env.example` can be edited: it is the contract,
  with no real values.
- [`.claude/hooks/spec-guardrails.sh`](../../.claude/hooks/spec-guardrails.sh) — enforces
  "no spec, no change": on `feat/*`/`fix/*` branches it blocks editing code while
  `specs/NNNN-<branch-slug>/` does not exist **or its `proposal.md` is still the
  template**. Documentation (`docs/`), the specs themselves, tooling (`.claude/`,
  `.github/`) and the root Markdown are exempt.

To disable one (not recommended), remove its block from `hooks.PreToolUse` in
`.claude/settings.json`. They require `python3`. All three fail _open_: when in doubt they
allow, so as not to jam the flow. Their cases are tested in
`.github/scripts/tests/run-tests.sh` (it runs in CI).

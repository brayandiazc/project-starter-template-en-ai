# Workflow (SDD + agents)

> How work is done in this template's projects: spec-driven development (SDD) with AI
> agents accompanying every phase. The goal is that one person alone moves fast **without
> losing robustness**: there is always somebody planning and somebody reviewing.
>
> **What this document does NOT fix**: what to build nor with what. The product's scope
> is yours and is documented in [`../product/`](../product/roadmap.md); the stack is
> yours and is recorded in [`../architecture/stack.md`](../architecture/stack.md). Here
> is only the work cycle, which is the same whatever the answer to those two is.
>
> **Last updated**: [DATE]

## The cycle

```
1. SPECIFY    → architect (+ /new-spec)          → specs/<change>/
2. IMPLEMENT  → development with AI, spec in hand → code + tests (test-author)
3. REVIEW     → /code-review + security-reviewer  → before every PR
4. DOCUMENT   → doc-keeper (+ /changelog…)        → docs/, CHANGELOG and roadmap
5. PUBLISH    → /release                          → version cut, tag and release
      └────────────── back to 1 with what you learned ──────────────┘
```

Steps 1–4 repeat on every non-trivial change; step 5 marks the version cuts.

## Before building the interface

If the product has views, three steps pay for themselves **before** writing any logic.
This is not a product method: it is the order in which UI mistakes come out cheapest.

| Step         | What is done                                            | Artifact left behind                                       |
| ------------ | ------------------------------------------------------- | ---------------------------------------------------------- |
| 1. Map       | View inventory (standard catalog below + your own)      | [`../architecture/screens.md`](../architecture/screens.md) |
| 2. Dress     | The product's visual identity — `/identity` skill       | Palette and typography in `design/tokens.css`              |
| 3. Prototype | Navigable static views — `designer` agent, `/prototype` | A clickable prototype in the repo                          |

**Static before functional**: the views are built first with no logic —they validate the
flow and the design dirt cheap— and the backend is connected afterwards. The prototype is
not thrown away, it gets converted.

**With no interface, the same rule is called _the output before the engine_**: you mock
up by hand the artifact the tool should produce —the report, the JSON, the file— and see
whether it is useful, **before** building what generates it. It is just as cheap to throw
away and answers the same question: if the result does not convince, the engine is moot.

### Standard view catalog

Every web product starts from this inventory and adds the views of its critical journey —
that way none gets discovered mid-development:

- **Public**: landing/home, pricing (if there is payment), about, contact, 404, 500.
- **Legal**: terms, privacy, cookies. The template does not ship these texts — they are
  written per product.
- **Auth** (if there are accounts): login, sign-up, password recovery, verification.
- **App**: dashboard/home, the view(s) of the value action, settings/account, billing
  (if there is payment).

The `/prototype` skill builds them statically with the design system in `design/` (light
and dark mode and localization from the start). The same rule applies to every later spec
touching UI: its `design.md` links a reference HTML prototype (on mobile the mockup serves
as a spec of **content and hierarchy**, not of layout or navigation: tabs instead of a
sidebar, 48 dp touch targets, safe areas, and screens of its own such as onboarding,
permissions and offline).

## Kickoff branches

The kickoff produces two branches in sequence, both born off `develop` (which is created
from `main` if it does not exist — `main` is left for production only):

```
main ──► develop ──► docs/kickoff ──(PR → develop)──► feat/<first-spec>
                     branch 1: the kickoff's        branch 2: stack scaffolding
                     filled-in documentation        + prototype, guided by the spec
```

The documentation is merged into `develop` first; **afterwards** the branch that generates
the software project is born (dependencies, skeleton, views). The `git-guardrails.sh` hook
prevents creating work branches off `main`.

Two repository rules accompany the flow:

- **`develop` is the default branch on GitHub** (new PRs and Dependabot's point there) —
  `/configure-repo` sets it.
- **Every `develop` → `main` merge publishes a release**: the version is cut in the
  CHANGELOG with `/release` (which also syncs the stack manifest's version, if there is
  one) and the `release.yml` workflow creates the tag and the GitHub release
  automatically. The first merge (the kickoff documentation) publishes the project's
  `v0.1.0` — no step to production is left without a version, and the `release` job in
  `quality.yml` verifies it: it blocks the PR to `main` if the topmost CHANGELOG version
  is already published or if entries are left loose under `## [Unreleased]`.
  `hotfix/*` branches cut their own `patch` before the PR to `main` (see
  [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md)).

## Critical rules (the "what rules what")

1. **Ask before assuming.** In any phase, on real ambiguity (scope, priority, a business
   trade-off) you ask the person — reversible implementation decisions, no; product
   decisions, yes.
2. **No spec, no change — mandatory.** Every feature or fix (`feat/*`, `fix/*`) is born
   in [`../../specs/`](../../specs/README.md) (proposal → design → tasks), with the branch
   and the spec sharing a slug. The spec is the contract between the idea and the code,
   and what allows delegating to agents without drift. It is not optional: the
   `spec-guardrails.sh` hook blocks editing code on those branches while its spec does not
   exist **and** while `proposal.md` still holds unfilled template lines — an empty folder
   is not a spec.
3. **No review, no merge.** `/code-review` over the diff and, if it touches user input,
   auth, data or external calls, the `security-reviewer` subagent, which knows the four
   areas that fail silently (`SECURITY.md`). Blocking findings are resolved before the PR.
4. **Nothing undocumented.** Every change → CHANGELOG + affected docs **in the same PR**
   as the code (`doc-keeper`); decisions that are hard to reverse → an ADR; specs that
   touch data, payments or third parties → also review whether the product's legal texts
   change. A change with no documentation **is not done** (it is a strict rule in
   `AGENTS.md`), and the `changelog` job in `quality.yml` verifies it on every PR: with no
   entry under `## [Unreleased]`, CI fails. The exception is requested explicitly with the
   `no-changelog` label.
5. **The roadmap moves with the specs, not with good intentions.** The spec declares which
   item of [`../product/roadmap.md`](../product/roadmap.md) it completes (the _Roadmap
   item_ field in `proposal.md`) and the PR implementing it ticks it off. Roadmap,
   CHANGELOG and code travel in the same commit set: the product's state is what is
   merged, not what was promised.
6. **AI administers the repository.** Description, topics, labels, branches, issues, PRs
   and releases are managed with the skills (`/configure-repo`, `/open-issue`, `/open-pr`,
   `/release`) — the person decides, the AI operates and leaves a trace.

## Who is who

| Phase        | Agent / skill                                            | What it guarantees                                      |
| ------------ | -------------------------------------------------------- | ------------------------------------------------------- |
| Map          | `screens.md` (by hand)                                   | A view inventory before building any of them            |
| Dress        | `/identity`                                              | The product's palette and typography, decided by seeing |
| Prototype    | `designer`, `/prototype`                                 | Views faithful to the design system, clickable          |
| Specify      | `architect`, `/new-spec`                                 | A grounded plan before touching code                    |
| Implement    | main session + `debugger`                                | Code aligned with the spec and the conventions          |
| Test         | `test-author`                                            | Happy path + edges covered                              |
| Review       | `/code-review`, `security-reviewer`                      | Correctness, security, no secrets                       |
| Document     | `doc-keeper`, `/changelog`, `/new-adr`                   | Docs, CHANGELOG and roadmap up to date                  |
| Operate repo | `/configure-repo`, `/open-issue`, `/open-pr`, `/release` | GitHub managed by AI with a trace                       |

## Working with AI: patterns we use

- **The spec as the anchor (SDD)**: agents work against the spec, not against the
  conversation's memory — that is what allows parallelizing and resuming with no lost
  context.
- **Loops with verification**: implement → run tests/lint → fix → repeat; the agent does
  not declare "done" without green evidence (see
  [`definition-of-done.md`](definition-of-done.md)).
- **Parallelize by independence**: independent jobs (explore + test, several modules of a
  migration) are launched as parallel subagents; dependent jobs, in sequence. Never two
  agents editing the same thing.
- **Adversarial review**: whoever reviews is not whoever wrote — the reviewer comes in
  with clean context and orders to find problems, not to validate.
- **Deterministic guardrails**: what must never happen (pushing to main, branches born off
  main, committing secrets, code with no spec) is blocked by hooks (`.claude/hooks/`,
  enabled by default), not by the model's promises. What the hook cannot see until the
  work is finished (is there a CHANGELOG entry?) is verified by CI on the PR — two layers,
  neither based on the agent's memory.

## Anti-patterns

- Implementing straight from a conversed idea with no spec ("I have it fresh").
- Skipping the review because "it is a small change" (small ones are the ones that break).
- Letting the backlog grow without weighing it against the roadmap.
- Asking the same agent to implement and approve itself.

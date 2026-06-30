---
name: refactor
description: Improves code structure and readability WITHOUT changing observable behavior, in small safe steps guided by the project conventions, keeping tests green. Use this when the user asks to refactor, clean up, restructure, or reduce duplication in code without adding features or fixing bugs (e.g. "refactor this module", "clean up this function", "extract this logic").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Refactor the named code while preserving behavior.

1. Read the relevant guidance in `docs/conventions/` (style, architecture, naming) and follow it — the conventions define what "better structure" means here.
2. Establish a safety net first: identify the tests covering the target code and run them to confirm they pass before you touch anything. If coverage is missing, note the risk and consider adding a characterization test.
3. Refactor in small, behavior-preserving steps, for example:
   - Rename for clarity; extract a function/component/module; inline needless indirection.
   - Remove duplication; simplify conditionals; tighten types.
   - Reduce coupling per the architecture conventions.
4. After EACH meaningful step, re-run the tests (and linter/formatter if configured) and keep them green. Revert a step that breaks them rather than patching behavior.
5. Summarize what changed structurally and confirm that public APIs and observable behavior are unchanged.

Do NOT change behavior, public APIs, or output — if a behavior change seems needed, stop and raise it separately. Do NOT mix in new features or bug fixes. Do NOT do one giant rewrite; prefer reviewable increments.

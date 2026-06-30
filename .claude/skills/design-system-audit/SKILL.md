---
name: design-system-audit
description: Audits UI code against the project's design system — semantic tokens, allowed components, required interaction states, and the accessibility baseline. Use this when the user asks to audit/check design-system compliance, verify tokens are used instead of raw values, or confirm a component follows the design guidelines (e.g. "does this component follow our design system?", "audit the new card").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Audit the named UI (component/page) against the design system.

1. Read `docs/conventions/design-system.md` for the token system, the list of approved/blessed components, required states, and the accessibility baseline.
2. Locate the UI source files in scope.
3. Check against the conventions:
   - Tokens — colors, spacing, typography, radii use semantic design tokens, NOT raw hex/px/magic values.
   - Components — built from the approved component set rather than one-off reimplementations.
   - States — required interactive states are handled (default, hover, focus, active, disabled, loading, empty, error) as the doc specifies.
   - Accessibility baseline — meets the minimum the doc requires (contrast, focus visibility, semantic markup).
4. Report a checklist: each item Pass / Fail, with file:line and a concrete fix referencing the correct token or component.

Example finding: `Raw color #2563eb in Button.tsx:14 — use the \`color-primary\` token per design-system.md.`

Do NOT redesign or restyle on your own initiative — report findings and suggest fixes. For deeper a11y checks, defer to the accessibility-audit skill. Always defer to `docs/conventions/design-system.md`.

---
name: design-system-audit
description: Audits a view or component against the design system on what a script cannot check — interaction states, the four data states, native primitives versus reinvented components, and visual hierarchy. Use this when the user asks to review design-system compliance or whether a component follows the guidelines (e.g. "does this card follow our system?", "audit the settings view").
---

Audit the named UI against the design system in `design/`.

**You do not review the colors.** The CI `Design system` job
(`.github/scripts/check-design-tokens.sh`) already fails on any hex, `rgb()`, palette
utility (`bg-blue-500`) or arbitrary value (`bg-[#0A7A9D]`) in the views. If you think
you see a raw color, it means the check does not cover that path: say so, and propose
adding the folder to the script instead of becoming a human linter.

Your job is what no script can check:

1. Read `design/README.md` (the system) and `docs/conventions/ui.md` (how the views are
   organized and where the brand assets are).

2. **Native primitive before a reinvented component.** A dialog built with a `<div>` and
   `position: fixed` is a finding even if it looks fine: `<dialog>`, `<details>` and
   `popover` bring focus, keyboard and Escape solved by the browser. If there is a custom
   component where a primitive belonged, flag it with the concrete replacement.

3. **If the custom component is unavoidable**, flag it and defer its accessibility
   (focus trap, Escape, `aria-*`, tabbing) to `/accessibility-audit` — that list lives
   there, in one place, on purpose.

4. **Interaction states**: default, hover, active and disabled. (Visible focus and
   keyboard navigation are audited by `/accessibility-audit`.)

5. **The four data states**, in every view that loads something: **loading** (a skeleton
   shaped like the content, not a generic spinner or "Loading…"), **empty** (icon + why
   it is empty + a CTA that orients), **error** (message + retry action) and **success**.
   The empty state is the one that most defines the product and the one most often skipped.

6. **Both themes**: light and `data-theme="dark"` — the view must use the tokens in both
   and no piece may be stuck to a single theme. (Measuring AA contrast belongs to
   `/accessibility-audit`; `design/preview.html` brings it for the base tokens.)

7. **Hierarchy before decoration**: can you tell what matters in the view without
   reading the text? Spacing and type weight before borders and shadows.

Report a list: each item **Pass / Fail**, with `file:line` and the concrete fix.
Example: `Modal.tsx:12 — <div role="dialog"> with no focus trap; use <dialog>`.

Do NOT redesign or restyle on your own initiative: you report and propose. For a full
accessibility review (measured contrast, screen readers), use `accessibility-audit`.
`design/` always wins.

---
name: accessibility-audit
description: Checks UI changes for accessibility — color contrast, keyboard navigation, focus management, ARIA usage, and alt text. Use this when the user asks for an a11y/accessibility review, to check WCAG compliance, keyboard support, screen-reader friendliness, or focus handling (e.g. "is this modal accessible?", "audit a11y on the form").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Audit the named UI for accessibility. This complements the design-system-audit skill (which covers the design-system baseline); this skill goes deeper on a11y.

1. If `docs/conventions/` contains accessibility or design-system guidance, read it for the project's target standard (e.g. WCAG 2.1 AA) and any specific rules.
2. Locate the UI source in scope and review against these checks:
   - Contrast — text and meaningful UI meet the contrast ratio for their size/role.
   - Keyboard — all interactive elements are reachable and operable by keyboard; no keyboard traps; logical tab order.
   - Focus — visible focus indicators; focus is moved/restored correctly for modals, menus, and route changes.
   - Semantics & ARIA — native elements (`button`, `a`, `label`) preferred; ARIA roles/attributes used correctly and only when needed; form inputs have associated labels.
   - Images & media — `alt` text on meaningful images, empty `alt` on decorative ones; captions where relevant.
   - Motion & responsiveness — respects reduced-motion; usable when zoomed/at small sizes.
3. Report a checklist: each item Pass / Fail / Needs-manual-check, with file:line and a concrete fix.

Example finding: `Icon-only button in Nav.tsx:22 has no accessible name — add aria-label.`

Do NOT claim full WCAG conformance from static review alone — flag items that need manual or assistive-tech testing.

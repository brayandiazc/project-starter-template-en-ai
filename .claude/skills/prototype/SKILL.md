---
name: prototype
description: Generates the product's navigable static views (landing, auth, app, legal, errors and the ones in the screen map) using the design system in design/, with no backend logic. Use it when views need to be laid out (e.g. "build the prototype", "mock up the views", "create the static landing").
---

Build clickable static views — they validate flow and design before any logic is
written, and afterwards they get connected (not thrown away).

## Step 1 — Context

Read `design/README.md` + `design/tokens.css` (system and tokens), the view map in
`docs/architecture/screens.md` and the project's `README.md`.
If there is no screen map, build it with the person first. When you finish, mark in
that map the views that move to **prototype** state.

## Step 2 — View inventory

Start from the **standard catalog** and check it against the map:

- **Public**: landing/home, pricing (if there is payment), about, contact, 404 and 500.
- **Legal**: terms, privacy, cookies. The template does not ship these texts — lay out
  the page structure and leave the content marked as pending.
- **Auth** (if there are accounts): login, sign-up, password recovery.
- **App**: the views of the critical journey (dashboard, the value action,
  settings/account).

Confirm with the person which ones go into the prototype (default: all of the critical
journey + landing + legal).

## Step 3 — Build

**On the tokens, not on a library.** There are no versioned example views on purpose:
they age and end up contradicting the design system. You build with
`design/tokens.css` and native HTML primitives (`<dialog>`, `<details>`, `popover`),
which bring focus, keyboard and Escape already solved.

- Format according to the stack: the templating or component system the project
  already uses. If it is not instantiated yet, plain HTML importing `tokens.css`.
- **If the target is mobile**: the mockup serves as a content and hierarchy spec, but
  the layout, the navigation (tabs, not a sidebar) and the screen catalog are different
  — there are screens that only exist on mobile (onboarding, permissions, offline) and
  web views with no equivalent.
- Semantic design-system tokens only; loading/empty/error states visible where they
  apply (with realistic sample data, not "lorem ipsum").
- Images/illustrations from the approved sources in `design/README.md` — optimized and
  with `alt`.
- Real navigation between views (working links) — the prototype is walked end to end.
- Light and dark mode (`prefers-color-scheme` + `data-theme="dark"`) and localized text
  (no hardcoded strings if the stack already has i18n).

## Step 4 — Validate

Walk the prototype against the product's critical journey and list what grates (extra
steps, missing information). Close with: views created, design decisions taken, and
which view to connect first when implementation starts.

Do NOT add business logic, nor JS beyond navigation/trivial toggles, nor invent views
outside the map without proposing them first.

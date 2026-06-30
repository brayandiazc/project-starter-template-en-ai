---
name: copywriting
description: Reviews or produces user-facing copy (UI text, headings, buttons, error messages, marketing) in the project's voice and tone. Use this when the user asks to write/improve copy, fix wording, check tone, or draft microcopy (e.g. "write the empty-state text", "make this error message friendlier", "review the landing headline").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Review or produce user-facing copy that matches the project's voice.

1. Establish the voice and tone:
   - If a brand/voice/style doc exists (look for `docs/brand/`, `docs/voice.md`, `docs/conventions/copy.md`, `STYLEGUIDE.md`, or similar), read it and follow it.
   - Otherwise, infer the voice from existing copy in the product (UI strings, README, landing page) and keep consistent with it.
2. Confirm the context: what surface is this (button, error, onboarding, marketing), the audience, and the goal of the text.
3. Apply common copy principles, overridden by the project's doc/voice:
   - Be clear and concise; lead with the user benefit.
   - Use consistent terminology and capitalization.
   - Write actionable button/CTA labels; make error messages explain what happened and what to do next.
   - Respect i18n — copy may need to be added as translation keys (see the i18n-parity skill).
4. Deliver the copy (or edits) plus a one-line rationale tying each choice to the voice/principles. Offer 1-2 alternatives for key strings.

Example: button `Submit` → `Create account` (clearer, states the outcome).

Do NOT invent product facts, legal claims, or features that do not exist. Do NOT change established product terminology without flagging it.

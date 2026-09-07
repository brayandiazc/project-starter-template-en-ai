---
name: identity
description: Defines a product's visual identity — proposes two or three color and typography directions justified by what the product is, writes them into design/tokens.css and leaves them ready to be seen applied in preview.html before deciding. Use it after defining the product and BEFORE prototyping (e.g. "define the identity", "what palette should we use", "pick the product's colors"). It does not build views.
---

Every product is **its own brand**. The palette that ships in `design/tokens.css` is a
deliberately neutral starting point, so nothing starts with undefined colors — not a
mandate. This skill is what decides the final ones.

## When

Between the product being defined (you know who it is for and what register it lives
in) and the **prototype**. Before that is guessing; after it there are already views
built with the wrong colors.

## The division of labor

**The design judgment is not yours: it belongs to the `frontend-design` skill**, which
is already installed and better at it than any instruction we could write here — it
brings the calibration against AI's three default _looks_ (cream + serif + terracotta;
black + acid green; broadsheet with hairline rules) and the two-pass method with
self-critique.

What **is** this skill's job, and what `frontend-design` cannot know, is this
repository's contract: twenty tokens, two themes, OKLCH, verified AA contrast and
freely licensed typefaces. You are the adapter between a design direction and
`design/tokens.css`.

## Step 1 — Read the product, do not invent it

From `README.md` and `docs/product/business-model.md`: who it is for, what problem it
attacks and what register it lives in. If they are unfilled, **stop**: ask the person
first. An identity with no product behind it is decoration.

The **register** matters more than taste:

| Register                             | What it asks for                                  | Why                                                                    |
| ------------------------------------ | ------------------------------------------------- | ---------------------------------------------------------------------- |
| Dense tool (editor, timeline, panel) | Dark first, low chroma, **one** saturated accent  | Long sessions, the content is the protagonist and the chrome must hush |
| Work product (CRUD, dashboard)       | Light first, high contrast, accent on the actions | Daytime, interleaved use; it is scanned more than contemplated         |
| Consumer or marketing                | More chromatic and typographic freedom            | It is visited briefly and has to be remembered                         |

## Step 2 — Ask `frontend-design` for the direction

Invoke it with a brief built from Step 1: concrete subject, audience, the page's job
and the register. Ask it explicitly for **two or three distinct directions**, each with:

- 4–6 named colors with values,
- a display + body pairing (and a utility one if needed),
- one sentence on why **this** direction for **this** product.

If any of them resembles what you would produce for any product in the same sector,
discard it before showing it. The rule in `docs/conventions/ai-agents.md` is that design
**without direction** converges on a generic template: proposing with judgment does not
break that rule, defaulting does.

## Step 3 — Translate into the token contract

This is where this skill earns its place. `frontend-design` returns 4–6 colors; the
system needs **twenty tokens across two themes**. Rules:

- **`primary`** — the action, not the brand. It is the color of "continue", and that is
  why it must meet AA over `base-100` in both themes. If the brand color does not get
  there, lightness is adjusted and the brand color lives in the logo, not in the buttons.
- **`accent`** — the one spent once per screen. Saturated, for what really must stand out.
- **`base-100/200/300`** — three stacked surfaces, not three random greys: background,
  alternate background and borders. In the tool register more levels are often needed;
  if that is the case, say so instead of forcing three.
- **`base-content`** — the text. Never pure black on pure white.
- **`neutral`, `info`, `success`, `warning`, `error`** — they inherit the palette's
  temperature; they must not look pasted in from another system.
- Each `*-content` is the color **on top of** its pair, and it is chosen by contrast,
  not by aesthetics.
- **Values in OKLCH**, because its lightness is perceptual and makes adjusting lightness
  without shifting hue predictable.

And the dark theme **is not the light one inverted**: `primary` and `accent` are
recalculated by lightness to keep AA over the dark background. The three blocks of
`tokens.css` —light, `prefers-color-scheme`, `[data-theme="dark"]`— must stay coherent.

**If the chosen register is dark-first, the blocks must be inverted**, not just trusted
to the toggle: `tokens.css` ships with light in `:root`, and `:root` is what is seen
before anyone chooses anything. The file's header explains the change (dark palette to
`:root`, light to `[data-theme="light"]`, media query to `prefers-color-scheme: light`).
Leaving it half done gives you an editor that starts white and jumps to dark, which is
exactly the defect the register was trying to avoid.

**Typefaces: freely licensed only** (OFL, Apache, MIT) and self-hosted. A paid typeface
on the critical path is a legal dependency in every product. If the direction asks for a
paid one, propose the free equivalent and say so.

## Step 4 — See it applied before deciding

Write the first direction into `design/tokens.css` and **ask them to open
`design/preview.html`**. There are thirteen sections of real components there, both
themes and the **AA contrast recomputed live**: if a badge comes out red, that pairing
is not used for text and the lightness has to be adjusted.

Iterate with the person over the preview, not over descriptions. A palette is judged by
seeing it; a paragraph describing it cannot be judged.

If there are several directions, apply them **one at a time** and let them compare.

## Step 5 — Record the chosen one

An ADR with `/new-adr`: which direction was chosen, **for which register**, and which
were discarded and why. Without that, six months from now somebody —you included—
"improves" the palette without knowing why it was the way it was.

Regenerate `DESIGN.md` with `bash .github/scripts/design-md.sh --write` (CI verifies it
is in sync) and update the brand assets in `docs/conventions/ui.md`.
`design/README.md` carries no values — it links to `DESIGN.md` on purpose.

## Do NOT

- **Do not build views.** That is `/prototype`, and it comes after. Here only the
  identity is decided.
- **Do not invent the identity if the product is not defined.** Without knowing who it
  is for, the proposal comes from nowhere and it shows.
- **Do not leave the dark theme for later.** A color chosen only in light almost always
  fails AA in dark, and fixing it afterwards forces moving the whole palette.
- **Do not create copies of the values** (a `tokens.json`, a hand-written table):
  `tokens.css` is the single source; whatever needs another format is generated from it.
- Do not propose a direction you cannot justify with one sentence about **this**
  product. If the justification works for any other, it is not a direction.

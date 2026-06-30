---
name: seo-audit
description: Audits a page or route's SEO metadata (title, description, canonical, Open Graph, robots) against the project's SEO conventions and lists what is missing or wrong. Use this when the user asks to check/audit SEO, review meta tags, or verify a page is search-ready (e.g. "audit SEO on the pricing page", "check meta tags for this route").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Audit the SEO metadata of the page/route the user names.

1. Read `docs/conventions/seo.md` for the project's required tags, value formats (e.g. title length, description length), per-page-type rules, and which pages should be indexed vs. `noindex`.
2. Identify the page/route's source file(s) and where its metadata is defined.
3. Check each required item against the convention doc:
   - `<title>` — present, unique, within the length rule.
   - meta `description` — present, within length, descriptive.
   - canonical URL — present and correct.
   - Open Graph / social tags — `og:title`, `og:description`, `og:image`, etc. as required.
   - `robots` directives — correct for this page type (e.g. `noindex` on private/utility pages).
   - Structured data, if the convention requires it.
4. Produce a checklist report: each item marked Present / Missing / Incorrect, with the file:line and a concrete fix suggestion for each problem.

Example finding: `Missing canonical — add to app/pricing/page.tsx; convention requires one on every indexable page.`

Do NOT silently rewrite metadata unless the user asks — report findings first. Always defer to `docs/conventions/seo.md` over generic SEO advice.

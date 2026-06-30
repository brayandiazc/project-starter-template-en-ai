---
name: i18n-parity
description: Checks internationalization parity — that every translation key exists in all locales and that no user-facing strings are hardcoded — following the project's i18n conventions. Use this when the user asks to check translations, verify locale parity, find missing/hardcoded strings, or audit i18n (e.g. "check i18n", "are all locales in sync?").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Verify locale parity and catch hardcoded user-facing strings.

1. Read `docs/conventions/i18n.md` for the locale file format, where translation files live, the default/reference locale, and the rule for what must be translated.
2. List the locale files and treat the reference locale as the source of truth for the key set.
3. Compare keys across locales:
   - Keys present in the reference but missing in another locale → report as missing.
   - Keys present in a locale but not in the reference → report as orphaned.
   - Empty or untranslated-but-identical values → flag for review.
4. Scan UI source for hardcoded user-facing strings that should go through the i18n system (per the convention's rules), and list each with file:line.
5. Optionally run the bundled helper `scripts/check.sh` (relative to this skill) for a quick automated pass — but note it is a STUB the user must adapt to their actual i18n format before relying on it.
6. Report a summary: missing keys per locale, orphaned keys, and suspected hardcoded strings.

Do NOT auto-translate or invent translation text — report gaps so a human/translator fills them. Always defer to `docs/conventions/i18n.md`.

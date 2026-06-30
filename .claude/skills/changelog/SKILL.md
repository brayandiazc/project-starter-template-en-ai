---
name: changelog
description: Updates CHANGELOG.md in the Keep a Changelog format, adding the current changes under the Unreleased section. Use this when the user asks to update the changelog, add a changelog entry, or record what changed for the release notes (e.g. "add this to the changelog", "update CHANGELOG for these commits").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Add the current changes to `CHANGELOG.md`.

1. Read `CHANGELOG.md` to match its existing style and confirm it follows Keep a Changelog (https://keepachangelog.com). Ensure an `## [Unreleased]` section exists at the top; create it if missing.
2. Determine what changed since the last release: review recent commits (`git log <last-tag>..HEAD --oneline`) and/or the working diff.
3. Summarize changes into the standard categories under Unreleased, creating only the subsections that apply:
   - `Added` — new features.
   - `Changed` — changes to existing behavior.
   - `Deprecated` — soon-to-be-removed features.
   - `Removed` — removed features.
   - `Fixed` — bug fixes.
   - `Security` — vulnerability fixes.
4. Write entries as concise, user-facing bullet points (what changed and why it matters), not raw commit messages. Link issues/PRs if the file does so.
5. Report the lines you added.

Example: under `### Fixed` → `- Prevent crash when saving an empty form (#142).`

Do NOT cut a versioned release (do not move Unreleased into a dated version) unless the user explicitly asks. Do NOT bump version numbers on your own.

---
name: commit
description: Writes a Conventional Commits message for the staged changes and creates the commit, including the AI attribution co-author line. Use this when the user asks to commit, write a commit message, or save changes (e.g. "commit this", "make a commit for these changes"). Does not push.
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Create a well-formed commit for the current changes.

1. Read `CONTRIBUTING.md` for the project's commit rules (allowed types, scope conventions, subject style, any required footers). Follow that doc over the defaults below.
2. Inspect what is staged with `git status` and `git diff --staged`. If nothing is staged, review `git diff` and stage the intended files; ask before staging if it is ambiguous.
3. Compose a Conventional Commits message:
   - Format: `<type>(<optional scope>): <short imperative subject>`
   - Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`.
   - Keep the subject under ~72 chars; add a body explaining the why when the change is non-trivial.
   - Use `!` or a `BREAKING CHANGE:` footer for breaking changes.
4. For AI-assisted work, add the attribution/co-author line in the footer as defined by `CONTRIBUTING.md` (a `Co-Authored-By:` trailer).
5. Create the commit. Show the final message to the user.

Example subject: `feat(auth): add password reset via email`.

Do NOT push, do NOT amend or rewrite existing history, and do NOT commit unrelated changes — keep each commit focused.

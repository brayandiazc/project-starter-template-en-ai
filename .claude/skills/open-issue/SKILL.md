---
name: open-issue
description: Drafts and creates a GitHub issue by filling out the right template from .github/ISSUE_TEMPLATE/ based on the type (bug, feature, documentation, task, or question). Use this when the user asks to open/create an issue, report a bug, or record a task/request (e.g. "open an issue for this bug", "create an issue for the new feature", "log this task"). Does not close or comment on existing issues.
argument-hint: "[title or short description]"
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Create a well-formed issue using the repository's template.

1. Look at the available templates in `.github/ISSUE_TEMPLATE/` and pick the one that
   matches the issue type:
   - `bug_report.md` — a defect or incorrect behavior.
   - `feature_request.md` — a new feature or improvement.
   - `documentation_request.md` — something missing or wrong in the docs.
   - `task.md` — an internal work task (chore, refactor, tooling).
   - `support_question.md` — a support question or doubt.
     If the type is ambiguous from `$ARGUMENTS`, ask before choosing.
2. Read the chosen template to learn its required sections and its front matter
   (`title:`, `labels:`, `assignees:`). Respect that front matter.
3. Fill in each section using the info from `$ARGUMENTS` and the conversation context:
   - A clear, descriptive title (not generic like "bug").
   - Reproduction steps / expected vs. actual behavior for bugs.
   - Motivation and acceptance criteria for features and tasks.
   - Leave as a prompt (don't invent) any data you don't have: versions, environment,
     screenshots.
4. Create the issue with the `gh` CLI following the template, e.g.
   `gh issue create --title "…" --body "…" --label "…"` (or `--template <file>` for the
   interactive flow). If there is no remote configured, output the filled issue for the
   person to paste into GitHub.
5. Report the URL of the created issue (or the drafted body).

Example: `/open-issue login fails with Google on Safari` →
filled `.github/ISSUE_TEMPLATE/bug_report.md`, published.

Do NOT invent data you don't have (versions, logs, environment) — leave them as prompts,
do NOT create a duplicate issue if an identical one already exists (search first with
`gh issue list`), and do NOT close, edit, or comment on existing issues.

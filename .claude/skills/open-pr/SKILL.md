---
name: open-pr
description: Drafts a pull request for the current branch by filling out the repository's PR template based on the branch's changes. Use this when the user asks to open/create a PR, prepare a pull request, or write a PR description (e.g. "open a PR", "draft the pull request for this branch"). Does not merge.
---

Prepare a pull request for the current branch.

0. **Before drafting anything, get the change ready.** This is the only moment when
   someone looks at the whole set, and whatever is not updated here never gets updated:
   - Run the **`doc-keeper`** subagent over the diff: it syncs `docs/architecture/*`,
     **the diagrams** (entities, screens, auth, components), the ADR if a decision was
     made, the `CHANGELOG.md` entry, and the roadmap item the spec declared.
   - Run **`bash .githooks/pre-push`**: the CI checks, in about fifteen seconds and
     without spending Actions minutes.
   - Go through [`docs/conventions/definition-of-done.md`](../../../docs/conventions/definition-of-done.md),
     and especially the part **no machine checks**: a human review of the schema,
     authorization tested with another role, the four UI states.

   **If anything is red, do not open the PR**: say so and fix it first. A PR that is born
   red gets normalized and stops being looked at.

1. Read `.github/PULL_REQUEST_TEMPLATE.md` to learn the required sections and checklist.
2. Gather context on the branch's changes:
   - `git log <base>..HEAD --oneline` for the commit list (base is usually `main`).
   - `git diff <base>...HEAD --stat` and review notable diffs.
3. Fill in every section of the template using that context:
   - Summary of what changed and why.
   - Linked issues / related ADRs or specs if referenced.
   - Testing notes (what you ran or what the reviewer should check).
   - Tick checklist items that genuinely apply; leave the rest for the author.
4. Create the PR with the `gh` CLI (e.g. `gh pr create --title ... --body ...`) if the branch is pushed; otherwise output the filled template for the user to paste.
5. Report the PR URL or the drafted body.

Do NOT merge, do NOT approve, and do NOT check off checklist items that are not actually done. Write a draft PR if the work is incomplete.

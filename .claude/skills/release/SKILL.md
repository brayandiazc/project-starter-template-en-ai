---
name: release
description: Cuts a new version — moves the CHANGELOG's Unreleased section to a dated SemVer version, creates the commit and the tag, and optionally the GitHub release. Use this when someone asks to publish/cut a version or prepare a release (e.g. "cut version 1.2.0", "prepare the release", "publish a new version"). Does not push without confirmation.
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Cut a version following Keep a Changelog and Semantic Versioning (see `CHANGELOG.md`
and `CONTRIBUTING.md`).

## Steps

1. **Preconditions.** Verify the tree is clean (`git status`) and that you are on the
   right branch per `CONTRIBUTING.md` (with Git Flow, the release goes from `develop` to
   `main`; without `develop`, from `main`). If there are uncommitted changes, stop and say so.
2. **Read what's pending.** Take the entries from the `## [Unreleased]` section of
   `CHANGELOG.md`. If it is empty, there is nothing to publish: say so and stop.
3. **Propose the version.** Read the last published version (`v*` tag or CHANGELOG) and
   propose the SemVer bump based on the content: breaking changes → **major**; only
   `Added`/`Changed` → **minor**; only `Fixed`/`Security` → **patch**. Let the person
   confirm or correct with AskUserQuestion.
4. **Update the CHANGELOG.** Move the `Unreleased` entries into a new
   `## [X.Y.Z] - YYYY-MM-DD` section (today's date), leave `Unreleased` with its empty
   categories, and update the comparison links at the bottom of the file.
5. **Commit and tag.** Create the `chore(release): vX.Y.Z` commit (with the AI
   co-authorship from `docs/conventions/ai-agents.md`) and the annotated tag `vX.Y.Z`
   pointing at it.
6. **GitHub release (optional).** Offer to publish with
   `gh release create vX.Y.Z --title "vX.Y.Z" --notes "<CHANGELOG section>"`.

Example: "cut the version" → proposes `v1.3.0` → updated CHANGELOG + commit + tag.

Do NOT push the commit or the tag or publish the release without explicit confirmation,
do NOT invent changelog entries that aren't in `Unreleased`, and do NOT skip a SemVer
version.

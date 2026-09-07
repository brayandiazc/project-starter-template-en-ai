---
name: release
description: Cuts a new version — moves the CHANGELOG's Unreleased section into a dated SemVer version, creates the commit and the tag, and optionally the GitHub release. Use this when the user asks to publish/cut a version or prepare a release (e.g. "cut version 1.2.0", "prepare the release", "publish a new version"). It does not push without confirmation.
---

Cut a version following Keep a Changelog and Semantic Versioning (see `CHANGELOG.md`
and `CONTRIBUTING.md`).

> **Automation:** when merging `develop` → `main`, the
> `.github/workflows/release.yml` workflow detects the most recent dated version in the
> CHANGELOG and, if it has no tag, publishes the tag and the GitHub release on its own.
> This skill prepares the cut (moving Unreleased → `X.Y.Z` with a date and choosing the
> SemVer version); the manual tag/release is only needed if the workflow is not active.

## Steps

1. **Preconditions.** Verify the tree is clean (`git status`) and that you are on the
   right branch per `CONTRIBUTING.md`: with Git Flow the release goes from `develop` to
   `main`, except a hotfix, which is cut on the `hotfix/*` branch itself (see below);
   without `develop`, from `main`. If there are uncommitted changes, stop and say so.
2. **Read what is pending.** Take the entries from the `## [Unreleased]` section of
   `CHANGELOG.md`. If it is empty, there is nothing to publish: say so and stop.
3. **Propose the version.** Read the last published version (a `v*` tag or the CHANGELOG)
   and propose the SemVer bump from the content: breaking changes → **major**; only
   `Added`/`Changed` → **minor**; only `Fixed`/`Security` → **patch**. Let the person
   confirm or correct it with AskUserQuestion.
4. **Update the CHANGELOG.** Move the `Unreleased` entries into a new
   `## [X.Y.Z] - YYYY-MM-DD` section (today's date), leave `Unreleased` with its
   categories empty and update the comparison links at the bottom of the file.
5. **Sync the manifest version.** If the stack has a file that declares a version, bump
   it to `X.Y.Z` in the same commit — otherwise the project publishes `v0.4.0` with the
   manifest saying `0.1.0`. Find the one that applies and update its lockfile too if the
   manager regenerates it:
   - `package.json` (+ `package-lock.json` / `pnpm-lock.yaml`) · `*.gemspec` or
     `lib/**/version.rb` · `Cargo.toml` (+ `Cargo.lock`) · `pyproject.toml` ·
     `composer.json` · `pubspec.yaml` · `build.gradle` · `VERSION`.
   - If there is none (a project with no versioned manifest), say so and carry on: the
     CHANGELOG is the single source of the version.
6. **Commit, no tag.** Create the `chore(release): vX.Y.Z` commit (with the AI
   co-authorship line from `docs/conventions/ai-agents.md`) on a `chore/cut-vX.Y.Z`
   branch — remember `git-guardrails.sh` does not allow committing straight onto
   `develop`.
   **Do NOT create or publish the tag here.** `release.yml` only publishes if the version
   **has no tag**: if you create it, the workflow considers it published, creates no
   GitHub release, and on top of that the tag points at the branch commit instead of the
   merge on `main`.
7. **Take it to production.** A PR from the cut branch → `develop`, and then a PR
   `develop` → `main`. On merging into `main`, `release.yml` creates the `vX.Y.Z` tag
   over the merge and publishes the release with that CHANGELOG section's notes.
8. **Only if the workflow is not active** (a project with no Actions, or `release.yml`
   deleted): then yes, an annotated tag by hand and
   `gh release create vX.Y.Z --title "vX.Y.Z" --notes "<CHANGELOG section>"`.

## The cut is the last thing before merging into `main`

The `release` job in `quality.yml` (`.github/scripts/check-release.sh`) blocks PRs toward
`main` if the topmost CHANGELOG version is already published, if entries were left loose
in `## [Unreleased]`, or if that version is **inherited from the template** (a CHANGELOG
that was never reset leaves the origin repository's last version on top). It is the same
rule said backwards: **nothing reaches production without a version**. If the PR to
`main` fails for that, do not dodge it — cut the version.

## Hotfix (a release from `main`)

A `hotfix/*` does not go through `develop`, but it **also publishes a version** (always a
**patch**). The order is:

1. On the `hotfix/*` branch (born off `main`): the fix, its entry under
   `## [Unreleased]` and the cut with this skill — steps 3 to 6, with a `patch` bump.
2. PR `hotfix/*` → `main`. The `release` job validates it and, on merging, `release.yml`
   publishes the tag and the release.
3. **Sync to `develop`** with a `main` → `develop` PR (required by
   [`CONTRIBUTING.md`](../../../CONTRIBUTING.md)): if you skip it, `develop` has neither
   the fix nor the CHANGELOG's version section, and the next cut overwrites it.

Example: "cut the version" → proposes `v1.3.0` → CHANGELOG updated + a commit on
`chore/cut-v1.3.0`; the tag and the release are created by `release.yml` on reaching
`main`.

Do NOT create the tag by hand while `release.yml` is active (you steal its release), do
NOT push or publish without explicit confirmation, do NOT invent changelog entries that
are not in `Unreleased`, and do NOT skip a SemVer version.

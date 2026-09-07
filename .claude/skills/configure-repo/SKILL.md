---
name: configure-repo
description: Configures the GitHub repository end to end with gh — description, topics, labels, develop branch, branch protection, merge settings and metadata. Use it when creating a new project's repo or when an existing one needs tidying up (e.g. "configure the repo", "set up the GitHub repository", "set the labels and branch protection").
---

Leave the GitHub repository operational and consistent with the template. It requires
an authenticated `gh`; verify with `gh auth status` before starting.

## Step 1 — Context

Read `README.md` and `docs/product/business-model.md` to derive the description and
topics. Detect the current repo (`gh repo view`). If there is no remote, ask whether to
create it (`gh repo create` — public/private is the person's call).

## Step 2 — Metadata

- **Description**: one sentence from the product's vision (`gh repo edit
--description`). **Homepage**: the product URL if there is one.
- **Topics**: 3–6 derived from the stack and the domain (`gh repo edit --add-topic`).

## Step 3 — Labels

Run `.github/scripts/setup-labels.sh` (it uses `.github/LABELS.md` as the catalog).

## Step 4 — Branches and flow

- Create `develop` off `main` if it does not exist, publish it and **set it as the
  repo's default branch** (`gh api -X PATCH repos/{owner}/{repo} -f default_branch=develop`)
  — this is not optional: the default branch is where new PRs and Dependabot's point;
  if it stays `main`, Git Flow breaks (`CONTRIBUTING.md`).
- Verify that `.github/dependabot.yml` has `target-branch: "develop"` in every ecosystem.
- Protection for `main` (and `develop` if the person wants it): PR required, no
  force-push, conversations resolved and **required checks by their check-run name, not
  the workflow's**: `Quality` (from `quality.yml`) and `Gitleaks` (from
  `secret-scan.yml`). If you use the workflow name, the PR waits forever for a check
  that never reports. Verify them with
  `gh api repos/{owner}/{repo}/commits/{sha}/check-runs --jq '.check_runs[].name'`
  over a commit that has already run CI.
  Apply via `gh api repos/{owner}/{repo}/branches/{branch}/protection` and show the JSON
  before applying.
- **Check the local hooks actually run**:
  `bash .github/scripts/check-hooks-enabled.sh` (with `--fix` it enables them).
  `core.hooksPath` does not travel in the repository, so the default state of any fresh
  clone is "no local verification at all".

### If GitHub answers 403 to the protection

```
gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)
```

On a **private repository on the free plan branch protection does not exist**. This is
not a loose error to report at the end: it is an expected outcome that **changes what
the project can promise**. `CONTRIBUTING.md` and `AGENTS.md` declare PR required, no
direct pushes to `main`/`develop` and required checks to merge — and all of that is
enforced by the server. Without it, this is what is left:

| Control              | What it covers                  | How it is bypassed                               |
| -------------------- | ------------------------------- | ------------------------------------------------ |
| `git-guardrails.sh`  | Pushing from a protected branch | It is an agent hook: it does not apply to people |
| `.githooks/pre-push` | The checks before publishing    | `git push --no-verify`                           |
| `core.hooksPath`     | Enables the above               | **It gets forgotten**: manual, once per clone    |

Do three things, the moment the 403 appears:

1. **Say it plainly**, without softening it: "this repository has no branch protection;
   the local hooks are the only control and they are bypassed with `--no-verify`".
2. **Offer the real way out**: making the repository public enables protection for free.
   That is a product decision, not a technical one — ask it here, not later.
3. **Put it in writing** in the `README.md` or in the instantiation ADR, so whoever
   arrives later does not take as given a set of rules nobody enforces.

## Step 5 — Merge settings and hygiene

- Squash merge enabled, delete branches on merge, issues enabled; the PR/issue templates
  already come with the repo.
- Verify Actions is enabled and that the active workflows (`quality.yml`,
  `secret-scan.yml`) run.

## Step 6 — Close

Summarize what was configured (with the commands you ran) and record it in the CHANGELOG
under Unreleased. **And say what was NOT protected**, with its consequence — listing
what failed for permissions is not enough: if there is no branch protection, the summary
has to say that the `CONTRIBUTING.md` rules are enforced by nobody (Step 4).

Rules: show every destructive or configuration command before running it the first time;
do NOT delete existing labels/branches without confirming; do NOT touch repos other than
the current project's.

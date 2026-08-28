# sumo-mobile-ui

## Branch/PR workflow — sync with `main` twice

Unlike other SUMO sub-repos, this repo has **only a `main` branch** (no `develop`) — it's a small, standalone reusable Flutter widget package extracted from the Sumo app. Every branch here is worked in its own worktree off `main` (see the SUMO root `CLAUDE.md`'s "Sub-repo branching workflow" — same worktree pattern, `main` is just the base instead of `develop` for this one repo). Sync with `origin/main` at **two** points for every PR — this repo's `main` branch protection does **not** have `required_status_checks`/`strict` configured, so none of this is enforced by GitHub; it only works if every session does it:

1. **Before opening the PR** — `git fetch origin main` then merge (or rebase) `origin/main` into the branch, so CI runs against current `main`, not whatever it looked like when the worktree was created.
2. **Before merging the PR** — sync again, right before clicking merge. This is the step most often skipped. Another PR can land on `main` in the time between opening this PR and merging it. Use GitHub's "Update branch" button, or `git fetch origin main && git merge origin/main` (or rebase), and wait for CI to go green on the re-synced branch before merging — never merge off a sync that only happened when the PR was opened.

**Why this matters**: two branches can independently add content that collides at the same logical key/slot from the same `main` base (e.g. two branches bumping the package version in `pubspec.yaml`, or two branches each adding an exported widget under the same name/export path) without git raising any textual conflict — the lines differ — so the second one merged silently wins or breaks something for downstream consumers of this package instead of failing in review. Re-syncing right before merge is what surfaces this before it lands on `main`.

This is a manual discipline rule, not GitHub-enforced — see the SUMO root `CLAUDE.md` for the org-wide audit (no sub-repo in the org has this enforced as of 2026-08-28). After this PR merges, remember to update `knowledge-base/handoff/<date>-daily-summary.md` in the root `sumo-setup` repo per that file's rule too.

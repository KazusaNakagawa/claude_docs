---
name: start
description: Use when starting work on a GitHub Issue by number ("issue 123 をやって", "start 123") — updates the base branch, creates a feature branch, drives TDD implementation, and creates/merges the PR.
argument-hint: "<issue-number>"
allowed-tools: Bash(git:*), Bash(gh:*)
---

# Start Development from Issue

Start development workflow from a GitHub Issue number.

## Usage

```bash
/start 123   # Start working on Issue #123
```

## Workflow

1. **Fetch and update the base branch**
   Base branch is `develop` or `dev` depending on the repository — check which exists before switching.
   ```bash
   git fetch origin
   BASE=$(git branch -r | grep -qE 'origin/dev$' && echo dev || echo develop)
   git checkout "$BASE"
   git pull origin "$BASE"
   ```

2. **Get Issue details**
   ```bash
   gh issue view $ARGUMENTS
   ```

3. **Create feature branch**
   Branch naming convention: `feature/issue-{number}-{short-description}`
   ```bash
   git checkout -b feature/issue-$ARGUMENTS-<short-description>
   ```

4. **Start development (TDD cycle)**
   - Read the Issue content and understand the requirements
   - For each unit of behavior, repeat Red → Green → Refactor:
     1. **Red**: Write a failing test first, before implementation code
     2. **Green**: Write the minimum code to make the test pass
     3. **Refactor**: Clean up while keeping tests green
   - Test case coverage rule: for each behavior under test, cover at minimum
     - **成功系 (success)**: expected input → expected output
     - **失敗系 (failure)**: invalid input / error conditions → expected error handling
     - **境界値 (boundary)**: edge values (empty, min/max, zero, off-by-one, etc.)
   - Skip TDD only for cases with no meaningful test surface (pure config, docs); state this explicitly if skipped

5. **After development is complete**
   - Stage and commit changes
   - Push the branch to remote
   ```bash
   git push -u origin <branch-name>
   ```

6. **Create Pull Request (in English)**
   ```bash
   gh pr create --title "<title>" --body "<body>"
   ```

   PR format:
   - Title: Short, descriptive (under 70 characters)
   - Body: Include `## Summary`, `## Test plan`, and link to the Issue with `Closes #<issue-number>`
   - Body length: 本文全体で 100〜150 文字を目安に要点のみ。重要な要点（再発条件・破壊的変更・移行手順など）があれば例外的に超過して良い

7. **Merge & cleanup (when the user says "merge" / "ok merge")**
   Do this automatically without asking — it's a mechanical follow-through, not a design decision.
   ```bash
   gh pr checks <PR#>                     # confirm CI is green first
   gh pr merge <PR#> --merge --delete-branch
   gh pr view <PR#> --json state,mergedAt --jq '{state,mergedAt}'  # confirm MERGED
   BASE=$(git branch -r | grep -qE 'origin/dev$' && echo dev || echo develop)
   git checkout "$BASE"
   git pull origin "$BASE"
   git branch -d feature/issue-<N>-<short-description>   # local branch cleanup
   ```
   **This repo has `delete_branch_on_merge` disabled at the repo-settings level**, so `--merge` alone leaves the remote branch behind — always pass `--delete-branch` explicitly. If a merge was already done without it, clean up after the fact with `git push origin --delete <branch-name>`. If `gh pr checks` isn't green yet, report status and wait rather than merging anyway.

## Prerequisites

- GitHub CLI (`gh`) is installed and authenticated
- You are on the repository's base branch (`develop` or `dev`) or can switch to it
- Remote repository is configured

## Notes

- All PR titles and descriptions should be in English
- Reference the Issue number in the PR body with `Closes #<number>`
- Ensure all changes are tested before creating the PR
- After merge, always run Phase 7 in full — don't leave the local branch behind or `dev` stale for the next session

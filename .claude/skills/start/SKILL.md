---
name: start
description: Start development from a GitHub Issue number
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

1. **Fetch and update develop branch**
   ```bash
   git fetch origin
   git checkout develop
   git pull origin develop
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

4. **Start development**
   - Read the Issue content
   - Understand the requirements
   - Begin implementation

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

## Prerequisites

- GitHub CLI (`gh`) is installed and authenticated
- You are on `develop` branch or can switch to it
- Remote repository is configured

## Notes

- All PR titles and descriptions should be in English
- Reference the Issue number in the PR body with `Closes #<number>`
- Ensure all changes are tested before creating the PR

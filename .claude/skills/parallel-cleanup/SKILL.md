---
name: parallel-cleanup
description: Use when finishing parallel development (after /parallel-setup) or when the user asks to clean up worktrees/tmux — removes parallel-dev git worktrees, kills the tmux session, and returns to the base branch.
argument-hint: "[session-name]"
allowed-tools: Bash(git:*), Bash(tmux:*), Bash(rm:*)
---

# Parallel Development Cleanup

Remove git worktrees created by `/parallel-setup`, kill the tmux session, and return the main repo to its base branch.

## Usage

```bash
/parallel-cleanup                  # default 'parallel-dev' session
/parallel-cleanup my-session       # specific session name
```

## Workflow

### 1. Show current state

```bash
tmux list-sessions 2>/dev/null
git worktree list
```

### 2. Confirm with user (required)

Use AskUserQuestion to confirm:
- Which tmux session to kill (default: `parallel-dev`)
- Which worktrees to remove — show `git worktree list` output **including
  uncommitted-change status** (`git -C <path> status --short`)
- That `--force` removal will discard any uncommitted changes

**Never force-remove a dirty worktree the user hasn't explicitly approved.**
If work isn't pushed yet, offer to commit+push first:

```bash
cd ~/worktree-worker1 && git add . && git commit -m "WIP: Save progress" && git push
```

### 3. Kill tmux session

```bash
session_name="${ARGUMENTS:-parallel-dev}"
if tmux has-session -t "$session_name" 2>/dev/null; then
  tmux kill-session -t "$session_name"
fi
```

### 4. Remove approved worktrees

Only remove paths matching `worktree-worker*` / `worktree-*`; skip anything else.

```bash
git worktree remove <path> --force   # per approved worktree
git worktree prune                   # stale metadata
```

### 5. Return to base branch

```bash
BASE=$(git branch -r | grep -qE 'origin/dev$' && echo dev || echo develop)
git checkout "$BASE" && git pull origin "$BASE"
git worktree list   # verify only main repo remains
```

### 6. Report

Summarize what was removed and confirm: feature branches (local + remote) and
PRs are untouched — only worktree directories and the tmux session are gone.

## Troubleshooting

- **"cannot remove a locked working tree"** → `git worktree unlock <path>` first
- **"no such session"** → `tmux list-sessions` and pass the correct name
- **Worktree dir already deleted manually** → `git worktree prune`

## See Also

- `/parallel-setup` — create the environment this skill tears down

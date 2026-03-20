---
name: parallel-cleanup
description: Cleanup parallel development environment (worktrees and tmux)
argument-hint: "[session-name]"
allowed-tools: Bash(git:*), Bash(tmux:*), Bash(rm:*)
---

# Parallel Development Cleanup

Clean up the parallel development environment by removing git worktrees and killing tmux sessions.

## Usage

```bash
/parallel-cleanup                  # Clean up default 'parallel-dev' session
/parallel-cleanup my-session       # Clean up specific session name
```

## What This Does

1. **List current worktrees** - Shows all active git worktrees
2. **Confirm cleanup** - Asks user which worktrees to remove
3. **Kill tmux session** - Terminates the specified tmux session
4. **Remove worktrees** - Deletes worktree directories and git metadata
5. **Return to develop** - Checks out develop branch in main repository

## Workflow

### 1. Check Current State

```bash
# List tmux sessions
echo "Active tmux sessions:"
tmux list-sessions

# List git worktrees
echo ""
echo "Active git worktrees:"
git worktree list
```

### 2. Confirm with User

Use AskUserQuestion to confirm:
- Which tmux session to kill (default: `parallel-dev`)
- Which worktrees to remove (show list from `git worktree list`)
- Whether to keep any worktrees for later use

### 3. Kill tmux Session

```bash
session_name="${ARGUMENTS:-parallel-dev}"

if tmux has-session -t "$session_name" 2>/dev/null; then
  tmux kill-session -t "$session_name"
  echo "✓ Killed tmux session: $session_name"
else
  echo "ℹ No tmux session named '$session_name' found"
fi
```

### 4. Remove Git Worktrees

```bash
# Get list of worktree paths (excluding main repo)
worktrees=$(git worktree list --porcelain | grep "worktree " | cut -d' ' -f2 | grep -v "^$(git rev-parse --show-toplevel)$")

# Remove each worktree
for worktree in $worktrees; do
  if [[ "$worktree" == *"worktree-worker"* ]] || [[ "$worktree" == *"worktree-"* ]]; then
    echo "Removing worktree: $worktree"
    git worktree remove "$worktree" --force
    echo "✓ Removed $worktree"
  else
    echo "⚠ Skipping $worktree (not a parallel-dev worktree)"
  fi
done

# Prune stale worktree metadata
git worktree prune
echo "✓ Pruned stale worktree metadata"
```

### 5. Return to Develop

```bash
# Switch back to develop branch
git checkout develop
echo "✓ Switched to develop branch"

# Show clean state
echo ""
echo "Remaining worktrees:"
git worktree list
```

### 6. Summary

```bash
echo ""
echo "Cleanup complete!"
echo "  - Killed tmux session: $session_name"
echo "  - Removed all parallel-dev worktrees"
echo "  - Returned to develop branch"
echo ""
echo "You can now:"
echo "  - Run /parallel-setup to start new parallel development"
echo "  - Continue working on develop branch normally"
```

## Safety Features

### Selective Removal

Only removes worktrees matching patterns:
- `~/worktree-worker*`
- `~/worktree-*`

Skips other worktrees to avoid accidental deletion.

### Force Remove

Uses `--force` flag in `git worktree remove` to handle:
- Uncommitted changes
- Branches not yet merged
- Dirty worktrees

**Important:** User confirmation is requested during step 2 (via AskUserQuestion) to check the status of worktrees. After confirmation, `git worktree remove --force` will delete the worktree regardless of its dirty state. There is no additional automatic warning after the initial confirmation.

### Confirmation

Always asks for confirmation (step 2) before proceeding:
- Which tmux session to kill
- Which worktrees to remove (shows status including uncommitted changes)
- User acknowledges that `--force` will be used for removal

## Common Scenarios

### Scenario 1: Clean Finish (All PRs Created)

```bash
# All workers completed their tasks and created PRs
/parallel-cleanup
# Removes everything, back to develop
```

### Scenario 2: Partial Cleanup (Keep Some Workers)

```bash
# Worker 1 and 2 finished, but Worker 3 still working
# Manually handle:
git worktree remove ~/worktree-worker1
git worktree remove ~/worktree-worker2
# Keep worker3 for later
```

### Scenario 3: Emergency Stop

```bash
# Something went wrong, need to stop everything
/parallel-cleanup
# Force removes all, even with uncommitted changes
# (After confirming with user)
```

## What Gets Removed

### Worktree Directories
- `~/worktree-worker1/`
- `~/worktree-worker2/`
- `~/worktree-worker3/`
- etc.

### Git Metadata
- `.git/worktrees/` entries
- Branch references for removed worktrees

### tmux Resources
- tmux session `parallel-dev`
- All windows within the session
- All panes and processes

## What Gets Preserved

### Main Repository
- Your main working directory
- All committed code
- Feature branches (even if worktree is removed)

### Remote Branches
- Pushed feature branches remain on GitHub
- PRs remain intact

### Other Sessions
- Other tmux sessions are not affected
- Other Claude Code sessions continue running

## Troubleshooting

### "worktree contains modified or untracked files"

```bash
# Option 1: Commit changes first
cd ~/worktree-worker1
git add .
git commit -m "WIP: Save progress"
git push

# Option 2: Force remove (loses changes)
git worktree remove ~/worktree-worker1 --force
```

### "cannot remove a locked working tree"

```bash
# Unlock and remove
git worktree unlock ~/worktree-worker1
git worktree remove ~/worktree-worker1
```

### "no such session: parallel-dev"

```bash
# List actual sessions
tmux list-sessions

# Use correct name
/parallel-cleanup actual-session-name
```

### Stale worktree metadata

```bash
# If worktree directory deleted manually
git worktree prune
```

## Manual Cleanup (If Skill Fails)

### Remove tmux session

```bash
tmux kill-session -t parallel-dev
```

### Remove worktrees

```bash
# List worktrees
git worktree list

# Remove one by one
git worktree remove ~/worktree-worker1 --force
git worktree remove ~/worktree-worker2 --force
git worktree remove ~/worktree-worker3 --force

# Clean up stale metadata
git worktree prune
```

### Return to develop

```bash
cd ~/work/english_learn_app
git checkout develop
```

## Best Practices

### Before Cleanup

1. **Ensure all work is committed**
   ```bash
   cd ~/worktree-worker1 && git status
   cd ~/worktree-worker2 && git status
   cd ~/worktree-worker3 && git status
   ```

2. **Push all branches**
   ```bash
   # In each worktree
   git push -u origin <branch-name>
   ```

3. **Create PRs if ready**
   ```bash
   # Use /review-fix or gh pr create
   ```

### After Cleanup

1. **Verify worktrees removed**
   ```bash
   git worktree list  # Should only show main repo
   ```

2. **Verify tmux session gone**
   ```bash
   tmux list-sessions  # Should not show parallel-dev
   ```

3. **Update develop branch**
   ```bash
   git pull origin develop
   ```

## See Also

- `/parallel-setup` - Setup parallel development environment
- `/start` - Start development from GitHub Issue
- `/review-fix` - Review and fix PR feedback

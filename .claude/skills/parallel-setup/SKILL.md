---
name: parallel-setup
description: Setup tmux parallel development environment with git worktrees
argument-hint: "[worker-count]"
allowed-tools: Bash(git:*), Bash(tmux:*), Bash(mkdir:*), Bash(gh:*)
---

# Parallel Development Setup

Setup tmux-based parallel development environment with git worktrees for concurrent feature development.

## Usage

```bash
/parallel-setup          # Interactive mode - asks for issue numbers
/parallel-setup 3        # Setup 3 workers (asks for issue numbers)
```

## What This Does

1. **Ask for Issue numbers** - Prompts you to specify which GitHub Issues each worker should handle
2. **Fetch latest develop** - Updates the develop branch from remote
3. **Create git worktrees** - Creates separate working directories for each feature branch
4. **Setup tmux session with pane split** - Creates a tmux session with all workers visible in split panes
5. **Launch Claude Code** - Starts an independent Claude Code session in each pane
6. **Auto-start development** - Runs `/start <issue-number>` in each worker

**Default layout: Pane split mode** - All workers displayed simultaneously in one window for easy monitoring.

## Workflow

**Implementation Note:** This workflow implements the **pane split layout** verified through testing. All workers are displayed simultaneously in split panes within a single tmux window.

### 1. Ask User for Issue Numbers

Use AskUserQuestion to gather:
- How many workers needed (default: 2, maximum: 4 recommended)
- Issue number for each worker
- Verify issues exist using `gh issue view`

**Important:** Fewer workers (2-3) provide better visibility in split-pane mode. For 4+ workers, consider if the screen space will be sufficient.

### 2. Fetch and Update Develop

```bash
git fetch origin
git checkout develop
git pull origin develop
```

### 3. Create Git Worktrees

For each worker (example with 3 workers handling issues #100, #101, #102):

```bash
# Get issue title for branch naming
issue_title=$(gh issue view 100 --json title -q .title)

# Sanitize and truncate title (UTF-8 safe)
# - Convert to lowercase
# - Replace non-alphanumeric with hyphens
# - Limit to 30 characters using awk (respects UTF-8)
# - Remove trailing hyphens
sanitized_title=$(echo "$issue_title" |
  tr '[:upper:]' '[:lower:]' |
  sed 's/[^a-z0-9]/-/g' |
  sed 's/--*/-/g' |
  awk '{print substr($0, 1, 30)}' |
  sed 's/-$//')

branch_name="feature/issue-100-${sanitized_title}"

# Create worktree
git worktree add ~/worktree-worker1 -b "$branch_name" develop
git worktree add ~/worktree-worker2 -b "feature/issue-101-..." develop
git worktree add ~/worktree-worker3 -b "feature/issue-102-..." develop
```

### 4. Create tmux Session with Pane Split Layout

**IMPORTANT: Use the verified approach that worked in testing**

```bash
# Step 1: Create session with appropriate dimensions for split panes
# Configurable dimensions (defaults work well for most screens)
TMUX_WIDTH=${TMUX_WIDTH:-200}
TMUX_HEIGHT=${TMUX_HEIGHT:-50}

tmux new-session -d -s parallel-dev -x $TMUX_WIDTH -y $TMUX_HEIGHT
tmux rename-window -t parallel-dev:0 workers

# Step 2: Setup Worker 1 (pane 0)
tmux send-keys -t parallel-dev:workers.0 'cd ~/worktree-worker1' Enter
sleep 1  # Wait for directory change

# Step 3: Split pane for Worker 2
tmux split-window -h -t parallel-dev:workers

# Step 4: Setup Worker 2 (pane 1)
tmux send-keys -t parallel-dev:workers.1 'cd ~/worktree-worker2' Enter
sleep 1  # Wait for directory change

# Step 5: For 3+ workers, continue splitting
# Worker 3 example:
# tmux split-window -h -t parallel-dev:workers
# tmux send-keys -t parallel-dev:workers.2 'cd ~/worktree-worker3' Enter
# sleep 1

# Step 6: Adjust layout based on worker count
# 2 workers: even-horizontal (side-by-side)
tmux select-layout -t parallel-dev:workers even-horizontal

# 3+ workers: tiled (grid layout)
# tmux select-layout -t parallel-dev:workers tiled

# Step 7: Verify pane directories (optional but recommended)
echo "Verifying pane directories:"
tmux list-panes -t parallel-dev:workers -F "pane #{pane_index}: #{pane_current_path}"
```

**Layout patterns by worker count:**

```bash
# 2 workers: Side-by-side
tmux select-layout -t parallel-dev:workers even-horizontal

# 3 workers: Tiled (uses available space efficiently)
tmux select-layout -t parallel-dev:workers tiled

# 4 workers: Perfect 2x2 grid
tmux select-layout -t parallel-dev:workers tiled
```

### 5. Launch Claude Code in Each Pane

**CRITICAL: Each pane must launch Claude independently in its own directory**

```bash
# Worker 1 (pane 0)
tmux send-keys -t parallel-dev:workers.0 'claude' Enter
sleep 2  # Wait for Claude to start

# Worker 2 (pane 1)
tmux send-keys -t parallel-dev:workers.1 'claude' Enter
sleep 2  # Wait for Claude to start

# Worker 3 (pane 2) - if applicable
# tmux send-keys -t parallel-dev:workers.2 'claude' Enter
# sleep 2

echo "✓ Claude Code launched in all panes"
```

**Pane targeting reference:**
- `parallel-dev:workers.0` = Worker 1 (first pane)
- `parallel-dev:workers.1` = Worker 2 (second pane)
- `parallel-dev:workers.2` = Worker 3 (third pane)
- etc.

### 6. Rename Claude Sessions (Optional)

After Claude Code sessions are ready, rename them for easier identification:

```bash
# Configurable startup delay (default: 10 seconds)
# Adjust CLAUDE_STARTUP_DELAY if Claude takes longer/shorter to initialize on your system
CLAUDE_STARTUP_DELAY=${CLAUDE_STARTUP_DELAY:-10}

# Wait for Claude sessions to be fully initialized
echo "Waiting ${CLAUDE_STARTUP_DELAY}s for Claude sessions to initialize..."
sleep $CLAUDE_STARTUP_DELAY

# Rename each Claude session in its pane
# Example with 2 workers handling issues #79 and #80:
tmux send-keys -t parallel-dev:workers.0 '/rename worker1-issue79' Enter
tmux send-keys -t parallel-dev:workers.1 '/rename worker2-issue80' Enter

# For 3 workers:
# tmux send-keys -t parallel-dev:workers.2 '/rename worker3-issue102' Enter

echo "✓ Claude sessions renamed"
```

**Note:** If Claude doesn't start in time, increase `CLAUDE_STARTUP_DELAY`:
```bash
CLAUDE_STARTUP_DELAY=15 /parallel-setup 2
```

### 7. Auto-start Development

After renaming, send `/start` command to begin development:

```bash
# Configurable post-rename delay (default: 3 seconds)
# Adjust POST_RENAME_DELAY if /rename takes longer to process
POST_RENAME_DELAY=${POST_RENAME_DELAY:-3}

# Wait for rename to complete
echo "Waiting ${POST_RENAME_DELAY}s for rename to complete..."
sleep $POST_RENAME_DELAY

# Send /start command to each worker pane with their issue numbers
tmux send-keys -t parallel-dev:workers.0 '/start 79' Enter
tmux send-keys -t parallel-dev:workers.1 '/start 80' Enter

# For 3 workers:
# tmux send-keys -t parallel-dev:workers.2 '/start 102' Enter

echo "✓ Development started in all workers"
```

**Note:** Timing adjustments may be needed based on system performance. The delays ensure commands are sent after Claude is ready to receive them.

### 8. Display Instructions for User

Show summary and instructions to the user:

```bash
# Example with 2 workers:
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Parallel Development Environment Ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Created 2 workers in split-pane layout:"
echo "  📍 Worker 1: Issue #79 (~/worktree-worker1) [pane 0]"
echo "  📍 Worker 2: Issue #80 (~/worktree-worker2) [pane 1]"
echo ""
echo "All workers are visible simultaneously!"
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│ Worker 1 (#79)    │ Worker 2 (#80)         │"
echo "│ [Claude running]  │ [Claude running]       │"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "To view the workers:"
echo "  1. Open a NEW terminal tab/window"
echo "  2. Run: tmux attach -t parallel-dev"
echo ""
echo "tmux Keybindings:"
echo "  Ctrl+b ←→      : Move between panes"
echo "  Ctrl+b o       : Next pane"
echo "  Ctrl+b q       : Show pane numbers"
echo "  Ctrl+b z       : Zoom/unzoom pane (focus on one)"
echo "  Ctrl+b d       : Detach (workers keep running)"
echo ""
echo "When done, cleanup with:"
echo "  /parallel-cleanup"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## Prerequisites

- tmux is installed (`brew install tmux` on macOS)
- GitHub CLI (`gh`) is authenticated
- On `develop` branch or able to switch to it
- No existing `parallel-dev` tmux session (or use `/parallel-cleanup` first)
- Terminal size: Minimum 200x50 recommended for comfortable split-pane viewing
  - Default dimensions: 200 columns × 50 rows
  - Customize via environment variables: `TMUX_WIDTH` and `TMUX_HEIGHT`
  - Example: `TMUX_WIDTH=250 TMUX_HEIGHT=60 /parallel-setup 2`

## Important Notes

### Avoid File Conflicts

Workers should work on different features/files:
- **Good**: worker1=auth, worker2=AWS Lambda, worker3=UI components
- **Bad**: All workers editing the same service file

### Disk Space

Each worktree creates a full copy of the working directory:
- 3 workers ≈ 3x repository size
- Use `/parallel-cleanup` when done to reclaim space

### Session Management

```bash
# List active tmux sessions
tmux list-sessions

# List git worktrees
git worktree list

# Attach to existing session
tmux attach -t parallel-dev

# Kill session (use /parallel-cleanup instead)
tmux kill-session -t parallel-dev
```

## Example Scenarios

### Scenario 1: Three Independent Features

```bash
/parallel-setup 3
# Enter issues: 100 (auth), 101 (payment), 102 (dashboard)
# Each worker develops independently
```

### Scenario 2: iOS + AWS + Docs

```bash
/parallel-setup 3
# Worker 1: iOS app feature
# Worker 2: AWS CDK changes
# Worker 3: Documentation updates
```

### Scenario 3: Bug Fixes

```bash
/parallel-setup 2
# Worker 1: Critical bug #85
# Worker 2: UI bug #86
```

## Cleanup

When development is complete, use `/parallel-cleanup` to:
- Remove git worktrees
- Kill tmux session
- Return to main repository

## Troubleshooting

### "worktree already exists"

```bash
git worktree list
git worktree remove ~/worktree-worker1
```

### "tmux session already exists"

```bash
tmux kill-session -t parallel-dev
# Or use: /parallel-cleanup
```

### Worker stuck or unresponsive

```bash
# Detach and re-attach
tmux detach
tmux attach -t parallel-dev

# Or kill and restart specific window
tmux kill-window -t parallel-dev:worker1-issue100
# Then recreate manually
```

## See Also

- `/parallel-cleanup` - Clean up parallel development environment
- `/start` - Start development from GitHub Issue (used by each worker)
- `/review-fix` - Review and fix PR feedback (used by each worker)

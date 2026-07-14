---
name: parallel-setup
description: Use when the user wants to work multiple GitHub Issues concurrently — creates git worktrees per issue, opens a split-pane tmux session, and launches an independent Claude Code session running /start in each pane.
argument-hint: "[worker-count]"
allowed-tools: Bash(git:*), Bash(tmux:*), Bash(mkdir:*), Bash(gh:*)
---

# Parallel Development Setup

Set up a tmux split-pane environment with one git worktree + Claude Code session per GitHub Issue.

## Usage

```bash
/parallel-setup          # asks for worker count and issue numbers
/parallel-setup 3        # 3 workers (asks for issue numbers)
```

## Workflow

### 1. Gather inputs

Use AskUserQuestion:
- Worker count (default 2; 2-3 fit best in split panes, 4 max → 2x2 grid)
- Issue number per worker — verify each with `gh issue view <N>`

Workers must target **different files/features** — same-file edits across
worktrees cause merge conflicts.

### 2. Update base branch

```bash
git fetch origin
BASE=$(git branch -r | grep -qE 'origin/dev$' && echo dev || echo develop)
git checkout "$BASE" && git pull origin "$BASE"
```

### 3. Create worktrees (one per worker)

```bash
issue_title=$(gh issue view <N> --json title -q .title)
sanitized_title=$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' |
  sed 's/[^a-z0-9]/-/g; s/--*/-/g' | awk '{print substr($0, 1, 30)}' | sed 's/-$//')
git worktree add ~/worktree-worker<i> -b "feature/issue-<N>-${sanitized_title}" "$BASE"
```

Note: each worktree is a full working-copy — check disk space for 3+ workers.

### 4. Create tmux session with split panes

```bash
tmux new-session -d -s parallel-dev -x "${TMUX_WIDTH:-200}" -y "${TMUX_HEIGHT:-50}"
tmux rename-window -t parallel-dev:0 workers

# pane 0 = worker 1; split once per additional worker
tmux send-keys -t parallel-dev:workers.0 'cd ~/worktree-worker1' Enter
tmux split-window -h -t parallel-dev:workers
tmux send-keys -t parallel-dev:workers.1 'cd ~/worktree-worker2' Enter
# repeat split-window + send-keys for worker 3, 4 …

# layout: 2 workers → even-horizontal, 3+ → tiled
tmux select-layout -t parallel-dev:workers even-horizontal

# verify each pane is in the right directory before proceeding
tmux list-panes -t parallel-dev:workers -F "pane #{pane_index}: #{pane_current_path}"
```

### 5. Launch Claude Code and start development

Timing matters: wait between steps so keystrokes land after Claude is ready.
Delays are configurable via `CLAUDE_STARTUP_DELAY` (default 10) and
`POST_RENAME_DELAY` (default 3); increase them if commands get swallowed.

```bash
# per pane i:
tmux send-keys -t parallel-dev:workers.<i> 'claude' Enter
sleep 2

# after all panes launched:
sleep "${CLAUDE_STARTUP_DELAY:-10}"
tmux send-keys -t parallel-dev:workers.<i> '/rename worker<i+1>-issue<N>' Enter
sleep "${POST_RENAME_DELAY:-3}"
tmux send-keys -t parallel-dev:workers.<i> '/start <N>' Enter
```

### 6. Report to user

Summarize concisely: worker → issue → worktree path table, then:
- Attach from a new terminal: `tmux attach -t parallel-dev`
- Key bindings: `Ctrl+b ←→` move panes, `Ctrl+b z` zoom, `Ctrl+b d` detach
- When done: `/parallel-cleanup`

## Prerequisites

- tmux installed, `gh` authenticated
- No existing `parallel-dev` session (run `/parallel-cleanup` first if so)
- Terminal ≥ 200x50 recommended (`TMUX_WIDTH`/`TMUX_HEIGHT` to customize)

## Troubleshooting

- **"worktree already exists"** → `git worktree list`, then `git worktree remove <path>`
- **"tmux session already exists"** → `/parallel-cleanup` (or `tmux kill-session -t parallel-dev`)
- **Pane didn't receive a command** → re-send with `tmux send-keys`; raise the delay env vars

## See Also

- `/parallel-cleanup` — tear down worktrees + session
- `/start` — the per-worker development workflow

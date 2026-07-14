# Parallel Development with tmux + Claude Code

tmux + git worktree で複数の GitHub Issue を並行開発するためのスキル。
手順の実体は [SKILL.md](SKILL.md) にあり、このREADMEは人間向けの最小メモ。

## Quick Start

```bash
# 前提: brew install tmux / gh auth status
/parallel-setup 2             # worker数を指定、Issue番号は対話で入力
tmux attach -t parallel-dev   # 別ターミナルから全workerを一画面で監視
/parallel-cleanup             # 終わったら worktree + tmux を一括撤去
```

## tmux 基本操作

| キー | 動作 |
|------|------|
| `Ctrl+b ←→` | ペイン移動 |
| `Ctrl+b z` | ペインのズーム/解除 |
| `Ctrl+b d` | デタッチ(workerは動き続ける) |

## 注意

- worker同士は**別のファイル/機能**を担当させる(同一ファイル編集はコンフリクトの元)
- worktreeはリポジトリのフルコピー — worker数ぶんのディスクを消費

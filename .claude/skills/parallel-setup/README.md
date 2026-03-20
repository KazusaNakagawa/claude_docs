# Parallel Development with tmux + Claude Code

tmuxとGit Worktreesを使った並行開発環境のクイックスタートガイド。

## Prerequisites

```bash
# tmuxのインストール（macOS）
brew install tmux

# GitHub CLIの認証確認
gh auth status
```

## Quick Start

### 1. 並行開発環境のセットアップ

```bash
# Claude Codeで実行（2-3 workerを推奨）
/parallel-setup 2
```

対話形式で以下を入力：
- Worker 1が担当するIssue番号（例: 79）
- Worker 2が担当するIssue番号（例: 80）

これにより以下が自動実行されます：
1. 最新のdevelopブランチをfetch
2. 各Issueごとにfeatureブランチを作成
3. Git worktreeを作成（`~/worktree-worker1`, `~/worktree-worker2`）
4. tmuxセッション `parallel-dev` を**ペイン分割モード**で起動
5. 各ペインで独立したClaude Codeセッションを開始
6. 各ワーカーで `/start <issue-number>` を実行

**✨ ペイン分割モード（デフォルト）:** 全workerが1画面に同時表示！

### 2. tmuxセッションにアタッチ

```bash
# 別のターミナルから
tmux attach -t parallel-dev
```

### 3. 表示レイアウト

`parallel-setup` は2つのレイアウトモードをサポートします。

#### モード1: ペイン分割（推奨）- 1画面で全worker同時表示

```bash
┌──────────────────────────────────────────────┐
│ Worker 1 (#79)     │ Worker 2 (#80)         │
│ ~/worktree-worker1 │ ~/worktree-worker2     │
│                    │                        │
│ Claude Code        │ Claude Code            │
│ [task output...]   │ [task output...]       │
│                    │                        │
└──────────────────────────────────────────────┘
```

**メリット:**
- 全workerの進捗を1画面で同時監視可能
- ウィンドウ切り替え不要

**tmuxキーバインド（ペイン分割モード）:**

| キー | 動作 |
|------|------|
| `Ctrl+b 矢印キー` | ペイン間の移動 |
| `Ctrl+b o` | 次のペインへ移動 |
| `Ctrl+b q` | ペイン番号を表示 |
| `Ctrl+b z` | 現在のペインを最大化/元に戻す |
| `Ctrl+b d` | デタッチ（セッションは継続） |

#### モード2: 別ウィンドウ - ウィンドウ切り替えで表示

**メリット:**
- 各workerが広い画面を使える
- 集中して1つのworkerを見たい場合に便利

**tmuxキーバインド（別ウィンドウモード）:**

| キー | 動作 |
|------|------|
| `Ctrl+b 0-9` | ウィンドウ番号で切り替え |
| `Ctrl+b n` | 次のウィンドウ |
| `Ctrl+b p` | 前のウィンドウ |
| `Ctrl+b d` | デタッチ（セッションは継続） |
| `Ctrl+b ,` | ウィンドウ名変更 |

### 4. 各ワーカーでの作業

ペイン分割モードでは、1つのtmuxウィンドウ内の各ペインでClaude Codeが動作しています：

```bash
# Worker 1（左ペイン、Issue #100）
# 既に /start 100 が実行済み
# あとは通常通り開発

# Worker 2（右ペイン、Issue #101）
# 既に /start 101 が実行済み

# Worker 3（別のペイン、Issue #102）
# 既に /start 102 が実行済み
```

※ 別ウィンドウモードを使用する場合は、各tmuxウィンドウ（window 0, 1, 2）でClaude Codeが動作します。

### 5. クリーンアップ

全ての作業が完了したら：

```bash
# Claude Codeで実行（どのワーカーからでも可）
/parallel-cleanup
```

これにより：
- tmuxセッション `parallel-dev` を終了
- 全てのworktreeを削除
- developブランチに戻る

## 使用例

### 例1: iOS/AWS/Docsの3チーム体制

```bash
/parallel-setup 3
# Issue #85: iOS UI改善
# Issue #86: AWS Lambda最適化
# Issue #87: ドキュメント更新
```

### 例2: 緊急バグ修正2件

```bash
/parallel-setup 2
# Issue #90: クリティカルバグ修正
# Issue #91: UI表示崩れ修正
```

## Tips

### ファイル競合を避ける

各ワーカーは異なるファイルを編集するように計画：
- ✅ Worker 1: `EnglishLearnApp/Views/`, Worker 2: `aws/lib/`
- ❌ 全ワーカーが同じ`SpeechService.swift`を編集

### ディスク容量

Worktreeは作業ディレクトリのコピーを作成：
- 3ワーカー ≈ リポジトリサイズ × 3
- 不要になったら `/parallel-cleanup` で削除

### セッションの再接続

```bash
# デタッチ後に再接続
tmux attach -t parallel-dev

# 別ターミナルタブから同じセッションに接続（同時監視）
# タブ1
tmux attach -t parallel-dev

# タブ2（read-onlyモードで監視のみ）
tmux attach -t parallel-dev -r
```

### ペイン操作（ペイン分割モード）

```bash
# 特定のペインにフォーカス
Ctrl+b q          # ペイン番号を表示
Ctrl+b q {番号}   # 番号のペインに移動

# ペインの最大化/復元（1つのworkerに集中したい時）
Ctrl+b z          # 現在のペインを最大化
Ctrl+b z          # もう一度押すと元に戻る

# ペイン間の移動
Ctrl+b 矢印キー   # 方向キーで移動
Ctrl+b o          # 次のペインへ
```

### 現在の状態確認

```bash
# アクティブなtmuxセッション
tmux list-sessions

# アクティブなworktree
git worktree list

# 各ワーカーのブランチ確認
git branch --all
```

## Troubleshooting

### "tmux session already exists"

```bash
# 既存のセッションを確認
tmux list-sessions

# 既存セッションに接続するか、削除
tmux attach -t parallel-dev
# または
/parallel-cleanup
```

### "worktree already exists"

```bash
# 既存のworktreeを確認
git worktree list

# 削除
git worktree remove ~/worktree-worker1
# または
/parallel-cleanup
```

### ワーカーが応答しない

```bash
# デタッチして再接続
Ctrl+b d
tmux attach -t parallel-dev

# 特定のウィンドウを再起動
tmux kill-window -t parallel-dev:0
# 手動で再起動
```

## Architecture

### Git Worktrees

```bash
main repository (~/work/english_learn_app)
├── .git/
├── .claude/skills/
│   ├── parallel-setup/
│   └── parallel-cleanup/
└── ...

worktree-worker1 (~/worktree-worker1)  [feature/issue-100-auth]
├── .git -> ../work/english_learn_app/.git/worktrees/worker1
└── ... (full working copy)

worktree-worker2 (~/worktree-worker2)  [feature/issue-101-payment]
└── ...

worktree-worker3 (~/worktree-worker3)  [feature/issue-102-dashboard]
└── ...
```

### tmux レイアウト

#### ペイン分割モード（推奨）

```bash
tmux session: parallel-dev
└── window 0: workers (3 panes)
    ├── pane 0: worker1-issue100 [Claude Code session]
    ├── pane 1: worker2-issue101 [Claude Code session]
    └── pane 2: worker3-issue102 [Claude Code session]
```

すべてのworkerが1画面に同時表示されます。

#### 別ウィンドウモード

```bash
tmux session: parallel-dev
├── window 0: worker1-issue100  [Claude Code session]
├── window 1: worker2-issue101  [Claude Code session]
└── window 2: worker3-issue102  [Claude Code session]
```

Ctrl+b {番号} でウィンドウを切り替えます。

## Best Practices

1. **作業開始前に全てコミット**
   - メインリポジトリで未コミットの変更がないことを確認
   - `git status` でクリーンな状態を確認

2. **定期的にプッシュ**
   - 各ワーカーで進捗があったらプッシュ
   - 他のワーカーからの影響を受けにくくなる

3. **こまめなクリーンアップ**
   - 作業完了したワーカーは早めに削除
   - ディスク容量の節約

4. **ブランチ名のルール**
   - `feature/issue-<番号>-<短い説明>`
   - `/parallel-setup` が自動生成

5. **PR作成のタイミング**
   - 各ワーカーで独立してPR作成可能
   - `/review-fix` で修正対応も並行実行可能

## See Also

- [SKILL.md](./SKILL.md) - `/parallel-setup` スキルの詳細仕様
- [../parallel-cleanup/SKILL.md](../parallel-cleanup/SKILL.md) - `/parallel-cleanup` スキルの詳細仕様
- [CLAUDE.md](../../../CLAUDE.md) - プロジェクト全体のClaude Code設定

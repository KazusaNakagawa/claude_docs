---
name: review-fix
description: Use when addressing PR review comments ("レビュー対応して", "fix PR feedback") — fetches all reviewer/bot comments, classifies them P0-P2, applies fixes in priority order, pushes, and resolves conversations.
argument-hint: "<pr-number>"
allowed-tools: Bash(git:*), Bash(gh:*)
---

# Review and Fix PR

Review PR feedback from reviewers or bots, apply fixes, and push updates.

## Usage

```bash
/review-fix 72   # Review and fix PR #72
```

## Workflow

### Phase 1: Fetch Feedback

```bash
gh pr view $ARGUMENTS --comments
gh api --paginate repos/{owner}/{repo}/pulls/$ARGUMENTS/comments
gh api --paginate repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews
```

**完了条件:** 全てのレビューコメントとレビュー状態を取得できた

### Phase 2: Classify & Prioritize

`references/review-criteria.md` の基準に従い、各コメントを分類：

1. 全コメントを P0 / P1 / P2 に分類
2. P0 があれば最優先で対応リストに追加
3. P1 は原則対応（工数大なら確認）
4. P2 は時間があれば対応

**完了条件:** 対応すべきコメントのリストが確定

### Phase 3: Apply Fixes

優先度順に修正を適用：

1. P0 を全て解消
2. P1 を順次対応
3. P2 は可能な範囲で対応

**完了条件:** 対応リストの項目が全て解消

### Phase 4: Commit & Verify

```bash
git add <changed-files>
git commit -m "fix: Address PR review feedback"
git push
gh pr checks $ARGUMENTS
```

**完了条件:** push 成功、CI が green（または確認中）

### Phase 5: Resolve Conversations

対応済みのレビューコメントは GitHub 上で **Resolve conversation** を実行して閉じる。
未対応のものと見分けがつくよう、**今回直したスレッドだけ** を resolve すること
（push しただけでは resolved にならない）。

1. 未解決スレッドと、その先頭コメント（path/line/author/body）を取得：

   ```bash
   gh api graphql -f query='
   query($owner:String!,$repo:String!,$pr:Int!){
     repository(owner:$owner,name:$repo){
       pullRequest(number:$pr){
         reviewThreads(first:100){
           nodes{
             id isResolved
             comments(first:1){ nodes{ path line author{login} body } }
           }
         }
       }
     }
   }' -F owner=<owner> -F repo=<repo> -F pr=$ARGUMENTS \
     --jq '.data.repository.pullRequest.reviewThreads.nodes[]
           | select(.isResolved==false)
           | {id, c: .comments.nodes[0]}'
   ```

2. 対応リスト（Phase 2）と path/line で突き合わせ、**今回修正したスレッドの `id`** を特定。

3. 各スレッドを resolve：

   ```bash
   gh api graphql -f query='
   mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' \
     -F id=<thread_id>
   ```

**完了条件:** 今回対応した全スレッドが `isResolved: true`。対応していない／保留したスレッドは resolve しない。

### Phase 6: Decide on Re-review (self-judgment)

修正を push したあと、**再レビューを依頼するかどうかを自分で判断する**。毎回は依頼しない。

| 今回の修正の規模 | 判断 |
|---|---|
| **クリティカル** — バグ修正、ロジック変更、API/スキーマ変更、セキュリティ | 再レビュー依頼する（`@sourcery-ai review`） |
| **中規模** — 関数の構造変更、新しい分岐、複数ファイルにまたがる挙動変更 | 再レビュー依頼する |
| **軽微 / 修正不要と判断** — 文言、ログレベル、コメント、命名、テスト追加のみ、または指摘を妥当でないと判断して見送り | 再レビュー依頼しない。対応サマリーを英語コメントで残すだけで完了 |

- 判断基準は「直したコードがレビュアーの再確認に値する挙動変更を含むか」。含まなければ依頼しない。
- 見送った（decline した）指摘しかない場合も再レビューは不要 — 理由を英語コメントで残す。
- 自己判断で進めてよい。ユーザーに毎回確認しない。

### Phase 7: Merge & Cleanup (when the user says "merge" / "ok merge")

CI が green になり、ユーザーがマージを了承したら、以下を自動的に一括実行する（機械的な後始末なので都度確認しない）：

```bash
gh pr checks <PR#>                     # CI green を確認
gh pr merge <PR#> --merge --delete-branch
gh pr view <PR#> --json state,mergedAt --jq '{state,mergedAt}'  # MERGED を確認
BASE=$(git branch -r | grep -qE 'origin/dev$' && echo dev || echo develop)
git checkout "$BASE"
git pull origin "$BASE"
git branch -d feature/issue-<N>-<short-description>   # ローカルブランチ削除
```

**このリポジトリは `delete_branch_on_merge` がリポジトリ設定で無効** なので、`--merge` だけではリモートブランチが残る。必ず `--delete-branch` を明示指定すること。もし付け忘れてマージ済みなら事後でも削除できる：`git push origin --delete <branch-name>`。CI がまだ green でなければマージせず、状況を報告して待つ。

## Conventions

- **All PR comments (mention replies, fix summaries, re-review triggers) MUST be in English** — matches the repo's PR/commit language convention. Never post Japanese in PR comments.

## Prerequisites

- GitHub CLI (`gh`) is installed and authenticated
- You are on the PR branch
- Have write access to the repository

## References

- [Review Criteria](references/review-criteria.md) - 優先度分類と対応判断基準

---
name: review-fix
description: Review PR feedback, fix issues, and push changes
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

## Prerequisites

- GitHub CLI (`gh`) is installed and authenticated
- You are on the PR branch
- Have write access to the repository

## References

- [Review Criteria](references/review-criteria.md) - 優先度分類と対応判断基準

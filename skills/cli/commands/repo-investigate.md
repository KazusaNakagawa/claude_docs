---
name: repo-investigate
description: Investigate repository structure, architecture, and dependencies
argument-hint: "[target-path] [--lang en|ja|both]"
allowed-tools: Glob, Grep, Read, Write, Bash(git:*), Bash(cat:*), Bash(ls:*), Bash(find:*)
---

# Repository Investigation

Investigate codebase structure, architecture overview, and dependency relationships.

## Usage

```bash
/repo-investigate                    # Investigate current directory (outputs both en + ja)
/repo-investigate src/               # Investigate specific path
/repo-investigate --lang en          # English report only
/repo-investigate --lang ja          # Japanese report only
/repo-investigate --lang both        # Both EN + JA reports (default)
/repo-investigate src/ --lang ja     # Specific path, Japanese only
```

## Language Detection

Parse `$ARGUMENTS` to extract the `--lang` flag and target path.

```
LANG_MODE = extract "--lang <value>" from $ARGUMENTS, default = "both"
TARGET_DIR = remaining argument after removing --lang flag, default = "."
```

Supported values: `en`, `ja`, `both`

---

## Workflow

### Phase 1: Project Overview

Identify the project type and technology stack.

```bash
# Check root-level files
ls -1

# Detect package manager / build tool
cat package.json        # Node.js
cat pyproject.toml      # Python
cat go.mod              # Go
cat Cargo.toml          # Rust
cat pom.xml             # Java/Maven
cat build.gradle        # Java/Gradle
```

**Output:**
- Language / framework
- Build tool / package manager
- Key config files found

**Done when:** Technology stack is identified.

### Phase 2: Directory Structure

Map the top-level directory layout and understand module boundaries.

```bash
# Directory tree (depth 2-3)
find ${TARGET_DIR:-.} -maxdepth 3 -type d \
  | grep -v -E '(node_modules|\.git|__pycache__|\.venv|dist|build|\.next)' \
  | sort

# Count source files by extension
find ${TARGET_DIR:-.} -type f \
  | grep -v -E '(node_modules|\.git|__pycache__|\.venv|dist|build)' \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
```

**Output:**
- Directory tree (annotated with purpose)
- File counts by type

**Done when:** Module boundaries and overall layout are clear.

### Phase 3: Entry Points & Core Components

Locate entry points, main modules, and key abstractions.

```bash
# Common entry point patterns
find ${TARGET_DIR:-.} -maxdepth 3 -type f \
  | grep -E '(main\.|index\.|app\.|server\.|cmd/)' \
  | grep -v -E '(node_modules|\.git|test|spec)'
```

Read entry point files to understand initialization flow and top-level imports.

**Done when:** Entry points and core modules are identified.

### Phase 4: Dependency Analysis

Analyze both external dependencies and internal module dependencies.

#### External dependencies

```bash
# Node.js
cat package.json | grep -A 100 '"dependencies"'

# Python
cat pyproject.toml || cat requirements.txt || cat Pipfile

# Go
cat go.mod

# Ruby
cat Gemfile
```

#### Internal dependencies

Use Grep to trace import/require patterns across the codebase:

```bash
# Find import patterns (adjust pattern per language)
grep -r "^import\|^from\|^require\|^use " ${TARGET_DIR:-.} \
  --include="*.ts" --include="*.py" --include="*.go" \
  -l | head -30
```

**Output:**
- External dependency list (grouped by category: framework / utility / dev)
- Internal coupling map (which modules depend on which)

**Done when:** Dependency graph is clear.

### Phase 5: Report

Determine output paths based on LANG_MODE, then write reports using the Write tool.

```
If docs/ exists in TARGET_DIR:
  EN_FILE = "${TARGET_DIR}/docs/repo-investigation.en.md"
  JA_FILE = "${TARGET_DIR}/docs/repo-investigation.ja.md"
Else:
  EN_FILE = "${TARGET_DIR}/repo-investigation.en.md"
  JA_FILE = "${TARGET_DIR}/repo-investigation.ja.md"
```

- `--lang en`   → Write EN_FILE only
- `--lang ja`   → Write JA_FILE only
- `--lang both` → Write both EN_FILE and JA_FILE (default)

After writing, display the generated report(s) to the user and list the output file paths.

---

## Report Templates

### English Template

```markdown
# Repository Investigation: [project name]

**Date**: YYYY-MM-DD
**Target**: [path investigated]
**Language**: English

---

## 1. Overview

| Item | Value |
|------|-------|
| Language | |
| Framework | |
| Build tool | |
| Package manager | |
| Estimated scale | X files / Y kloc |

## 2. Directory Structure

\`\`\`
[annotated tree]
\`\`\`

| Directory | Purpose |
|-----------|---------|
| `src/` | |
| `tests/` | |

## 3. Entry Points

| File | Role |
|------|------|
| | |

## 4. External Dependencies

### Runtime
- `package-name` — purpose

### Dev / Build
- `package-name` — purpose

## 5. Internal Module Dependencies

\`\`\`
[module A] → [module B] → [module C]
\`\`\`

Key observations:
- High-coupling areas: ...
- Core shared modules: ...

## 6. Findings & Notes

- [ ] Potential circular dependencies
- [ ] Outdated / unused dependencies
- [ ] Large modules worth splitting
- [ ] Missing documentation areas
```

---

### Japanese Template

```markdown
# リポジトリ調査レポート: [プロジェクト名]

**日付**: YYYY-MM-DD
**調査対象**: [調査したパス]
**言語**: 日本語

---

## 1. 概要

| 項目 | 値 |
|------|-----|
| 言語 | |
| フレームワーク | |
| ビルドツール | |
| パッケージマネージャー | |
| 推定規模 | X ファイル / Y kloc |

## 2. ディレクトリ構造

\`\`\`
[注釈付きツリー]
\`\`\`

| ディレクトリ | 用途 |
|------------|------|
| `src/` | |
| `tests/` | |

## 3. エントリーポイント

| ファイル | 役割 |
|---------|------|
| | |

## 4. 外部依存関係

### ランタイム
- `パッケージ名` — 用途

### 開発・ビルド
- `パッケージ名` — 用途

## 5. 内部モジュール依存関係

\`\`\`
[モジュールA] → [モジュールB] → [モジュールC]
\`\`\`

主要な観察事項:
- 高結合エリア: ...
- コア共有モジュール: ...

## 6. 調査結果・メモ

- [ ] 循環依存の可能性
- [ ] 古い・未使用の依存関係
- [ ] 分割を検討すべき大きなモジュール
- [ ] ドキュメントが不足しているエリア
```

---

## Notes

- Skip `node_modules`, `.git`, `dist`, `build`, `__pycache__` in all searches.
- For monorepos, apply Phase 2–5 per package under the workspace root.
- If `$ARGUMENTS` contains no path (only `--lang` flag or is empty), use `.` as TARGET_DIR.
- Always use the Write tool to save reports — do not print to stdout only.
- File naming convention:
  - English: `repo-investigation.en.md`
  - Japanese: `repo-investigation.ja.md`

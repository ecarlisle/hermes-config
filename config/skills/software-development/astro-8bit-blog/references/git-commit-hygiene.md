# Git Commit Hygiene for Astro Projects

## The Problem

When a repo has no `.gitignore` (or an empty 0-byte one), the initial commit may track `node_modules/`, `dist/`, and `.astro/`. Subsequent `git add` operations can re-stage these tracked-but-modified directories, leading to massive commits with thousands of unintended files.

## The Fix

**Never run `git rm -r --cached node_modules/`** — it times out on large directories.

Instead:
1. Write a proper `.gitignore` first (see template below)
2. Use explicit `git add <file>` paths — never `git add .`
3. Verify with `git status --short` before committing
4. If a bad commit was made: `git reset HEAD~1` returns to pre-commit state

## Minimal `.gitignore` for Astro Projects

```
# Dependencies
node_modules/

# Build output
dist/
.astro/

# Environment
.env
.env.local
.env.*.local

# OS files
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*.swo
```

## Recovery from a Bad Commit

```bash
# Undo the last commit, keep changes in working tree
git reset HEAD~1

# Now stage only what you want
git add src/components/Header.astro .gitignore
git commit -m "style(header): migrate navigation theme to dark arcade tokens"
```

## Key Rule

**Always `git add` specific files, never `git add .`** — especially in repos where `node_modules` is already tracked.

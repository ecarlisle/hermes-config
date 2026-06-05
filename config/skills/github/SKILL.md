---
name: github
description: "GitHub operations via gh CLI and REST API: auth, repos, PRs, issues, code review, codebase inspection."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, git, pr, issues, code-review, repos, gh-cli]
    category: github
---

# GitHub Operations

End-to-end GitHub operations via the `gh` CLI and REST API. Covers authentication, repository management, pull requests, issues, code review, and codebase inspection.

## When to use this skill

- User asks about GitHub repos, PRs, issues, code review, or auth
- User wants to create/manage/fork/clone repos
- User wants to open, review, or merge PRs
- User wants to create, triage, or label issues
- User wants to inspect codebase size, languages, or structure

## Prerequisites

- `gh` CLI installed (`gh --version`)
- Authenticated: `gh auth status`

---

## 1. Authentication

Before any GitHub operation, ensure you're authenticated.

### Quick Auth Check

```bash
gh auth status
gh auth login          # interactive login if not authenticated
```

### Auth Environment Setup

Source the helper script to auto-detect auth method and set environment variables:

```bash
source ~/.hermes/skills/github/scripts/gh-env.sh
```

After sourcing, these variables are set:
- `GH_AUTH_METHOD` — `"gh"`, `"curl"`, or `"none"`
- `GITHUB_TOKEN` — personal access token (if method is `"curl"`)
- `GH_USER` — GitHub username
- `GH_OWNER`, `GH_REPO`, `GH_OWNER_REPO` — resolved from git remote (if in a repo)

### Auth Methods

**Method 1: gh CLI (preferred)**
```bash
gh auth login
# Follow interactive prompts — supports HTTPS and SSH
```

**Method 2: Personal Access Token (fallback)**
```bash
# Set via environment
export GITHUB_TOKEN="ghp_..."

# Or store in ~/.hermes/.env
echo 'GITHUB_TOKEN=ghp_...' >> ~/.hermes/.env
```

**Method 3: SSH Keys**
```bash
# Configure gh to use SSH
gh config set git_protocol ssh
# Ensure your SSH key is added to GitHub
```

### Pitfalls
- **Token expiry:** Run `gh auth status` before operations. If expired, re-run `gh auth login`.
- **SSH vs HTTPS:** `gh` defaults to HTTPS. Set `git_protocol: ssh` in `~/.config/gh/config.yml` for SSH.
- **Fork PRs:** `gh pr create` needs `--repo owner/repo` when pushing from a fork.

---

## 2. Repository Management

Full repo operations: create, clone, fork, view, edit, rename, delete, releases.

### Quick Reference

```bash
gh repo create <name>                    # create new repo
gh repo clone <owner>/<repo>             # clone
gh repo fork <owner>/<repo>              # fork
gh repo view <owner>/<repo>              # view details
gh repo list                             # list repos
gh repo edit <owner>/<repo>              # edit settings
gh repo delete <owner>/<repo>            # delete
gh repo rename <old> <new>               # rename
gh release create <tag>                  # create release
gh release list                          # list releases
```

### REST API Cheatsheet

For operations not covered by `gh` CLI, use the REST API. See `references/github-api-cheatsheet.md` for the full reference including endpoints for repos, PRs, issues, CI/actions, releases, secrets, branch protection, and pagination.

### Common Patterns

**Create repo from template:**
```bash
gh repo create <name> --template <owner>/<template-repo> --public
```

**Set topics:**
```bash
gh repo edit <owner>/<repo> --add-topic "python,cli"
```

---

## 3. Pull Requests

Full PR lifecycle: create, list, view, review, merge, CI troubleshooting.

### Quick Reference

```bash
gh pr create                             # create PR
gh pr list                               # list PRs
gh pr view <number>                      # view PR
gh pr checkout <number>                  # checkout PR branch
gh pr review <number>                    # review PR
gh pr merge <number>                     # merge PR
gh pr close <number>                     # close PR
gh pr edit <number>                      # edit PR
gh pr diff <number>                      # view diff
gh pr comment <number>                   # add comment
gh pr checks <number>                    # check CI status
```

### PR Creation

Use the PR body templates:
- Feature PR: `templates/pr-body-feature.md`
- Bugfix PR: `templates/pr-body-bugfix.md`

```bash
gh pr create --title "feat: description" --body-file ~/.hermes/skills/github/templates/pr-body-feature.md
```

### Conventional Commits

Follow conventional commits format for PR titles and commit messages. See `references/conventional-commits.md` for the full quick reference.

Format: `type(scope): description`

Key types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`, `build`, `revert`

Breaking changes: Add `!` after type or `BREAKING CHANGE:` in footer.

### CI Troubleshooting

When CI fails on a PR, use the decision tree in `references/ci-troubleshooting.md` to diagnose:
- Test failures (assertion errors, import errors)
- Lint/formatting failures (ruff, black, eslint)
- Type check failures (mypy, pyright)
- Build/compilation failures
- Permission/auth failures
- Timeout failures
- Docker/container failures

```bash
# View failed CI logs
gh run view <RUN_ID> --log-failed

# Re-run after fix
gh pr checks --watch
```

### Fork → Branch → PR → Merge Workflow

```bash
gh repo fork owner/repo
cd repo
git checkout -b feature-branch
# ... make changes ...
git add . && git commit -m "feat: description"
git push origin feature-branch
gh pr create --title "feat: description" --body "Details..."
# ... review, CI, merge ...
gh pr merge --squash
```

---

## 4. Issues

Create, triage, label, assign, and manage GitHub issues.

### Quick Reference

```bash
gh issue create                          # create issue
gh issue list                            # list issues
gh issue view <number>                   # view issue
gh issue edit <number>                   # edit issue
gh issue close <number>                  # close issue
gh issue reopen <number>                 # reopen issue
gh issue comment <number>                # add comment
gh issue label <number>                  # manage labels
gh issue assign <number>                 # assign users
gh issue develop <number>                # create linked branch
```

### Issue Templates

- Bug report: `templates/bug-report.md`
- Feature request: `templates/feature-request.md`

```bash
gh issue create --title "Bug: ..." --body-file ~/.hermes/skills/github/templates/bug-report.md
```

### Triage Workflow

```bash
gh issue list --state open --limit 20
gh issue view <number>
gh issue label <number> --add "bug"
gh issue assign <number> --assignee @me
```

### REST API for Issues

```bash
# List issues
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues?state=open

# Create issue
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues \
  -d '{"title": "...", "body": "..."}'

# Search issues
curl -s "https://api.github.com/search/issues?q=bug+repo:$GH_OWNER/$GH_REPO"
```

Note: The Issues API also returns PRs. Filter with `"pull_request" not in item` when parsing.

---

## 5. Code Review

Review local changes before pushing, or review open PRs on GitHub.

### Pre-Push Review (Local)

```bash
# See scope of changes
git diff main...HEAD --stat
git log main..HEAD --oneline

# Full diff
git diff main...HEAD

# Check for common issues
git diff main...HEAD | grep -n "print(\|console\.log\|TODO\|FIXME\|HACK\|XXX\|debugger"
git diff main...HEAD | grep -in "password\|secret\|api_key\|token.*=\|private_key"
git diff main...HEAD | grep -n "<<<<<<\|>>>>>>\|======="
```

### PR Review Workflow

1. **Gather context:**
```bash
gh pr view <number>
gh pr diff <number> --name-only
gh pr checks <number>
```

2. **Check out PR locally:**
```bash
git fetch origin pull/<number>/head:pr-<number>
git checkout pr-<number>
```

3. **Read the diff:**
```bash
git diff main...HEAD
# For each changed file, use read_file for full context
```

4. **Run automated checks:**
```bash
python -m pytest 2>&1 | tail -20
ruff check . 2>&1 | head -30
```

5. **Apply review checklist** — Correctness, Security, Code Quality, Testing, Performance, Documentation

6. **Post the review:**

```bash
# Approve
gh pr review <number> --approve --body "LGTM!"

# Request changes
gh pr review <number> --request-changes --body "See inline comments."

# Inline comment via API
gh api repos/$GH_OWNER/$GH_REPO/pulls/<number>/comments \
  --method POST \
  -f body="Suggestion here" \
  -f path="src/file.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 \
  -f side="RIGHT"
```

7. **Post summary comment** using the template at `references/review-output-template.md`

8. **Clean up:**
```bash
git checkout main
git branch -D pr-<number>
```

### Review Output Format

Use the structured format from `references/review-output-template.md`:

```
## Code Review Summary
**Verdict: [Approved ✅ | Changes Requested 🔴 | Reviewed 💬]**

### 🔴 Critical
- **file.py:line** — description

### ⚠️ Warnings
- **file.py:line** — description

### 💡 Suggestions
- **file.py:line** — description

### ✅ Looks Good
- positive observations
```

### Verdict Decision
- **Approve** — no critical or warning-level issues
- **Request Changes** — any critical or warning-level issue
- **Comment** — observations only, nothing blocking

---

## 6. Codebase Inspection

Analyze repositories for lines of code, language breakdown, file counts, and code-vs-comment ratios using `pygount`.

### Installation

```bash
pip install --break-system-packages pygount 2>/dev/null || pip install pygount
```

### Basic Summary

```bash
cd /path/to/repo
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,.eggs,*.egg-info" \
  .
```

**IMPORTANT:** Always use `--folders-to-skip` to exclude dependency/build directories.

### Filter by Language

```bash
pygount --suffix=py --format=summary .
pygount --suffix=py,yaml,yml --format=summary .
```

### Output Formats

```bash
pygount --format=summary .    # Summary table
pygount --format=json .       # JSON for programmatic use
```

### Interpreting Results

Columns: Language, Files, Code, Comment, %

Special pseudo-languages: `__empty__`, `__binary__`, `__generated__`, `__duplicate__`, `__unknown__`

### Pitfalls
1. **Always exclude .git, node_modules, venv** — without `--folders-to-skip`, pygount crawls everything
2. **Markdown shows 0 code lines** — expected, pygount classifies Markdown as comments
3. **JSON shows low code counts** — use `wc -l` for accurate JSON line counts
4. **Large monorepos** — use `--suffix` to target specific languages

---

## Common Workflows

### Full PR Review End-to-End
```bash
# 1. Source auth
source ~/.hermes/skills/github/scripts/gh-env.sh

# 2. View PR
gh pr view 123
gh pr diff 123 --name-only
gh pr checks 123

# 3. Check out locally
git fetch origin pull/123/head:pr-123
git checkout pr-123

# 4. Review
git diff main...HEAD
# ... apply checklist ...

# 5. Submit review
gh pr review 123 --request-changes --body "Found issues — see inline comments."

# 6. Clean up
git checkout main
git branch -D pr-123
```

### Issue Triage
```bash
gh issue list --state open --limit 20
gh issue view <number>
gh issue label <number> --add "bug,priority-high"
gh issue assign <number> --assignee @me
```

### Release Workflow
```bash
git tag v1.2.3
git push origin v1.2.3
gh release create v1.2.3 --generate-notes
```

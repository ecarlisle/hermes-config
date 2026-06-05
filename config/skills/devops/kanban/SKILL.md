---
name: kanban
description: "Hermes Kanban multi-agent orchestration — task lifecycle, decomposition playbook, worker pitfalls, Codex lane isolation, and board operations."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [kanban, multi-agent, orchestration, workflow, codex]
    related_skills: [subagent-driven-development, coding-agents]
---

# Hermes Kanban Multi-Agent Orchestration

## Overview

This skill covers the full Hermes Kanban system: orchestrator decomposition playbook, worker lifecycle and pitfalls, Codex lane isolation, and board operations. The core worker lifecycle is auto-injected via `KANBAN_GUIDANCE`; this skill is the deeper playbook.

## When to Use

- Decomposing complex work into Kanban tasks across profiles
- Running as a Kanban worker (spawned by the dispatcher)
- Setting up isolated Codex lanes for implementation tasks
- Diagnosing stuck or crashed workers

## 1. Orchestrator Playbook (kanban-orchestrator)

### Step 0: Discover Available Profiles

**Never invent profile names.** The dispatcher silently drops unknown assignees.

```bash
hermes profile list
```

Cache the result. Ask the user if unsure.

### When to Use the Board

Create Kanban tasks when any apply: multiple specialists needed, work should survive restart, human-in-the-loop desired, parallel subtasks possible, review/iteration expected, audit trail matters.

### Anti-Temptation Rules

- **Do not execute the work yourself.** Route, don't implement.
- **Split multi-lane requests** before creating cards.
- **Run independent lanes in parallel** — only link true data dependencies.
- **Never create dependent work as independent ready cards** — use `parents=[...]`.
- **Decompose, route, summarize** — that's the whole job.

### Decomposition Playbook

1. **Understand the goal** — ask clarifying questions
2. **Sketch the task graph** — extract lanes, map to profiles, identify dependencies
3. **Create tasks** — independent lanes first (no parents), then children with `parents=[...]`
4. **Complete your own task** — summarize what you created
5. **Report to user** — plain prose describing the graph

### Dependency Gating

```python
t1 = kanban_create(title="research: costs", assignee="<profile-A>", body="...", tenant=os.environ.get("HERMES_TENANT"))["task_id"]
t2 = kanban_create(title="research: performance", assignee="<profile-A>", body="...")["task_id"]
t3 = kanban_create(title="synthesize", assignee="<profile-B>", body="...", parents=[t1, t2])["task_id"]
```

Children stay in `todo` until all parents reach `done`, then auto-promote to `ready`.

### Common Patterns

- **Fan-out + fan-in:** N parallel research cards → 1 synthesis card with all as parents
- **Parallel implementation + validation:** implementer + researcher run simultaneously → reviewer depends on both
- **Pipeline:** planner → implementer → reviewer, each gating the next
- **Same-profile queue:** N tasks, same assignee, no dependencies — dispatcher serializes
- **Human-in-the-loop:** worker calls `kanban_block()`, operator unblocks with comment

### Goal-Mode Cards

For long multi-step cards, use `goal_mode=True` to wrap the worker in a Ralph-style loop:

```python
kanban_create(title="Translate full docs to French", assignee="<translator>",
              goal_mode=True, goal_max_turns=15)
```

The judge re-evaluates after each turn; budget exhaustion blocks for human review.

### Recovering Stuck Workers

1. **Reclaim** — abort running worker, reset to `ready`
2. **Reassign** — switch to a different profile
3. **Change profile model** — edit profile config, then reclaim

## 2. Worker Pitfalls & Patterns (kanban-worker)

### Workspace Kinds

| Kind | Behavior |
|---|---|
| `scratch` | Fresh tmp dir, yours alone, GC'd on archive |
| `dir:<path>` | Shared persistent directory, treat as long-lived state |
| `worktree` | Git worktree, commit work here |

### Tenant Isolation

If `$HERMES_TENANT` is set, prefix memory entries with the tenant to prevent cross-tenant leaks.

### Good Handoff Shapes

**Coding task:**
```python
kanban_complete(summary="shipped rate limiter — 14 tests pass",
               metadata={"changed_files": [...], "tests_run": 14, "tests_passed": 14})
```

**Review-required (block instead of complete):**
```python
kanban_comment(body="review-required handoff:\n" + json.dumps({...}, indent=2))
kanban_block(reason="review-required: shipped, needs eyes on design choice")
```

**Research task:**
```python
kanban_complete(summary="3 libraries reviewed; vLLM wins on throughput",
               metadata={"sources_read": 12, "recommendation": "vLLM", "benchmarks": {...}})
```

### Claiming Created Cards

Only pass ids captured from successful `kanban_create` return values. Hallucinated ids are rejected and recorded.

```python
c1 = kanban_create(title="fix SQL injection", assignee="security-worker")
kanban_complete(summary="...", created_cards=[c1["task_id"]])
```

### Block Reasons

Good: one sentence naming the specific decision needed. Put full context in a comment.

```python
kanban_comment(body="Full context: ...")
kanban_block(reason="Rate limit key: IP (NAT-unsafe) or user_id (requires auth)?")
```

### Heartbeats

Good: `"epoch 12/50, loss 0.31"`. Bad: `"still working"`. Every few minutes max.

### Retry Diagnostics

| Outcome | Meaning | Action |
|---|---|---|
| `timed_out` | Hit max_runtime_seconds | Chunk the work |
| `crashed` | OOM/segfault | Reduce memory |
| `spawn_failed` | Profile config issue | Block and ask human |
| `blocked` | Previous attempt blocked | Read unblock comment |

### Do NOT

- Use `delegate_task` as a substitute for `kanban_create`
- Call `clarify` (headless — will timeout silently)
- Modify files outside `$HERMES_KANBAN_WORKSPACE`
- Complete a task you didn't actually finish

## 3. Codex Lane (kanban-codex-lane)

### Ownership Rules

1. Hermes owns the Kanban lifecycle — Codex never calls `kanban_*` tools
2. Hermes owns final acceptance — Codex diffs are untrusted until reviewed
3. Hermes owns test execution — Codex test runs are advisory
4. Hermes owns safety — reject lanes that touch secrets, risk gates, or live trading
5. Hermes owns cleanup — kill stuck processes, remove temp worktrees

### Required Isolation

**Never run Codex in a shared dirty checkout.** Always use an isolated worktree/branch:

```bash
BRANCH="codex/${SAFE_TASK}/$(date -u +%Y%m%d%H%M%S)"
WORKTREE="/tmp/${SAFE_TASK}-codex-lane"
git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE" "$BASE"
```

Cleanup after: `git worktree remove "$WORKTREE"`

### Mode Selection

- **`codex exec --full-auto`** — bounded one-shot edits (preferred)
- **`codex /goal`** — broader multi-step work with durable objective tracking
- **Never `--yolo`** for safety-sensitive repos

### Prompt Requirements

Every Codex prompt must include: task_id, title, acceptance criteria, repo/worktree paths, branch, allowed file scope, ownership statement, prohibited actions, verification commands.

For prediction-market-bot, include mandatory safety constraints: no live REST order entry, no market orders, no execution crossing, no fake fills/PnL, no risk-gate weakening, no secrets.

### Reconciliation Checklist

- [ ] `git status --short` shows only expected files
- [ ] `git diff` reviewed by Hermes
- [ ] No secrets, caches, or unrelated artifacts
- [ ] Safety constraints preserved
- [ ] Commits small enough to cherry-pick
- [ ] Hermes ran canonical tests independently
- [ ] Accepted commits applied to Hermes-owned workspace
- [ ] Rejected work documented with reason

### Metadata Schema

Include `metadata.codex_lane` on every task where the lane was considered:

```json
{"codex_lane": {"used": true, "mode": "exec", "worktree": "...", "branch": "...",
  "result": "accepted|rejected|partial|timed_out", "accepted_commits": [...],
  "tests_run": [{"command": "...", "exit_code": 0, "owner": "hermes"}]}}
```

## Verification Checklist

- [ ] Orchestrator: profiles discovered before planning, task graph shown to user
- [ ] Worker: `kanban_show` called first, workspace kind handled correctly
- [ ] Codex lane: isolated worktree, prompt includes safety constraints, Hermes reviewed diff
- [ ] All: `kanban_complete` metadata shaped for downstream consumers

---
name: hermes-infra
description: "Operate, debug, and extend the Hermes Agent infrastructure — skill authoring, s6 container supervision, TUI slash commands, and gateway configuration."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hermes-agent, infrastructure, skills, docker, s6, tui, gateway]
    related_skills: [hermes-agent, systematic-debugging]
---

# Hermes Infrastructure

## Overview

This skill covers the operational infrastructure of Hermes Agent itself: authoring and maintaining skills, debugging TUI slash commands, and managing the s6-overlay Docker container supervision tree. Load this skill when working on Hermes internals rather than using Hermis as a tool.

## When to Use

- Authoring or editing in-repo SKILL.md files
- Debugging TUI slash command issues (autocomplete, dispatch, live state)
- Adding/modifying s6-overlay services in the Hermes Docker image
- Diagnosing gateway or container boot issues

## 1. Skill Authoring (hermes-agent-skill-authoring)

### Two Skill Locations

| Location | Path | Created via |
|---|---|---|
| User-local | `~/.hermes/skills/<category>/<name>/SKILL.md` | `skill_manage(action='create')` |
| In-repo | `skills/<category>/<name>/SKILL.md` | `write_file` + `git add` |

### Required Frontmatter

```yaml
---
name: my-skill-name
description: Use when <trigger>. <one-line behavior>.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [short, descriptive, tags]
    related_skills: [other-skill, another-skill]
---
```

Hard requirements: `name` and `description` fields, `---` at byte 0, description ≤ 1024 chars, total ≤ 100k chars. Peer skills sit at 8-14k chars.

### Peer-Matched Structure

```
# Title → ## Overview → ## When to Use → body → ## Common Pitfalls → ## Verification Checklist
```

### Workflow

1. Survey peers: `ls skills/<category>/`
2. Draft with `write_file` to `skills/<category>/<name>/SKILL.md`
3. Validate frontmatter (name, description, size limits)
4. `git add` + `git commit`
5. Note: current session won't see the new skill (loader cached at session start)

### Key Pitfalls

- `skill_manage(action='create')` writes to `~/.hermes/skills/`, NOT the repo — use `write_file` for in-repo
- Leading whitespace before `---` fails validation
- `related_skills` should reference in-repo skills only (user-local refs break for other clones)

## 2. s6 Container Supervision (hermes-s6-container-supervision)

### Architecture

```
/init (PID 1, s6-overlay v3.2.3.0)
├── cont-init.d/           ← oneshot setup (UID remap, seed, reconcile)
├── s6-rc.d/               ← static services (main-hermes, dashboard)
└── /run/service/          ← runtime per-profile gateways (tmpfs)
```

**Architecture B** (CMD as main program) is used because cont-init.d can't receive CMD args and s6 halt doesn't propagate exit codes. The container CMD is `/opt/hermes/docker/main-wrapper.sh`.

### Key Files

| Path | Role |
|---|---|
| `docker/stage2-hook.sh` | UID remap, chown, seed, skills sync |
| `docker/main-wrapper.sh` | Container CMD, routes user args |
| `hermes_cli/service_manager.py` | S6ServiceManager: register/start/stop gateways |
| `hermes_cli/container_boot.py` | reconcile_profile_gateways() on boot |

### Quick Recipes

```sh
# Verify s6 is PID 1
docker exec <c> sh -c 'cat /proc/1/comm'

# Inspect a gateway service
docker exec <c> /command/s6-svstat /run/service/gateway-<name>

# Watch reconciler log
docker exec <c> tail -n 50 /opt/data/logs/container-boot.log

# Add a new static service: create docker/s6-rc.d/<name>/type + run + dependencies
```

### Key Pitfalls

- Use `/command/s6-svstat` (absolute path) — `/command/` not on PATH for `docker exec`
- Profile dirs must be hermes-owned (stage2 chowns every boot)
- Service slots on tmpfs are wiped on restart — reconciler recreates from persistent volume
- Container exit 143 means something invoked halt; let CMD exit normally for real exit codes

## 3. TUI Slash Commands (debugging-hermes-tui-commands)

### Three-Layer Architecture

```
Python backend (hermes_cli/commands.py) → COMMAND_REGISTRY (source of truth)
    ↓
TUI gateway (tui_gateway/server.py) → slash.exec / command.dispatch
    ↓
TUI frontend (ui-tui/src/app/slash/) → local handlers + fallthrough
```

### Investigation Steps

1. Check TUI frontend: `search_files --pattern "/commandname" --file_glob "*.ts" --path ui-tui/`
2. Check Python backend: `search_files --pattern "CommandDef" --path hermes_cli/commands.py`
3. Check gateway: `search_files --pattern "complete.slash|slash.exec" --path tui_gateway/`

### Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| Command in TUI but not autocomplete | Missing from `COMMAND_REGISTRY` | Add `CommandDef` entry |
| In autocomplete but doesn't work | Missing handler in gateway or frontend | Add handler in `tui_gateway/server.py` or `app.tsx` |
| CLI/TUI behavior differs | Different implementations in cli.py vs local handler | Check both paths |
| Config persists but no live update | nanostore state not patched | Also call `patchUiState(...)` |

### CommandDef Shape

```python
CommandDef("name", "Description", "Category",
           cli_only=True, aliases=("alias",),
           args_hint="[arg1|arg2]", subcommands=("arg1", "arg2"))
```

### Key Pitfalls

- Rebuild TUI after changes: `npm --prefix ui-tui run build`
- `cli_only=True` commands won't work in gateway/messaging platforms
- Live UI state changes need both config.set AND nanostore patch
- Check both `StreamingAssistant`/`ToolTrail` AND `MessageLine` render paths

## Verification Checklist

- [ ] Skill changes: frontmatter valid, peer structure matched, committed
- [ ] Container changes: `scripts/run_tests.sh tests/docker/` passes (19 tests)
- [ ] TUI changes: rebuilt, tested in `hermes --tui`, autocomplete verified

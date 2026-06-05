---
name: game-engine-architecture
category: game-development
description: Workflow for building 2D Canvas game components using class-based architecture and Test-Driven Development (TDD).
---
# Game Engine Architecture and TDD Workflow

This skill governs developing game mechanics within the SF2 project (`src/js/`, `game.js`, `fighter.js`, `combat.js`). Core philosophy: encapsulation and determinism.

## 🛠️ Workflow

1. **Test First (TDD):** Create a Playwright integration test in `/tests/` that verifies the desired live game state change **before** touching core logic.
2. **Modular Implementation:** Create a specialized class in `src/js/` encapsulating state and behavior.
3. **Game Loop Integration:** Integrate into `game.js` via the fixed-timestep deterministic update loop.
4. **Verification:** Re-run the full Playwright suite; all tests must pass with zero regressions.

## ⚡ Fixed-Timestep Loop

Physics always runs at exactly 1/60s regardless of display refresh rate.

### Architecture

```
engine.js  →  captures real wall-clock delta each RAF frame → game.tick(realDt)
game.tick  →  accumulates real time (capped at 0.25s), drains while (acc >= FIXED_DT) → _fixedUpdate(FIXED_DT)
_fixedUpdate → the true physics tick — always receives exactly 1/60
```

### Constants

```js
const FIXED_DT = 1 / 60;       // 16.66ms — strict physics slice
const MAX_FRAME_TIME = 0.25;    // spiral-of-death cap
```

### ⚠️ Pitfalls — Fixed Timestep

- **Never pass variable dt to physics** — all entity/projectile `update()` calls must use `FIXED_DT`, not raw frame delta.
- **Accumulator cap is mandatory** — without `MAX_FRAME_TIME`, a tab switch causes hundreds of catch-up ticks.
- **Frame counter** — `frameCount` increments once per `_fixedUpdate`, giving deterministic integer indices for rollback/netcode.
- **`update()` → `tick()` delegation** — legacy `update(dt)` delegates to `tick(dt)`. Tests calling `update(N)` still work.

## 🔄 Game Loop Ordering in `_fixedUpdate()`

**Correct order:** `aiEngine.update(dt)` → `getVirtualKeys()` → `handleInput(aiKeys)` → `initiateAttack()` → entity updates → projectile update/collide/cull → render.

Reordering (e.g., `handleInput` before `aiEngine.update`) breaks AI input or causes `aiKeys` to be undefined.

## 🎮 Modules

Detailed implementation patterns for each subsystem live in the reference files:

| Module | Reference |
|--------|-----------|
| Special Moves & Input Buffer | `references/special-moves-input-buffer.md` |
| Projectile System | `references/projectile-system.md` |
| AI Opponent Engine | `references/ai-opponent-engine.md` |
| Rollback Netcode & Serialization | `references/fixed-timestep-serialization.md` |
| Training Mode (Pause / Frame Advance / HUD) | `references/training-mode.md` |
| Playwright Testing Patterns | `references/playwright-game-testing.md` |

## 🎯 Training Mode Summary

Two flags on Game: `this.isPaused` and `this.stepRequested`. **P** toggles pause; **.** requests single frame step while paused.

### Key Rules

- **`render()` called even when paused** — HUD must remain visible
- **`stepRequested` consumed immediately** after single `_fixedUpdate`
- **Accumulator still accumulates while paused** — no time loss on resume
- **RAF loop keeps running** — `engine.js` still calls `tick()` every frame
- **`_fixedUpdate()` bypasses pause guard** — it always runs. Use `tick()` (not `_fixedUpdate()`) for pause tests.

### `tick()` Logic

```js
tick(realDt) {
    if (realDt > MAX_FRAME_TIME) realDt = MAX_FRAME_TIME;
    this.accumulator += realDt;

    if (this.isPaused) {
        if (this.stepRequested) {
            this._fixedUpdate(FIXED_DT);
            this.accumulator -= FIXED_DT;
            this.stepRequested = false;
        }
        return; // render() still called by caller
    }

    while (this.accumulator >= FIXED_DT) {
        this._fixedUpdate(FIXED_DT);
        this.accumulator -= FIXED_DT;
    }
}
```

### ⚠️ Pitfalls — Training Mode

- **`_fixedUpdate()` ignores `isPaused`** — calling it directly bypasses pause. For pause tests, use `g.tick()`.
- **`render()` must be called when paused** — otherwise HUD vanishes
- **`stepRequested` must be consumed** — failing to reset causes auto-play
- **Accumulator keeps filling while paused** — do NOT reset it
- **P toggles, . is momentary** — do NOT make . a toggle
- **HUD follows fighters** — position panels using current `x, y`, not cached positions

## 🎯 Rendering Debug Helpers

### Hitstun State Machine
- `state = 'HITSTUN'` with `hitstunTimer` locks player inputs.
- Guard `handleInput` with `if (this.state === 'HITSTUN') return;`.
- In `combat.checkHit`: set `defender.state = 'HITSTUN'`, `defender.hitstunTimer = 0.25`, apply knockback.

### Health Bar HUD
- Per-player `Fighter.health`, hit flag `hasBeenHitThisAttack`.
- 10 damage per standard hit, respect hit flag to avoid multi-hit.
- Draw in `Game.render` before entities: red bg, green fg scaled to health %.

### Hurtbox / Hitbox Rendering
- Passive hurtbox: `rgba(234, 179, 8, 0.3)` (transparent yellow).
- Active attack hitbox: `rgba(239, 68, 68, 0.4)` (transparent red).
- Draw hitboxes after applying the fighter's canvas transformation matrix.

## 🔄 Collision Utilities

- Reusable `checkHit(attacker, defender)` in `combat.js`.
- Accounts for facing direction, hurtbox offsets, and fallback dimensions.

## ⚠️ General Pitfalls

- **Update loop ordering** — `aiEngine.update()` → `getVirtualKeys()` → `handleInput()` → `initiateAttack()`. Always.
- **`update()` vs `_fixedUpdate()`** — `update()` goes through accumulator; `_fixedUpdate()` is a raw physics tick. Tests needing exact frame control use `_fixedUpdate()` directly.
- **Batch key dispatch** — all key presses AND frame ticks must be in a SINGLE `page.evaluate()` call for input buffer tests, to prevent RAF from injecting duplicate frames.
- **Destructuring key names must match** when passing objects between `page.evaluate()` calls.
- **Commit rule** — on test pass: `git add . && git commit -m "agent: [concise description]"`.
- **`hasBeenHitThisAttack` on attacker, not defender** — prevents multi-hit within same attack's active window. Reset in `initiateAttack()`, never per-frame in game loop.
- **`isHoldingBack` direction** — `attackerOnRight ? 'arrowleft' : 'arrowright'` for P2. Inverted ternary causes silent blocking failure.
- **`handleCombatState` phase-before-decrement** — phase is computed from current timer BEFORE decrementing, so ACTIVE starts one tick later than naive math.
- **AI virtual key clearing** — `aiEngine.update()` clears keys before `getVirtualKeys()` is read. To inject test inputs for P2, override `getVirtualKeys()` rather than setting `_keyDown` directly.
- **BLOCK_STUN state string** — `'BACKWARD'` not `'WALK_BACKWARD'` in `isHoldingBack` state check.

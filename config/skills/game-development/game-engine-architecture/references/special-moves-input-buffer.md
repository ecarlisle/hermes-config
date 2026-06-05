# Special Moves — Input Buffer Implementation Reference

## File Map

| File | Role |
|------|------|
| `src/js/inputBuffer.js` | New module: `InputBuffer` class, `DIR` enum, `SPECIALS` pattern dict |
| `src/js/fighter.js` | Modified: imports `InputBuffer`/`DIR`, handles `SPECIAL_ATTACK` state |
| `src/js/combat.js` | Modified: `HADOUKEN`/`PDP` presets, special hitboxes, 25-damage scaling |
| `src/js/game.js` | Modified: passes `playerIndex` to Fighter, resets `activeSpecialMove` on rematch |

## DIR Enum Values

```
null: 0   U: 1   D: 2   L: 4   R: 8
UL: 5  (1|4)   UR: 9  (1|8)
DL: 6  (2|4)   DR: 10 (2|8)
```

Bitwise OR is used for diagonals so each value is unique.

## Special Move Definitions (SPECIALS dict)

| Move | Sequence (DIR[]) | Button | Motion Description |
|------|-------------------|--------|--------------------|
| HADOUKEN | `[D, DR, R]` | `f` | Quarter-circle forward (Street Fighter classic) |
| DRAGON_PUNCH | `[R, D, DR]` | `f` | Forward, Down, Down-Forward (Z-motion) |

Note: Only P1's button (`f`) is defined in `SPECIALS`. P2 matching works because the `matchSpecial()` matcher checks `_keyDown[btn]` which reads from the live keyboard map using the original-cased key. If P2 uses `'m'`, add `SPECIALS.HADOUKEN_P2` / `SPECIALS.PDP_P2` with `button: 'm'`, or use the `_keyDown` fallback which accepts any button press.

## Attack Presets (frame data at 60FPS)

| Preset | Startup | Active | Recovery | Total | Duration |
|--------|---------|--------|----------|-------|----------|
| LP (Light Punch) | 4 | 3 | 7 | 14 | ~0.233s |
| HADOUKEN | 8 | 6 | 12 | 26 | ~0.433s |
| PDP (Dragon Punch) | 3 | 5 | 14 | 22 | ~0.367s |

Frame duration constant: `FRAME_DURATION = 1/60 ≈ 0.016666s`

Timer initialization: `ATTACK_PRESETS.<preset>.totalFrames * (1/60)`

## Hitbox Geometry

| Move | Width | Height | Y Offset | Facing extend |
|------|-------|--------|----------|---------------|
| LP | 40 | 20 | +20 | From `x + width` |
| HADOUKEN | 90 | 40 | +30 | From facing edge |
| DRAGON_PUNCH | 50 | 70 | -20 | From facing edge |

For LEFT-facing fighters, the hitbox extent goes **backward** (subtract from `x`).

## Damage & Hitstun

| Attack Type | Damage | Hitstun |
|-------------|--------|---------|
| Standard (LP) | 10 | 0.25s |
| Special (HADOUKEN, DRAGON_PUNCH) | 25 | 0.35s |

## InputBuffer API

```js
// Construction
const buf = new InputBuffer(['w','a','s','d','f']);  // tracked key list

// Per-frame (call before push)
buf.setKeyDownMap(keys);  // pass the full keydown map

// Push discrete inputs (call for each held direction + attack)
buf.push('s', DIR.D, now);     // directional input
buf.push('f', DIR.null, now);  // attack button (dir=0, skipped by matcher)

// Attempt pattern match (prunes stale entries, drains on success)
const result = buf.matchSpecial(now);
// Returns: 'HADOUKEN' | 'DRAGON_PUNCH' | null
```

## State Flow

```
handleInput(keys, fixedDt)
  → setKeyDownMap(keys)
  → resolve composite direction (up/down/left/right)
  → push each held direction to buffer
  → push attack button (DIR.null) if pressed
  → matchSpecial(now)
    → if matched && grounded && (IDLE|FORWARD|BACKWARD):
        state = 'SPECIAL_ATTACK'
        activeSpecialMove = result
        attackFrameTimer = preset.totalFrames * (1/60)
        combatPhase = 'STARTUP'
        return (skip normal attacks)
    → else: continue normal input processing

initiateAttack()
  → guard: if state === 'SPECIAL_ATTACK' → return (no override)
  → state = 'ATTACK', set LP timer

update(fixedDt)
  → handleCombatState(this, fixedDt)  // processes ATTACK + SPECIAL_ATTACK timers
  → if SPECIAL_ATTACK && timer <= 0: activeSpecialMove = null
  → Dragon Punch: if ACTIVE phase + grounded → apply upward velocity (jumpImpulse * 0.6)
```

## Rematch Reset (game.js)

```js
p1.activeSpecialMove = null;
p2.activeSpecialMove = null;
```

## `hasBeenHitThisAttack` Flag — Placement and Reset

**The flag belongs on the ATTACKER, not the defender.** It prevents the same attack from dealing damage multiple times during its multi-frame active window.

```js
// ✅ CORRECT: On attacker, checked in checkHit
if (hit && !attacker.hasBeenHitThisAttack) {
    attacker.hasBeenHitThisAttack = true;
    // apply damage/stun...
}

// ❌ WRONG: On defender — prevents counter-hits from landing
if (hit && !defender.hasBeenHitThisAttack) { ... }
```

**Reset in `initiateAttack()`, NOT per-frame in game loop:**

```js
// ✅ CORRECT: Reset when new attack starts
initiateAttack() {
    if (this.state === 'ATTACK' || this.state === 'SPECIAL_ATTACK' || 
        this.state === 'HITSTUN' || this.state === 'BLOCK_STUN') return;
    this.hasBeenHitThisAttack = false;  // ← reset here
    this.state = 'ATTACK';
    // ...
}

// ❌ WRONG: Per-frame reset in game.js — causes multi-hit during active window
// In _fixedUpdate: this.entities[1].hasBeenHitThisAttack = false; // DON'T
```

## `isHoldingBack` Direction Logic

**The `attackerOnRight` mapping determines which key = "back" (away from attacker):**

```js
// ✅ CORRECT:
// Attacker on RIGHT → defender holds LEFT to block
// Attacker on LEFT  → defender holds RIGHT to block
const backKey = attackerOnRight ? 'arrowleft' : 'arrowright';  // P2
const backKey = attackerOnRight ? 'a' : 'd';                   // P1
```

**Common bug:** Inverting the ternary (`attackerOnRight ? 'arrowright' : 'arrowleft'`) causes blocking to fail silently — the defender IS holding a key, but it's the wrong one.

**State check:** Defender must be in `'IDLE'` or `'BACKWARD'` state to block. Note: the state string is `'BACKWARD'`, NOT `'WALK_BACKWARD'`.

## `handleCombatState` Frame Counting

**Phase is computed BEFORE timer decrement.** This means ACTIVE starts one tick later than naive math:

```
Tick 1: timer=14/60, currentFrame=ceil(14)=14, 14>10 → STARTUP, then timer→13/60
Tick 2: timer=13/60, currentFrame=13, 13>10 → STARTUP, timer→12/60
Tick 3: timer=12/60, currentFrame=12, 12>10 → STARTUP, timer→11/60
Tick 4: timer=11/60, currentFrame=11, 11>10 → STARTUP, timer→10/60
Tick 5: timer=10/60, currentFrame=10, 10>10? NO, 10>7? YES → ACTIVE ✓
```

For LP (startup=4, active=3, recovery=7, total=14): ACTIVE starts on tick 5, not tick 4.

## BLOCK_STUN Implementation

- `blockstunTimer` field on Fighter, parallel to `hitstunTimer`
- `handleInput` early return must include BLOCK_STUN: `if (state === 'HITSTUN' || state === 'BLOCK_STUN') return;`
- `initiateAttack` guard must include BLOCK_STUN
- During BLOCK_STUN, apply pushback friction and position updates (don't skip them)
- Serialize/deserialize `blockstunTimer` for rollback netcode
- Reset `blockstunTimer` in `_doRematch`

## Projectile Blocking

In `game.js` projectile collision handler, check if target is blocking:

```js
const isBlocking = target.state === 'BLOCK_STUN' || 
    (isHoldingBack(target, attacker) && target.combatPhase !== 'ACTIVE');
if (isBlocking) {
    applyBlockStun(target, preset);
} else {
    applyHitStun(target, preset);
}
```

1. **Bracket balance** across all modified JS files (parens, braces, square brackets)
2. **Import/export consistency**: `inputBuffer.js` exports `InputBuffer`, `DIR`; `fighter.js` imports them; `combat.js` exports `ATTACK_PRESETS`, `handleCombatState`, `checkHit`
3. **`DIR.null === 0`** (falsy, not `undefined` or `null` the value)
4. **Logical `&&`** (not bitwise `&`) in diagonal input resolution
5. **SPECIAL_ATTACK lockout** in both `handleInput()` and `initiateAttack()`
6. **Buffer consumption**: `this.entries = []` drained on match
7. **`playerIndex`** passed to Fighter constructors (0 for P1, 1 for P2)
8. **Tracked keys**: P1 uses `['w','a','s','d','f']`, P2 uses `['arrowup','arrowdown','arrowleft','arrowright','m']`

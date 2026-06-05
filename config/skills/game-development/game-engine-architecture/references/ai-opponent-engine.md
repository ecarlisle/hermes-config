# AI Opponent Engine — Implementation Reference

## Architecture Overview

The AI opponent (`src/js/ai.js`) uses a **virtual key injection** pattern: instead of reading keyboard input, the `AIEngine` class populates a virtual key-state object each frame that is fed into `Fighter.handleInput()` identically to how P1's real keyboard input works. This means the AI goes through the exact same input buffer → special move matching → state transition pipeline as a human player.

## AIEngine Class (`src/js/ai.js`)

### Constructor
```js
constructor(aiFighter, targetFighter, projectiles)
```
- `aiFighter` — the P2 Fighter instance
- `targetFighter` — the P1 Fighter instance
- `projectiles` — reference to `game.projectiles` array (shared, live)

### Internal State
- `reactionTimer` / `reactionFrames` — countdown and window size for decision throttle
- `currentAction` — string tag of active decision (e.g., `'WALK_FORWARD'`, `'HADOUKEN'`)
- `actionTimer` — frames remaining before the action expires
- `motionQueue` — array of `{ key, holdFrames }` for special move input sequences
- `motionTimer` — sub-frame counter for motion playback
- `virtualKeys` — the key-state object returned by `getVirtualKeys()`

### Public API
- `update(dt)` — called once per frame from `Game.update()`. Clears virtual keys, checks stun, plays motion queue, runs reaction throttle, makes decisions, executes actions.
- `getVirtualKeys()` — returns the virtual key map for this frame
- `reset()` — hard-reset all timers/queues/keys; called on rematch

## Reaction Throttle

The AI re-evaluates its decision every **12–15 frames** (randomized), preventing frame-perfect responses:

```js
_pickReactionWindow() {
    const range = REACTION_MAX_FRAMES - REACTION_MIN_FRAMES + 1;
    this.reactionFrames = REACTION_MIN_FRAMES + Math.floor(Math.random() * range);
    this.reactionTimer = this.reactionFrames;
}
```

While `reactionTimer > 0`, the AI continues executing `currentAction` without re-evaluating. When the timer expires, `_decide()` is called and a new action is chosen.

## Decision Matrix

### 1. Anti-Projectile Trigger (highest priority)
If `_findIncomingProjectile()` detects a P1-owned projectile moving toward the AI:
- 40% → `BLOCK` (hold back/right)
- 40% → `JUMP_FORWARD` (jump over projectile)
- 20% → `HADOUKEN` (fire own fireball)

### 2. Far Range (dx > 250px)
- 45% → `WALK_FORWARD` (close distance)
- 30% → `HADOUKEN` (long-range fireball)
- 25% → `IDLE` (stand ground)

### 3. Mid Range (120px ≤ dx ≤ 250px)
- 55% → `WALK_FORWARD` (close gap)
- 30% → Special (50/50 Hadouken or Dragon Punch)
- 15% → `WALK_BACK` (retreat)

### 4. Close Range (dx < 120px)
- 50% → `LIGHT_PUNCH`
- 30% → `DRAGON_PUNCH` (anti-attack launcher)
- 20% → `DUCK` (crouch/block)

## Motion Queue for Special Moves

When the AI decides to perform a special move, it loads a motion sequence into the queue:

```js
// P2 faces LEFT, so "forward" = arrowleft
const MOTION_HADOUKEN     = ['arrowdown', 'arrowdown', 'arrowleft', 'm'];
const MOTION_DRAGON_PUNCH = ['arrowleft', 'arrowdown', 'arrowdown', 'm'];
```

Each entry is held for **2 frames** (`holdFrames: 2`) to ensure the `InputBuffer` registers it. The `_playMotionQueue()` method feeds one key per frame into `virtualKeys`, which then flows through `handleInput()` → `InputBuffer.push()` → `InputBuffer.matchSpecial()` — the same path a human player's input takes.

## Projectile Detection

`_findIncomingProjectile()` iterates `this.projectiles` and checks:
1. `p.isActive` — projectile is alive
2. `p.owner !== 0` — only P1 projectiles (not AI's own)
3. Direction toward AI: `(p.dir > 0 && p.x < ai.x) || (p.dir < 0 && p.x > ai.x)`

## Game Loop Integration (`game.js`)

```js
// Constructor
this.aiEngine = new AIEngine(this.entities[1], this.entities[0], this.projectiles);

// In update():
this.aiEngine.update(fixedDt);
const aiKeys = this.aiEngine.getVirtualKeys();

// P2 attack trigger
if (aiKeys['m']) {
    this.entities[1].initiateAttack();
    this.entities[0].hasBeenHitThisAttack = false;
}

// Feed inputs
this.entities[0].handleInput(this.input, fixedDt);  // P1: real keyboard
this.entities[1].handleInput(aiKeys, fixedDt);       // P2: virtual keys

// Rematch
if (this.aiEngine) this.aiEngine.reset();
```

## ⚠️ Pitfalls — AI Engine

- **P2 faces LEFT**: All directional assumptions in the AI must account for P2's default facing. "Forward" = `arrowleft`, "back" = `arrowright`.
- **Virtual keys are rebuilt every frame**: `_clearVirtualKeys()` is called at the top of `update()`. Only the currently active action sets keys.
- **Motion queue overrides decision**: When `motionQueue.length > 0`, `_playMotionQueue()` runs and returns early — `_executeCurrentAction()` is skipped. This is correct because the motion queue IS the action.
- **Stun clears motion queue**: `if (this.ai.state === 'HITSTUN') { this.motionQueue = []; return; }` — interrupted specials don't resume.
- **Projectile detection only checks P1**: `p.owner !== 0` filter prevents the AI from reacting to its own fireballs.
- **Don't import inputBuffer.js in ai.js**: The AI uses raw key strings (e.g., `'arrowdown'`) in its motion queue, not DIR constants. This keeps the AI self-contained.
- **`reset()` on rematch**: Always call `aiEngine.reset()` in the rematch handler, or the AI starts the next round with stale state.

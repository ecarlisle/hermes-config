# Playwright Testing Patterns for SF2 Game Engine

## Critical: The `tickN` Helper

**`tickN` must call `_fixedUpdate()` directly, NOT `tick()` or `update()`.**

The `tick()` method uses a `while (accumulator >= FIXED_DT)` loop. Floating-point drift can cause a single `tick(1/60)` call to drain **two** `_fixedUpdate` ticks instead of one, producing off-by-frame-count failures. `_fixedUpdate()` is always exactly one physics tick.

```js
// ✅ CORRECT — exact N ticks, no accumulator drift
async function tickN(page, n) {
    await page.evaluate((n) => {
        const g = window.gameInstance;
        for (let i = 0; i < n; i++) {
            g._fixedUpdate(1 / 60);
        }
    }, n);
}

// ❌ WRONG — accumulator drift can double-tick
async function tickN_bad(page, n) {
    await page.evaluate((n) => {
        const g = window.gameInstance;
        for (let i = 0; i < n; i++) {
            g.tick(1 / 60);  // may drain 2 ticks due to FP drift
        }
    }, n);
}
```

**Exception — pause/resume tests:** When testing that pause freezes physics, use `g.tick()` (NOT `_fixedUpdate`) for the paused phase, because `_fixedUpdate()` **bypasses the pause guard**.

## Clear Input Helper

```js
async function clearInput(page) {
    await page.evaluate(() => {
        Object.keys(window.gameInstance.input).forEach(k => {
            window.gameInstance.input[k] = false;
        });
    });
}
```

## Batched Key Dispatch for Input Buffer Tests

ALL key presses and frame ticks must be in a SINGLE `page.evaluate()`.

## Teleporting Projectiles for Collision Tests

Destructure keys in `page.evaluate` must match object keys exactly. Use `?.isActive ?? false` for culled projectiles.

## AI Interference

The AI engine updates P2 every frame. Set P2 state AFTER all ticks, before assertion.

## Training Mode Test Patterns

### Testing Pause Halts Physics

Use `g.tick()` (NOT `_fixedUpdate`) for pause-phase ticks so `isPaused` is respected.

### Testing Frame Advance (Exactly +1 Frame)

Use `g.tick()` for step and no-step ticks. Use `>=` assertion for resume (accumulator residual).

## AI Virtual Key Injection (Testing P2 Behavior)

**The Problem:** `_fixedUpdate()` calls `aiEngine.update(dt)` which clears ALL virtual keys, then calls `getVirtualKeys()`. Setting keys on the `aiKeys` reference BEFORE calling `_fixedUpdate()` does nothing — they get cleared.

**The Solution:** Override `aiEngine.getVirtualKeys()` to inject your desired keys AFTER the AI clears them:

```js
// Step 1: Save original and install override (inside page.evaluate)
const origGetKeys = g.aiEngine.getVirtualKeys.bind(g.aiEngine);
g.aiEngine.getVirtualKeys = () => {
    const keys = origGetKeys();  // get AI-cleared keys
    keys['arrowright'] = true;   // inject your test input
    return keys;
};

// Step 2: Tick normally — P2's handleInput will see arrowright
for (let i = 0; i < 6; i++) {
    g._fixedUpdate(1/60);
}

// Step 3: Restore (optional — AI will resume controlling P2)
g.aiEngine.getVirtualKeys = origGetKeys;
```

**Important:** After blockstun/stun expires, the AI regains control. If you need P2 in a specific post-stun state, restore `getVirtualKeys` before the stun expires. Alternatively, assert `not.toBe('BLOCK_STUN')` instead of `toBe('IDLE')` to avoid AI interference.

## Debugging Game State Failures

When an assertion fails, add a `console.log` inside `page.evaluate()` before the non-debug return:

```js
const debug = await page.evaluate(() => {
    const g = window.gameInstance;
    const p1 = g.entities[0];
    const p2 = g.entities[1];
    // Log to browser console (visible in test output)
    console.log('DEBUG:', JSON.stringify({
        p1State: p1.state, p1CombatPhase: p1.combatPhase,
        p2Health: p2.health, p2State: p2.state,
        p2BlockstunTimer: p2.blockstunTimer,
        p2InputKeyDown: JSON.stringify(p2.inputBuffer._keyDown),
    }));
    return { /* actual assertion data */ };
});
```

The debug output appears in the Playwright test runner output prefixed with the test name.

## Failure Table

| Symptom | Cause | Fix |
|---------|-------|-----|
| Frame count off by 1-2 after N ticks | `tickN` using `g.tick()` -> FP accumulator drift | Use `g._fixedUpdate()` in `tickN` |
| Physics not frozen during pause test | `_fixedUpdate()` bypasses `isPaused` | Use `g.tick()` for pause-phase ticks |
| Frame count resumes with extra frames | Accumulator residual | Use `>=` assertion for resume tests |
| `proj.x` is `NaN` | Destructure key mismatch | Match param names to object keys |
| `projectileActive` is `undefined` | Projectile culled after hit | Use `?.isActive ?? false` |
| P2 state overwritten by wrong state | AI overwrote during ticks | Set state after ticks |
| Buffer duplicate entries | Separate `evaluate()` calls | Batch in single `evaluate()` |
| P2 `_keyDown` all false during test | `aiEngine.update()` cleared keys before `getVirtualKeys()` | Override `getVirtualKeys()` instead of setting `_keyDown` directly |
| ACTIVE phase starts one tick later than expected | `handleCombatState` computes phase BEFORE decrementing timer | Add 1 to expected tick count for phase transitions |
| P2 in wrong state after stun expires | AI overrides state during post-stun ticks | Assert `not.toBe('BLOCK_STUN')` / `not.toBe('HITSTUN')` instead of `toBe('IDLE')` |

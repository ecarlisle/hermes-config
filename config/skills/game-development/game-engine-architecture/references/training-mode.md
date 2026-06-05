# Training Mode Implementation Reference

## Overview

Training mode allows players to pause the game, advance frame-by-frame, and inspect real-time frame data. Toggled via **P** key, stepped via **.** (period) key.

## Game State Flags

```js
// In Game constructor:
this.isPaused = false;
this.stepRequested = false;
```

## Pause / Step Logic in `tick()`

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

## Critical Distinction: `_fixedUpdate()` vs `tick()`

- **`_fixedUpdate(dt)`** — raw physics tick. Always runs. **Ignores `isPaused`.**
- **`tick(realDt)`** — accumulator + pause gate. Checks `isPaused` and `stepRequested`.

**For tests:**
- Use `tickN` (calls `_fixedUpdate` directly) for precise frame-counting in non-pause scenarios.
- Use `g.tick()` for pause-phase ticks so `isPaused` is respected.
- Use `g.tick()` for resume-phase ticks to properly drain accumulator residual.

## Keyboard Hooks (P and .)

```js
window.addEventListener('keydown', (e) => {
    if (e.key === 'p' || e.key === 'P') {
        this.isPaused = !this.isPaused;
        if (!this.isPaused) this.stepRequested = false;
    }
    if ((e.key === '.' || e.key === 'Period') && this.isPaused) {
        this.stepRequested = true;
    }
});
```

- **P is a toggle** (pause <-> resume); **. is a one-shot step request**
- **Step only works while paused** — ignore `.` keypresses when not paused
- **Clear stale step on resume** — `if (!this.isPaused) this.stepRequested = false`

## Training Mode HUD

Drawn on canvas 2D context after entities/projectiles. Three layers:

### 1. Pause Overlay
- `rgba(0,0,0,0.45)` full-canvas tint
- "PAUSED" centered, white, bold 28px monospace
- Instruction line: "P = resume  |  . = frame step"

### 2. Per-Fighter Frame Data Panel
Positioned above each fighter, follows fighter movement:

- Panel: `rgba(0,0,0,0.7)` bg, 4px border in phase color
- Phase colors: STARTUP = amber, ACTIVE = green, RECOVERY = red

### 3. Input History Stream
Left side: P1 last 10 frames. Right side: P2 last 10 frames.

- Mini arrow chars for directions; `+ f` / `+ m` for attacks
- Current frame row highlighted
- Read from `this.inputHistory` (30s retained), NOT `inputBuffer.entries` (0.75s)

## Pitfalls

- **`_fixedUpdate()` ignores `isPaused`** — calling it directly bypasses pause. For pause tests, use `tick()`.
- **`render()` must be called when paused** — otherwise HUD vanishes
- **`stepRequested` must be consumed** — failing to reset causes auto-play
- **Accumulator keeps filling while paused** — do NOT reset it
- **P toggles, . is momentary** — do NOT make . a toggle
- **Step only while paused** — ignore `.` when unpaused
- **HUD follows fighters** — position panels using current `x, y`, not cached positions
- **Input history display** — use `this.inputHistory`, not `inputBuffer.entries`

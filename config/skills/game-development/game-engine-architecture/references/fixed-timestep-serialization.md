# Fixed Timestep, State Serialization & Input History — Implementation Reference

## File Layout

| File | Role |
|---|---|
| `src/js/engine.js` | RAF loop, captures real dt, calls `game.tick(dt)` |
| `src/js/game.js` | `tick()`, `_fixedUpdate()`, `serialize()`, `deserialize()`, `inputHistory` |
| `src/js/fighter.js` | Per-fighter state (x/y/vx/vy/state/health/bufferEntries) |
| `src/js/projectile.js` | Projectile class (x/y/dir/owner/isActive/animTick) |

## Fixed-Timestep Constants

```js
const FIXED_DT = 1 / 60;       // 16.66ms
const MAX_FRAME_TIME = 0.25;    // 250ms spiral-of-death cap
```

## engine.js — Minimal RAF Loop

```js
let lastTime = 0;
function mainLoop(currentTime) {
    let deltaTime = (currentTime - lastTime) / 1000;
    lastTime = currentTime;
    if (deltaTime > 0.001) {
        window.gameInstance.tick(deltaTime);
    }
    const ctx = document.getElementById('gameCanvas').getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    window.gameInstance.render(ctx, 0);
    requestAnimationFrame(mainLoop);
}
```

## game.js — tick() and _fixedUpdate()

```js
tick(realDt) {
    if (realDt > MAX_FRAME_TIME) realDt = MAX_FRAME_TIME;
    this.accumulator += realDt;
    while (this.accumulator >= FIXED_DT) {
        this._fixedUpdate(FIXED_DT);
        this.accumulator -= FIXED_DT;
    }
}

_fixedUpdate(dt) {
    this.frameCount++;
    this.aiEngine.update(dt);
    const aiKeys = this.aiEngine.getVirtualKeys();
    this.entities[0].handleInput(this.input, dt);
    this.entities[1].handleInput(aiKeys, dt);
    for (const e of this.entities) e.update(dt);
    if (this.input.get('f')) this.entities[0].initiateAttack();
    if (aiKeys['m']) this.entities[1].initiateAttack();
    handleCombatState(this.entities[0], this.entities[1], this.projectiles);
    for (const p of this.projectiles) p.update(dt, this.width);
    this.projectiles = this.projectiles.filter(p => p.isActive);
    const frame = this.frameCount;
    const p1Inputs = new Map(this.input);
    const p2Inputs = new Map();
    for (const [k, v] of Object.entries(aiKeys)) p2Inputs.set(k, v);
    this.inputHistory[frame] = { p1: p1Inputs, p2: p2Inputs };
    const oldestAllowed = frame - Math.ceil(30 / FIXED_DT);
    for (const key of Object.keys(this.inputHistory)) {
        if (Number(key) < oldestAllowed) delete this.inputHistory[key];
    }
}
```

## serialize()

```js
serialize() {
    const snapFighter = (f) => ({
        x: f.x, y: f.y, vx: f.velocity.x, vy: f.velocity.y,
        facing: f.facing, state: f.state, health: f.health,
        lives: f.lives, combatPhase: f.combatPhase,
        attackTimer: f.attackTimer, hitstunTimer: f.hitstunTimer,
        activeSpecialMove: f.activeSpecialMove,
        entries: f.inputBuffer.entries.map(e => ({ ...e })),
    });
    return {
        frameCount: this.frameCount,
        accumulator: this.accumulator,
        gameOver: this.gameOver,
        winner: this.winner,
        p1: snapFighter(this.entities[0]),
        p2: snapFighter(this.entities[1]),
        projectiles: this.projectiles.map(p => ({
            x: p.x, y: p.y, dir: p.dir, owner: p.owner,
            isActive: p.isActive, animTick: p.animTick
        }))
    };
}
```

## deserialize(snap)

```js
deserialize(snap) {
    this.frameCount = snap.frameCount;
    this.accumulator = snap.accumulator;
    this.gameOver = snap.gameOver;
    this.winner = snap.winner;
    for (const [idx, key] of [[0, 'p1'], [1, 'p2']]) {
        const s = snap[key];
        const f = this.entities[idx];
        f.x = s.x; f.y = s.y;
        f.velocity.x = s.vx; f.velocity.y = s.vy;
        f.facing = s.facing; f.state = s.state;
        f.health = s.health; f.lives = s.lives;
        f.combatPhase = s.combatPhase;
        f.attackTimer = s.attackTimer;
        f.hitstunTimer = s.hitstunTimer;
        f.activeSpecialMove = s.activeSpecialMove;
        f.inputBuffer.entries = s.entries.map(e => ({ ...e }));
    }
    this.projectiles = snap.projectiles.map(p =>
        new Projectile(p.x, p.y, p.dir, p.owner)
    );
    for (const [i, p] of this.projectiles.entries()) {
        p.isActive = snap.projectiles[i].isActive;
        p.animTick = snap.projectiles[i].animTick;
    }
}
```

## K/L Keyboard Hooks

```js
window.addEventListener('keydown', (e) => {
    if (e.key === 'k' || e.key === 'K') {
        this.savedSnapshot = this.serialize();
        console.log('[SAVE] frame', this.frameCount);
    }
    if (e.key === 'l' || e.key === 'L') {
        if (this.savedSnapshot) {
            this.deserialize(this.savedSnapshot);
            console.log('[LOAD] restored to frame', this.frameCount);
        }
    }
});
```

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Shallow-copy projectiles in serialize | Mutations corrupt saved snapshot | Deep-map to plain objects |
| Forget accumulator in serialize | Physics drift after restore | Always include accumulator |
| Forget inputBuffer entries | Special moves broken after restore | Copy entries array too |
| Don't prune inputHistory | Unbounded memory growth | Delete entries older than 30s |
| Variable dt in _fixedUpdate | Non-deterministic physics | Always pass FIXED_DT |
| deserialize doesn't rebuild Projectiles | draw() errors on restored state | new Projectile() for each entry |

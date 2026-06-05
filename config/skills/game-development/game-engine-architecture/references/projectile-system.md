# Projectile System — Implementation Reference

## File: `src/js/projectile.js`

```javascript
const PROJECTILE_SPEED = 360;       // pixels per second
const PROJECTILE_RADIUS = 18;       // approximate render radius in px
const PROJECTILE_HITBOX_SIZE = 26;  // square AABB half-extent for collisions

export class Projectile {
    constructor(x, y, dir, owner) {
        this.x = x;
        this.y = y;
        this.dir = dir;        // +1 = right, -1 = left
        this.owner = owner;    // 0 = P1, 1 = P2
        this.speed = PROJECTILE_SPEED;
        this.radius = PROJECTILE_RADIUS;
        this.isActive = true;
        this.animTick = 0;
    }

    update(dt, stageWidth) {
        if (!this.isActive) return;
        this.x += this.dir * this.speed * dt;
        this.animTick += 1;
        if (this.x < -this.radius * 2 || this.x > stageWidth + this.radius * 2) {
            this.isActive = false;
        }
    }

    draw(ctx) {
        if (!this.isActive) return;
        const cx = this.x, cy = this.y, r = this.radius;
        const pulse = 1.0 + 0.12 * Math.sin(this.animTick * 0.4);
        // Outer glow
        const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, r * 2.4 * pulse);
        glow.addColorStop(0, 'rgba(0, 200, 255, 0.22)');
        glow.addColorStop(0.5, 'rgba(50, 120, 255, 0.10)');
        glow.addColorStop(1, 'rgba(50, 120, 255, 0)');
        ctx.fillStyle = glow;
        ctx.beginPath(); ctx.arc(cx, cy, r * 2.4 * pulse, 0, Math.PI * 2); ctx.fill();
        // Main corona
        const corona = ctx.createRadialGradient(cx, cy, r * 0.2, cx, cy, r * pulse);
        corona.addColorStop(0, 'rgba(255, 255, 255, 0.95)');
        corona.addColorStop(0.35, 'rgba(100, 180, 255, 0.85)');
        corona.addColorStop(0.7, 'rgba(0, 220, 255, 0.55)');
        corona.addColorStop(1, 'rgba(0, 140, 255, 0)');
        ctx.fillStyle = corona;
        ctx.beginPath(); ctx.arc(cx, cy, r * pulse, 0, Math.PI * 2); ctx.fill();
        // Hot-white centre
        ctx.fillStyle = '#ffffff';
        ctx.beginPath(); ctx.arc(cx, cy, r * 0.28 * pulse, 0, Math.PI * 2); ctx.fill();
    }

    getAABB() {
        const half = PROJECTILE_HITBOX_SIZE / 2;
        return { left: this.x - half, right: this.x + half, top: this.y - half, bottom: this.y + half };
    }

    intersectsFighter(target) {
        const a = this.getAABB();
        const hbX = target.hurtbox?.xOffset || 0;
        const hbY = target.hurtbox?.yOffset || 0;
        const hbW = target.hurtbox?.width  || 60;
        const hbH = target.hurtbox?.height || 130;
        const b = { left: target.x + hbX, right: target.x + hbX + hbW, top: target.y + hbY, bottom: target.y + hbY + hbH };
        return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
    }
}
```

## Game Loop Integration (`game.js`)

### Constructor
```javascript
this.projectiles = [];
```

### Spawn (in `update()`, after entity updates)
```javascript
for (const fighter of this.entities) {
    if (
        fighter.state === 'SPECIAL_ATTACK' &&
        fighter.activeSpecialMove === 'HADOUKEN' &&
        fighter.combatPhase === 'ACTIVE' &&
        !fighter._projectileSpawned
    ) {
        fighter._projectileSpawned = true;
        const dir = fighter.facing === 'RIGHT' ? 1 : -1;
        const spawnX = fighter.facing === 'RIGHT'
            ? fighter.x + fighter.width + 10
            : fighter.x - 10;
        const spawnY = fighter.y + 35;
        this.projectiles.push(new Projectile(spawnX, spawnY, dir, fighter.playerIndex));
    }
}
```

### Update + Collision + Cull
```javascript
for (const proj of this.projectiles) {
    proj.update(fixedDt, this.width);
}
for (const proj of this.projectiles) {
    if (!proj.isActive) continue;
    for (const target of this.entities) {
        if (target.playerIndex === proj.owner) continue;
        if (proj.intersectsFighter(target)) {
            target.health = Math.max(0, target.health - 25);
            target.state = 'HITSTUN';
            target.hitstunTimer = 0.35;
            target.velocity.x = proj.dir > 0 ? 350 : -350;
            proj.isActive = false;
            break;
        }
    }
}
this.projectiles = this.projectiles.filter(p => p.isActive);
```

### Draw (in `render()`, after entities)
```javascript
for (const proj of this.projectiles) {
    proj.draw(ctx);
}
```

### Rematch
```javascript
p1._projectileSpawned = false;
p2._projectileSpawned = false;
this.projectiles = [];
```

## Combat Adjustment (`combat.js`)

In `checkHit()`, add early return for Hadouken:
```javascript
if (attacker.state === 'SPECIAL_ATTACK') {
    if (attacker.activeSpecialMove === 'HADOUKEN') return false;
    // ... rest of special hitbox logic (Dragon Punch, etc.)
}
```

## Fighter Adjustment (`fighter.js`)

In `update()`, when SPECIAL_ATTACK timer expires:
```javascript
if (this.state === 'SPECIAL_ATTACK' && this.attackFrameTimer <= 0) {
    this.activeSpecialMove = null;
    this._projectileSpawned = false;
}
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `PROJECTILE_SPEED` | 360 px/s | Travel speed |
| `PROJECTILE_RADIUS` | 18 px | Visual radius |
| `PROJECTILE_HITBOX_SIZE` | 26 px | AABB collision half-extent |
| Hadouken damage | 25 | On projectile hit |
| Hadouken hitstun | 0.35 s | On projectile hit |
| Hadouken knockback | ±350 px/s | Horizontal velocity on hit |

---
name: aabb-collision-testing
description: Guide for evaluating AABB collision logic on a live development server using browser tools.
category: game-development
summary: Provide a repeatable procedure to test AABB collision detection.
---
# AABB Collision Testing Skill

## Purpose
Provide a reliable, repeatable procedure to test Axis-Aligned Bounding Box (AABB) collision detection in a local game server environment.

## Prerequisites
- The development server must be running and serving the game page (default `http://localhost:8080`).
- The page must expose a global `window.game` object with `player1` and `player2` instances matching the combat module API.
- The browser tools must be functional.

## Steps
1. **Start the server** if not already running:
   ```bash
   npm start   # or the appropriate launch command for the project
   ```
2. Verify the server is reachable:
   - Open `http://localhost:8080` in a browser.
   - Confirm the page loads without errors.
3. Open a browser session via the Hermes `browser_navigate` tool.
4. Execute the following console expression to position the fighters and evaluate `checkHit`:
   ```js
   (async () => {
       const p1 = window.game.player1;
       const p2 = window.game.player2;
       p1.x = 400;
       p2.x = 420;
       p1.facing = 'RIGHT';
       p1.initiateAttack();
       p1.combatPhase = 'ACTIVE';
       const { checkHit } = await import('./src/js/combat.js');
       return checkHit(p1, p2);
   })()
   ```
5. Capture the console output using `browser_console` and verify the result is `true` or `false` as expected.
6. **Pitfalls**:
   - *Server not running*: The navigation will fail with `ERR_CONNECTION_REFUSED`. Ensure the correct start command and port.
   - *Missing `window.game`*: Some builds may not expose the game object; adjust the page or enable a debug flag.
   - *Cache issues*: Refresh the page before running the script.

## References
- `references/aabb-testing-notes.md` – detailed troubleshooting log and example outputs.

---

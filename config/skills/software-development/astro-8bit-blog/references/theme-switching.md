# Light/Dark Theme Switching

## Architecture

Zero-flash theme switching via `data-theme` attribute on `<html>`, semantic CSS custom properties, and a blocking inline script in `<head>`.

## Two-Component Design (KISS Decoupling)

The original monolithic `HardwareSwitch.astro` mixed theme state management with hardware emulation simulation. It has been **split into two isolated components** to prevent script cross-contamination:

### 1. `ThemeToggle.astro` — Theme Control Only

**Location:** `src/components/ThemeToggle.astro` (flat, global — not in atomic design tier)

**Current implementation (v4 — CSS-state-driven):**
- Uses **Unicode glyphs** (`☾`/`☼`) inside the traveling thumb for zero-footprint icons (not SVG)
- **CSS `:global()` state engine** manages thumb position — NO `translateX()` math in JavaScript
  ```css
  :global(html[data-theme="dark"]) .retro-slider-thumb {
    transform: translateX(32px);   /* flush right boundary */
    background: #3a3a4a;           /* slate metal gray */
  }
  :global(html[data-theme="light"]) .retro-slider-thumb {
    transform: translateX(0);      /* flush left boundary */
    background: #ef4444;           /* retro red alert */
  }
  ```
- `transition: transform 0.12s steps(3)` for authentic stepped pixel animation
- Inline script only sets `data-theme` attribute, updates Unicode character inside thumb, and manages `aria-checked`
- DOM structure: `.theme-switch-container` → `.retro-slider-track` (with `.track-icon--dark` / `.track-icon--light` background indicators) → `.retro-slider-thumb` (with `.thumb-internal-icon`) → hidden checkbox
- LocalStorage key: `'theme-preference'` (matches BaseHead zero-flash script — unified since v4)

**Responsibilities:**
- Controls `data-theme` attribute on `<html>`
- Persists preference to `localStorage` under key `'theme-preference'`
- Defaults to `'dark'`
- Click + keydown (Enter/Space) listeners on slider
- `syncThemeUI(theme)` function sets attribute, localStorage, checkbox, aria-checked, thumb icon textContent

**Must NOT contain:** emulation logic, payload tracking, hardware simulation, LED indicators, mode text, translateX animation math.

**Integrated into:** `Header.astro` (global nav — every page gets it)

### 2. `HardwareDashboard.astro` — Hardware Simulation Only

**Location:** `src/components/molecules/HardwareDashboard.astro` (molecules tier)

**Responsibilities:**
- Simulates NES-style zero-JS payload tracking interface
- Power slider UI (`#hw-emulation-toggle-ui`, `#hw-switch-thumb`, `#hw-emulation-checkbox`)
- LED indicator (`#hw-status-led`) — green when OFF, red when ON
- Status text (`#hw-status-mode`) — "SYSTEM PAYLOAD: 0.0 KB CLIENT JS BUNDLED" vs "SYSTEM PAYLOAD: EMULATION ACTIVE"
- Its own `<script is:inline>` with `updateHardwareUI(enabled)` function, default OFF

**Must NOT contain:** theme state, `data-theme` manipulation, localStorage theme key, theme color tokens that respond to `data-theme`.

**Placed on:** `index.astro` only (homepage simulator)

### Script Separation Rule

Each component's `<script is:inline>` block manages **only its own DOM elements and state**. Shared state, shared listeners, or cross-referencing between the two scripts is a **KISS violation**.

## Zero-Flash Script (BaseHead.astro)

Placed at the VERY TOP of `<head>`, before any `<style>` or `<link>` tags:

```html
<script is:inline>
  (function() {
    var theme = localStorage.getItem('theme-preference') || 'dark';
    document.documentElement.setAttribute('data-theme', theme);
  })();
</script>
```

This runs before the browser paints — no FOUC.

## CSS Variable Architecture (global.css)

```css
:root, html[data-theme="dark"] {
  --color-sys-bg: #0f0f14;
  --color-sys-text: #f3f4f6;
  --color-card-bg: #16161e;
  --color-border: #2e2e3f;
  --color-brand-danger: #ef4444;
  --color-led-glow: #22c55e;
}

html[data-theme="light"] {
  --color-sys-bg: #f4f4f5;
  --color-sys-text: #09090b;
  --color-card-bg: #ffffff;
  --color-border: #e4e4e7;
  --color-brand-danger: #dc2626;
  --color-led-glow: #ef4444;
}
```

Dark mode is the default (merged with `:root`). Light mode overrides via `[data-theme="light"]`.

## Component Audit Checklist

After implementing theme switching, verify every component:

1. No hardcoded `#hex` colors in `<style>` blocks — all must use `var(--color-*)` tokens
2. Background colors use `var(--color-sys-bg)` or `var(--color-card-bg)`
3. Text colors use `var(--color-sys-text)`
4. Borders use `var(--color-border)`
5. Interactive states use `var(--color-brand-accent)` / `var(--color-brand-danger)`

## localStorage Key Map

| Key | Component | Purpose |
|-----|-----------|---------|
| `'theme-preference'` | `BaseHead.astro` (zero-flash script) + `ThemeToggle.astro` | Single unified key for theme persistence. Both read and write this key. |

> **Unified since ThemeToggle v4.** Previously ThemeToggle used `'site-theme'` while BaseHead used `'theme-preference'` — a one-refresh-cycle migration gap. Now both use `'theme-preference'`.

## Pitfalls — Theme Toggle Development

- **Never use `translateX()` in JS for thumb position.** Use CSS `:global(html[data-theme="..."])` selectors to declaratively set `transform`. JS should only flip the `data-theme` attribute and update non-layout state (icon character, aria-checked).
- **`:global()` is required** because `data-theme` is on `<html>` (outside the component's scoped style range). Without `:global()`, the selector won't match.
- **Thumb travel distance must equal `track_width - thumb_width - border*2 - padding*2`.** For a 64px track, 24px thumb, 3px border, 2px offset: `64 - 24 - 6 - 4 = 30px`... but the actual value is `32px` because the thumb's `left: 2px` offset means it travels from `left:2` to `left:34`, a distance of `32px`. Measure empirically, don't calculate.
- **Unicode icons need `!important` on color** inside the thumb to override inherited token colors. Use `color: #ffffff !important;` on `.thumb-internal-icon`.
- **Stepped animation** (`transition: transform 0.12s steps(3)`) creates an authentic 3-frame mechanical snap. Do NOT use `ease` or `linear` — smooth motion is antithetical to 8-bit aesthetics.
- **Fallow cannot trace Astro template bindings.** `npx fallow fix --yes` will false-positive on exports like `SOCIAL_LINKS` and `SITE_URL` that are consumed in `.astro` templates. Manual surgical cleanup (search with `search_files` → verify imports → patch/delete) is the ONLY safe approach.

## Files Modified Across Versions

- `src/components/ThemeToggle.astro` — CREATED (v1), upgraded to SVG icons (v2), refined pixel grid (v3), CSS-state-driven with Unicode icons (v4)
- `src/components/molecules/HardwareSwitch.astro` — **DELETED** (was deprecated stub, fully removed in cleanup)
- `src/components/molecules/HardwareDashboard.astro` — CREATED: pure hardware emulation simulator
- `src/components/Header.astro` — INTEGRATED: `<ThemeToggle />` in global nav
- `src/pages/index.astro` — UPDATED: renders `<HardwareDashboard />` for homepage simulator
- `src/consts.ts` — PRUNED: dead `NAV_LINKS` export removed
- `BaseHead.astro` — contains zero-flash `<script is:inline>` at top of `<head>`
- `global.css` — semantic tokens under `[data-theme]` selectors

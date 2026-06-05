---
name: astro-8bit-blog
category: software-development
description: Initialize and build an Astro static blog with an 8-bit NES design system — native CSS tokens, semantic HTML, Playwright smoke tests, and Lighthouse-optimized dark-mode layout.
---

# Astro 8-Bit Blog

This skill governs the full lifecycle of the Astro blog at `/Users/eric/repos/blog`: scaffolding, design tokens, layout, content, testing, and performance optimization.

> **🚫 DEPRECATED REPO:** The `my-blog` repo at `/Users/eric/repos/my-blog` is DEPRECATED. Do NOT start, continue, or migrate work there. If you discover changes in `my-blog`, reapply them to `/Users/eric/repos/blog` instead. Always `cd /Users/eric/repos/blog` before starting work.

## 🎨 Design System: Clean 8-Bit NES Vibe

The visual language is a modern, readable interpretation of retro NES aesthetics — chunky 2px pixel borders, monospace typography, high-contrast dark mode. No scanline filters, no vibrating backgrounds.

### Core Tokens (defined in `src/styles/global.css` as CSS custom properties)

The project uses **native CSS custom properties** in `:root` for all design tokens. Color values are pre-computed hex literals (no SCSS color functions). Components consume tokens via `var(--*)` references.

**CSS custom properties** (in `src/styles/global.css`, consumed by component `<style>` blocks):

**Font tokens** (static, in `:root`):
| CSS Custom Property | Value | Purpose |
|---------------------|-------|---------|
| `--font-family-display` | `'Syncopate', sans-serif` | Syncopate — all-caps display headers, nav, UI |
| `--font-family-body` | `'Inter', sans-serif` | Inter — reading prose, body text |
| `--font-family-mono` | `'Fira Code', monospace` | Fira Code — code blocks, technical content |

**Theme-aware color tokens** (in `:root, html[data-theme="dark"]` and `html[data-theme="light"]`):
| CSS Custom Property | Dark Value | Light Value | Purpose |
|---------------------|------------|-------------|---------|
| `--color-sys-bg` | `#0f0f14` | `#f4f4f5` | Page background |
| `--color-sys-text` | `#f3f4f6` | `#09090b` | Primary text |
| `--color-card-bg` | `#16161e` | `#ffffff` | Card/surface background |
| `--color-border` | `#2e2e3f` | `#e4e4e7` | Borders |
| `--color-brand-danger` | `#ef4444` | `#dc2626` | Konami Red — alerts, active states |
| `--color-led-glow` | `#22c55e` | `#ef4444` | Status LED (green→red in light mode) |

**Static color tokens** (in `:root`, theme-independent):
| CSS Custom Property | Value | Purpose |
|---------------------|-------|---------|
| `--color-brand-primary` | `#a1a1aa` | Nav links, secondary text |
| `--color-brand-accent` | `#3b82f6` | Capcom Blue — hover, highlights |
| `--color-brand-gold` | `#eab308` | Gold accents |
| `--size-border-pixel` | `2px` | Chunky pixel-stepped borders |

**Legacy tokens** (still in `:root` for backward compat, prefer semantic aliases above):
| CSS Custom Property | Value | Purpose |
|---------------------|-------|---------|
| `--color-bg` | `#09090b` | Deep arcade CRT background (legacy) |
| `--color-surface` | `#1a1a24` | Elevated surface (legacy) |
| `--color-surface-raised` | `#2a2a36` | Highest lift (legacy) |
| `--color-text` | `#e4e4e7` | High-contrast reading text (legacy) |
| `--color-sys-surface` | `var(--color-surface)` | Semantic alias for component use |
| `--font-atkinson` | `var(--font-family-body)` | Legacy bridge alias — do NOT use for new work |

> **⚠️ Token naming note:** Always use the `--color-sys-*` semantic aliases in component `<style>` blocks for theme-aware colors. Use `--color-brand-*` for static brand colors. Legacy `--color-*` tokens are kept for backward compat but should not be used in new work.

Full variable reference: `references/design-tokens.md`
Build error catalog: `references/build-error-catalog.md`
Astro `<Image />` component API: `references/astro-image-component.md`
SEO & social metadata pattern: `references/seo-social-metadata.md`
Content schema patterns (incl. `auditAssert`): `references/content-schema-patterns.md`
Lighthouse CI component patterns (GlobalScoreboard, PostAuditBanner): `references/lighthouse-ci-components.md`
SEOHead missing global.scss diagnostic: `references/seohead-global-scss-fix.md`
Git commit hygiene: `references/git-commit-hygiene.md`
JSON-LD SchemaGraph component: `references/json-ld-schema-graph.md`
Astro 6 content entry identity (`post.id` vs `post.slug`): `references/astro6-content-entry-identity.md`
Light/dark theme switching: `references/theme-switching.md`
Astro v6 config (Fonts API + CSP): `references/astro-v6-config.md`
Breadcrumb nav + JSON-LD pattern: `references/breadcrumb-pattern.md`
Playwright config template: `templates/playwright.config.js`
Smoke test template: `templates/smoke.spec.js`

## ⚡ Tech Stack

- **Framework:** Astro v6 with strict TypeScript
- **Styling:** Native CSS (no preprocessor). Global tokens in `src/styles/global.css` using `:root`. Component styles use scoped `<style>` tags (no `lang` attribute — plain CSS with native `&` nesting).
- **Content:** `.mdx` files in `src/content/blog/`
- **Testing:** Playwright (`@playwright/test`) — smoke tests in `tests/`
- **Node:** Requires ≥22.12.0 (activate via `nvm use 24` — the default alias on this machine)

## 🏗️ Layout Structure

Pages use a `BaseLayout` component at `src/layouts/BaseLayout.astro`. Blog posts use a separate `BlogPost.astro` layout with its own `<html>/<head>` (does NOT extend BaseLayout).

> **⚠️ Two layout trees:** `BaseLayout.astro` (homepage, top-level pages) and `BlogPost.astro` (blog articles, about page) are independent. Any global `<head>` addition (fonts, CSP meta, JSON-LD, breadcrumbs) must be applied to BOTH.

> **⚠️ Native CSS (no SCSS):** This project uses native CSS (`src/styles/global.css`) — no preprocessor. Design tokens are CSS custom properties in `:root` inside `global.css`. Component `<style>` blocks use plain CSS with native `&` nesting (no `lang="scss"` attribute).

## 🏗️ Project Setup Sequence

1. `npm create astro@latest my-blog -- --template minimal --no-install --no-git --typescript strict`
2. `npm install && npm install --save-dev @playwright/test sass`
3. `npx playwright install chromium`
4. Create `src/styles/global.css` with color tokens inside `:root { ... }` (see token table above)
5. Import `global.css` in the base layout or page frontmatter
6. Build semantic HTML structure: `<header>`, `<nav>`, `<main>`, `<section>`, `<footer>` with ARIA labels
7. Create `playwright.config.js` with dev server config (port 4321)
8. Create `tests/smoke.spec.js` — compile check, semantic landmarks, accessibility

### ⚠️ Pitfalls — Setup

- **Node version:** Astro ≥5.x requires Node ≥22. Activate with `export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" && nvm use 24` before any npm/node command in terminal.
- **`NODE_ENV=production` skips devDependencies:** On macOS, `NODE_ENV` may be set to `production` globally, causing `npm install` to skip all `devDependencies`. Always use `NODE_ENV=development npm install`. Verify with `echo $NODE_ENV`.
- **CSS token import:** In Astro layouts, tokens are available globally via `global.css` which is imported by the layout or page. For page-level scoped styles, use `<style>` (plain CSS, no `lang` attribute). Do NOT reference `tokens.css` or `global.scss` — those files do not exist.
- **Playwright webServer:** Use `npm run dev` (not `preview`) for test server, with `reuseExistingServer: !process.env.CI`.
- **Playwright as devDependency:** Install with `npm install --save-dev @playwright/test` — NOT as a production dependency.
- **Stale dev server on port 4321:** If Playwright's `webServer` times out, kill it: `lsof -ti:4321 | xargs kill -9`, then retry.
- **Vite HMR stale cache:** When scoped `<style>` in `.astro` files is correct on disk but the browser renders old styles, kill the dev server — Vite HMR cache is the cause.
- **Git commit hygiene:** Always write a proper `.gitignore` first, verify with `git status --short`, then use explicit `git add <file>` paths (never `git add .`). If a bad commit was made, `git reset HEAD~1`.

### ⚠️ Pitfalls — Lighthouse CI

- **Install:** `NODE_ENV=development npm install --save-dev @unlighthouse/cli @lhci/cli@0.15.x`
- **Config file:** `lighthouserc.js` at repo root with `startServerCommand: 'npm run preview'`, `url: ['http://localhost:4321/']`, `numberOfRuns: 3`. Strict gates: perf ≥0.95, a11y ≥0.95, SEO ≥1.0, best-practices ≥0.95.
- **package.json scripts:** `"audit": "astro build && npx unlighthouse --site http://localhost:4321"` and `"assert-ci": "astro build && npx lhci autorun"`.

### ⚠️ Pitfalls — Reading Files at Build Time in Astro Frontmatter

- **`process.cwd()` is flagged by ESLint** as undefined in Astro frontmatter. Use `import { fileURLToPath } from 'node:url'` with `new URL('../../relative/path', import.meta.url)` to resolve filesystem paths reliably.
- **Graceful fallback:** When the file doesn't exist (audit not yet run), catch the error and render fallback/default values.

### ⚠️ Pitfalls — Content Schema Mutation

- **Adding required fields:** Every `.md`/`.mdx` in `src/content/blog/` must be updated. Missing any file causes a build error on that post.
- **Adding optional fields with `.default()`:** Existing posts are safe — Zod fills the default at build time.
- **Schema sub-objects (e.g., `auditAssert`):** Group related fields into a `z.object()` with `.default()` for graceful fallback. Use `.min()` for score floors, not `.max()`.
- **After schema changes:** Always run `npm run lint && npm run build` to verify.

### ⚠️ Pitfalls — SCSS → Native CSS Migration

- **SCSS has been retired.** `src/styles/global.scss` was replaced by `src/styles/global.css`. `sass` was uninstalled.
- **Migration procedure (for future reference):**
  1. Write `global.css` converting all SCSS syntax: `$variables` → literal values, `//` comments → `/* */`.
  2. Update ALL imports: `global.scss` → `global.css` in every component.
  3. Change `<style lang="scss">` → `<style>` (plain CSS) in ALL components.
  4. Run `npx biome check --write .` (safe mode only — do NOT use `--unsafe`).
  5. Fix remaining Biome warnings manually — underscore-prefix unused Astro props.
  6. Run `rm src/styles/global.scss` (verify imports are rewired first).
  7. Run `npm uninstall sass`.
  8. Run `NODE_ENV=development npm install` to sync.
  9. Run `npm run build` — verify clean build.

### ⚠️ Pitfalls — Underscore-Prefixed Variable Mismatch in `.astro` Frontmatter

- **The bug pattern:** `const { tag: _Tag } = Astro.props` then referencing `Tag` (bare name) in the template → `ReferenceError`.
- **Fix pattern:** Remove the underscore prefix from the declaration. Do NOT add the underscore to the template references.
- **Prevention:** After any lint autofix pass, search for `grep -rn "const _\w\+\s*=" src/ --include="*.astro"` and verify each `_`-prefixed variable is used with the `_` prefix in the template.

### ⚠️ Pitfalls — Biome Format/Check with Astro Components

- **Biome cannot analyze Astro template variable usage.** False-positive `noUnusedVariables` warnings are expected — ignore them. The build is the source of truth.
- **`npx biome check --write .`** (safe fixes only): Safe to run. Exit code 0 even with warnings.
- **`npx biome check --write --unsafe .`**: **DANGEROUS for Astro projects.** Will add `_` prefixes to variables used in templates, re-introducing `ReferenceError` bugs. **NEVER run `--unsafe` on this codebase.**
- **The `format` script (`"format": "biome check --write ."`):** Safe version without `--unsafe`. Run it freely.

### ⚠️ Pitfalls — Light/Dark Theme Switching

- **Zero-flash inline script:** A `<script is:inline>` block MUST be placed at the very top of `<head>` (in `BaseHead.astro`), BEFORE any `<style>` or `<link>` tags.
- **Semantic CSS variable architecture:** Theme colors under `:root, html[data-theme="dark"]` and `html[data-theme="light"]`.
- **Component decoupling:** `ThemeToggle.astro` (theme only) and `HardwareDashboard.astro` (emulation only) are fully isolated. Scripts must NEVER cross-contaminate.
- **`HardwareSwitch.astro` is DELETED** — superseded by `ThemeToggle.astro` + `HardwareDashboard.astro`.
- **localStorage key mismatch:** `ThemeToggle` uses `'site-theme'` but `BaseHead.astro` zero-flash script uses `'theme-preference'` — out of sync. Unify both to `'site-theme'` in a future pass.

### ⚠️ Pitfalls — Build Errors

- **Relative import path for global styles:** In `src/pages/*.astro` files, use `import "../styles/global.css";` NOT `import "../src/styles/global.css";`. The `src` directory is the root of the source tree; referencing it again in a relative path from `src/pages/` causes a resolution error.
- **Stale build cache:** `rm -rf dist .astro node_modules/.cache` before diagnosing.
- **Missing closing `---` fence:** Every `.astro` frontmatter must have BOTH opening and closing `---`.
- **Accidental import removal during patch:** Include enough context (2-3 lines before/after) in `old_string` to uniquely identify the target.
- **Native CSS is the styling pipeline:** Do NOT reintroduce SCSS/SASS.
- **Astro `<Image />` component:** Always prefer `<Image />` over plain `<img>`. `alt` is always required.
- **Fonts:** Loaded via Google Fonts `<link>` tags in `BaseHead.astro` AND native `fonts` array in `astro.config.mjs`. Both coexist.
- **Content config location (Astro 6):** Must be at `src/content.config.ts`, NOT `src/content/config.ts`.
- **Dynamic route file naming:** `[...id].astro` with `params: { id: post.id }` — not `[...slug].astro`.
- **Content frontmatter must match schema exactly:** Check `src/content.config.ts` before writing frontmatter. Do NOT add fields not in the schema.
- **Content entry `coverImage` path format:** Use public-root paths like `/blog-placeholder-1.jpg`. Place images in `public/`.

### ⚠️ Pitfalls — Accessibility (WCAG 2.1 AA)

- **Skip navigation link is MANDATORY.** Every `<body>` in every layout must include `<a href="#main-content" class="skip-link">Skip to main content</a>` as the FIRST child, and the main content area must have `id="main-content"`. This is a WCAG 2.1 Level A requirement (Success Criterion 2.4.1).
- **Skip-link CSS pattern:** Position offscreen by default (`position: absolute; left: -9999px`), reveal on `:focus` with brand color outline. See `global.css` for the canonical pattern.
- **`target="_blank"` requires `rel="noopener noreferrer"`.** Every external link with `target="_blank"` must include `rel="noopener noreferrer"` — this is both a security best practice and a WCAG 2.1 Level A requirement (Success Criterion 2.4.4). Check both `Header.astro` and `Footer.astro` social link anchors.
- **Social icon links need accessible names.** Icon-only links (Mastodon, Twitter, GitHub) must contain `<span class="sr-only">Platform Name</span>` inside the anchor. `aria-label` on the anchor alone is acceptable but `sr-only` text is more robust.
- **`:focus-visible` must be defined globally.** Keyboard users need a visible focus indicator. Define `:focus-visible` in `global.css` with at least a 2px outline in a high-contrast color (Capcom Blue `#3b82f6`).
- **Heading hierarchy must not skip levels.** The canonical pattern is `h1` (page title) → `h2` (section headings) → `h3` (subsections) → `h4` (card titles). Never jump from `h1` to `h3`.
- **Two layout trees = two a11y audit targets.** `BaseLayout.astro` and `BlogPost.astro` are independent. Skip links, landmarks, and focus indicators must be verified in BOTH.
- **Verify a11y fixes in built output, not just source.** After patching, run `npm run build` then `grep` the `dist/` HTML to confirm skip links, `rel` attributes, and `id="main-content"` are present in the rendered output.

### ⚠️ Pitfalls — Astro v6 Security (CSP) & Fonts API

- **`security: { csp: true }`** in `astro.config.mjs` enables Astro v6's automatic Content Security Policy. At build time, Astro injects `<meta http-equiv="Content-Security-Policy">` tags with SHA-256 hashed `script-src` and `style-src` directives.
- **⚠️ Shiki/CSP incompatibility:** Shiki syntax highlighter applies inline `style` attributes to `<code>` elements, which CSP blocks. Build emits a warning but does not fail. **Solutions:** (1) Switch to Prism (class-based, CSP-safe), (2) add `style-src 'unsafe-inline'` to CSP (weakens security), or (3) accept the warning (current project state — build passes).
- **Native `fonts` array** in `astro.config.mjs`: Use `provider: 'local'` for self-hosted `.woff2` files and `provider: 'fontsource'` for npm-published font packages. Both can coexist with legacy Google Fonts `<link>` tags in `BaseHead.astro`.
- **Fontsource auto-downloads at build time** — no manual `npm install @fontsource/inter` needed.
- **Domain sync triple:** When changing the site domain, update all three: (1) `site:` in `astro.config.mjs`, (2) `SITE_URL` in `src/consts.ts`, (3) `siteRoot` in `BreadcrumbList.astro`. Mismatches cause SEO duplicate-content signals.
- **No `<Font>` component.** The project uses the native `fonts` config block + Google Fonts `<link>` tags. Do NOT reintroduce Astro's experimental `<Font>` component.

Full config schema: `references/astro-v6-config.md`
Breadcrumb nav + JSON-LD pattern: `references/breadcrumb-pattern.md`

## 🔧 Code Quality: ESLint + Prettier

### ESLint Flat Config (`eslint.config.mjs`)

Install dependencies:
```bash
NODE_ENV=development npm install --save-dev eslint eslint-plugin-astro astro-eslint-parser @typescript-eslint/parser eslint-plugin-jsx-a11y prettier eslint-config-prettier typescript-eslint prettier-plugin-astro
```

The flat config uses the `typescript-eslint` meta-package:
```js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import astroPlugin from 'eslint-plugin-astro';
import astroParser from 'astro-eslint-parser';
import jsxA11y from 'eslint-plugin-jsx-a11y';
import prettierConfig from 'eslint-config-prettier';

export default [
  { ignores: ['.astro/', 'dist/', 'node_modules/'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.astro'],
    languageOptions: {
      parser: astroParser,
      parserOptions: { parser: tseslint.parser, extraFileExtensions: ['.astro'], ecmaVersion: 'latest', sourceType: 'module' },
      globals: { URL: 'readonly', URLSearchParams: 'readonly' },
    },
    plugins: { astro: astroPlugin, 'jsx-a11y': jsxA11y },
    rules: { ...astroPlugin.configs.recommended.rules, ...jsxA11y.configs.recommended.rules },
  },
  prettierConfig,
];
```

### Prettier (`.prettierrc`)

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "useTabs": false,
  "printWidth": 100,
  "trailingComma": "all",
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "plugins": ["prettier-plugin-astro"],
  "overrides": [{ "files": "*.astro", "options": { "parser": "astro" } }]
}
```

### package.json Scripts

```json
"lint": "eslint \"src/**/*.{astro,ts,js}\"",
"format": "prettier --write \"src/**/*.{astro,ts,js,css,mdx}\""
```

### ⚠️ Pitfalls — Code Quality

- **`typescript-eslint` meta-package:** Import from `typescript-eslint`, NOT `@typescript-eslint/eslint-plugin`.
- **`prettier-plugin-astro` required:** Without it, Prettier silently ignores `.astro` files.
- **Browser globals in `.astro` files:** Add `URL` and `URLSearchParams` as readonly globals.

## 🧱 Component Architecture: Atoms

### RetroText — Foundational Typography Atom

Location: `src/components/atoms/RetroText.astro`

```astro
---
interface PageProps {
  tag?: 'h1' | 'h2' | 'h3' | 'p' | 'span';
  variant?: 'pixel' | 'mono';
}
const { tag: Element = 'p', variant = 'mono' } = Astro.props as PageProps;
---
<Element class={`retro-text variant-${variant}`}>
  <slot />
</Element>
```

- `variant="pixel"` → `var(--font-family-display)` (Syncopate 700)
- `variant="mono"` → `var(--font-family-body)` (Inter)

### ⚠️ Pitfalls — Font Loading

- **Google Fonts payload must be in BOTH `BaseHead.astro` and `SEOHead.astro`.** Both layout trees need identical `<link>` preconnect + stylesheet tags.
- **No `<Font>` component or `@fontsource/` packages.** The project uses native `fonts` config + Google Fonts `<link>` tags.
- **Inter provides the reading experience; Syncopate is display-only.**

### ⚠️ Pitfalls — Global Stylesheet Import Consistency

- **Every `<head>` component MUST import `global.css`.** If any head component doesn't import it, that page renders without CSS custom properties.
- **Diagnostic:** In browser console, `getComputedStyle(document.documentElement).getPropertyValue('--color-sys-bg')` — empty string means `global.css` is not loaded.

### ⚠️ Pitfalls — Font Stack Migration (Scoped Override Bug)

- **Scoped `<style>` blocks with hardcoded `font-family` strings override `:root` CSS custom property tokens.** Every `font-family` in every component `<style>` block MUST use a `var(--font-family-*)` token — never a raw font name string.
- **After any font migration:** `grep -r "font-family" src/components/ --include="*.astro" | grep -v "var(--font-family"` — zero results is the only acceptable outcome.

### ⚠️ Pitfalls — Migrating Scoped Styles from Legacy Light Tokens to Dark NES

- **Legacy token patterns to replace:** `rgb(var(--gray-dark))`, `rgb(var(--gray))`, `rgb(var(--black))`, `rgb(var(--accent))`, `var(--box-shadow)`, `border-radius: 12px`.
- **Replace with:** `var(--color-sys-text)`, `var(--color-brand-primary)`, `var(--color-brand-accent)`, `var(--size-border-pixel)` borders.

### ⚠️ Pitfalls — Header & Navigation Dark Theme

- **Header must NEVER use light-theme defaults.** Replace `background: white`, `box-shadow`, `var(--black)` with NES dark tokens.
- **HeaderLink.astro active state:** `text-decoration-color: var(--color-brand-danger)` (Konami Red).

### ⚠️ Pitfalls — Components

- **⚠️ Do NOT name interfaces `Props` in `.astro` files:** Astro uses `Props` as a built-in global. Use descriptive names like `PageProps`.
- **Atomic design directory structure:** `atoms/`, `molecules/`, `organisms/`, flat `components/`, `layouts/`.
- **Vite version pinning:** `"overrides": { "vite": "^7.0.0" }` in `package.json`.
- **Native CSS Nesting (`&`)** is supported in Astro scoped `<style>` blocks. Do NOT nest more than 2 levels deep.

## 🔎 JSON-LD Structured Data (SchemaGraph + BreadcrumbList)

### SchemaGraph Component

`src/components/SEO/SchemaGraph.astro` — renders `<script type="application/ld+json">` via `set:html={JSON.stringify(graphData)}`.

### BreadcrumbList Component

`src/components/SEO/BreadcrumbList.astro` — generates Schema.org `BreadcrumbList` JSON-LD from `Astro.url.pathname`. Composable alongside `SchemaGraph`.

### Mounting Pattern

**Both** `SchemaGraph` and `BreadcrumbList` must be mounted in **every layout that renders a `<head>`**:

- **`BaseLayout.astro`** — homepage and top-level pages
- **`BlogPost.astro`** — blog articles + about page

```astro
---
import SchemaGraph from '../components/SEO/SchemaGraph.astro';
import BreadcrumbList from '../components/SEO/BreadcrumbList.astro';
---
<head>
  <SchemaGraph {...props} />
  <BreadcrumbList />
</head>
```

### Visible Breadcrumb Nav

`src/components/Breadcrumb.astro` — renders `<nav aria-label="breadcrumb">` from `Astro.url.pathname`. Mount in `<body>` after `<Header />` in both layouts.

### ⚠️ Pitfalls — JSON-LD / SchemaGraph / BreadcrumbList

- **"Mount once in one layout" is WRONG.** Both layout trees must independently mount all JSON-LD components.
- **`Astro.site` defaults to `example.com` in dev.** Set `site:` in `astro.config.mjs` for production.
- **Domain consolidation is a three-file operation:** `astro.config.mjs` (`site:`), `src/consts.ts` (`SITE_URL`), `BreadcrumbList.astro` (`siteRoot`).
- **No `schema-dts` or `@unhead/schema` packages.** Pure `JSON.stringify()` via Astro's `set:html`.
- **BreadcrumbList `siteRoot` is hardcoded** — change `https://ericcarlisle.com` if the domain changes.

Full references: `references/json-ld-schema-graph.md`, `references/breadcrumb-pattern.md`

## 📰 Content Collection Pipeline

### Pattern: Timeline Feed (`src/pages/index.astro`)

```astro
---
import { getCollection } from 'astro:content';
const allPosts = await getCollection('blog');
const sortedPosts = allPosts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
---
```

### ⚠️ Pitfalls — Content Collection Pipeline

- **Always sort explicitly.** `getCollection` returns records in filesystem order.
- **Handle the empty state.** Render a styled placeholder when no posts exist.
- **Use `post.id` (not `post.slug`)** for link paths. In Astro 6 with `glob` loaders, `slug` is `undefined`.
- **`transition: steps(2)`** for arcade hover — zero JS, pure CSS retro feel.

## 🎨 Native CSS Nesting in Astro Scoped Styles

Astro's `<style>` blocks support native CSS Nesting (`&` selector). Use `&` nesting for pseudo-classes, child elements, and media queries. Do NOT nest more than 2 levels deep.

## 🔍 Fallow Code Quality Auditing

```bash
npx fallow --no-cache        # Full analysis
npx fallow health --no-cache # Health-only
```

**Exit code 1 is normal** when fallow finds issues. Known false positives: `lighthouserc.js` as "dead file", `@unlighthouse/cli` as "unused dependency".

### ⚠️ Pitfalls — Dependency Hygiene

- **`sharp` belongs in `devDependencies`.**
- **`@eslint/js` must be explicitly in `devDependencies`.**
- **Remove `@typescript-eslint/eslint-plugin` and `@typescript-eslint/parser`** when using `typescript-eslint` umbrella.

## 🗂️ Information Architecture

| Route | Purpose |
|-------|---------|
| `index.astro` | Splash page, post timeline |
| `/about` | Resume, stack overview |
| `/portfolio` | Project showcase |
| `/tags/` & `/categories/` | Content taxonomies |

## 🧪 Testing

Playwright smoke test assertions:
1. Page compiles (HTTP 200)
2. Hero heading renders
3. Semantic landmarks present (header, main, footer, nav)
4. `aria-labelledby` links section to heading
5. `<html lang="en">` set

Run: `npx playwright test`

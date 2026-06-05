# Astro v6 Configuration: Fonts API + CSP

## Native `fonts` Array (astro.config.mjs)

Astro v6 introduces a root-level `fonts` array for font declarations. The project uses both local and Fontsource providers alongside the legacy Google Fonts `<link>` tags in `BaseHead.astro` (the `<link>` tags remain as fallback for older browsers and to satisfy the existing CSS custom property wiring).

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import fs from 'node:fs';

// Scan local font directory for Atkinson files
const atkinsonDir = './public/fonts/atkinson/';
const atkinsonFiles = fs.readdirSync(atkinsonDir);
const atkinsonFaces = atkinsonFiles
  .filter(f => f.endsWith('.woff2'))
  .map(f => {
    const match = f.match(/Atkinson-Hyperlegible-(Regular|Bold)(Italic)?-\d+\.woff2/);
    if (!match) return null;
    const weight = match[1] === 'Bold' ? 700 : 400;
    const style = match[2] ? 'italic' : 'normal';
    return {
      src: [{ url: `/fonts/atkinson/${f}`, format: 'woff2' }],
      weight,
      style,
      display: 'swap',
    };
  })
  .filter(Boolean);

export default defineConfig({
  site: 'https://ericcarlisle.com',
  integrations: [/* ... */],
  vite: {
    css: { transformer: 'lightningcss' },
  },
  fonts: [
    // Local fonts (zero network requests)
    ...atkinsonFaces.map(face => ({
      provider: 'local',
      name: 'Atkinson Hyperlegible',
      cssVariable: '--font-atkinson',
      fallbacks: ['Inter', 'sans-serif'],
      face,
    })),
    // Fontsource hosted fonts (auto-downloaded at build time)
    {
      provider: 'fontsource',
      name: 'Inter',
      cssVariable: '--font-family-body',
      fallbacks: ['sans-serif'],
      weights: [400, 500, 700],
      styles: ['normal'],
      subsets: ['latin'],
    },
    {
      provider: 'fontsource',
      name: 'Fira Code',
      cssVariable: '--font-family-mono',
      fallbacks: ['monospace'],
      weights: [400, 600],
      styles: ['normal'],
      subsets: ['latin'],
    },
  ],
  // ...
});
```

### Provider Types

| Provider | Use Case | Notes |
|----------|----------|-------|
| `local` | Self-hosted `.woff2` files in `public/` | Zero network requests; scan filesystem at config time |
| `fontsource` | npm-published font packages | Auto-downloaded at build time; specify weights/styles/subsets |
| `google` | Google Fonts (built-in) | Not used in this project (manual `<link>` tags instead) |

> **⚠️ IMPORTANT:** The project ALSO loads Inter, Fira Code, and Syncopate via Google Fonts `<link>` tags in `BaseHead.astro`. The native `fonts` API and the `<link>` tags coexist. The CSS custom properties (`--font-family-body`, `--font-family-mono`) are wired from both sources.

---

## `security.csp` — Automated Content Security Policy

Astro v6 adds a root-level `security` config block. Setting `csp: true` enables automatic CSP header generation at build time.

```js
// astro.config.mjs
export default defineConfig({
  site: 'https://ericcarlisle.com',
  integrations: [/* ... */],
  security: {
    csp: true,
  },
});
```

### What Happens at Build Time

- Astro injects a `<meta http-equiv="Content-Security-Policy">` tag into every HTML page
- Inline `<script>` and `<style>` blocks are hashed (SHA-256) and added to the policy
- External resources must be explicitly allowed (or already covered by `'self'`)

### ⚠️ Pitfall: Shiki Syntax Highlighter Incompatibility

**Shiki applies inline `style` attributes to syntax-highlighted `<code>` elements.** These inline styles are blocked by the auto-generated CSP when `csp: true`.

**Symptom:** Build succeeds but emits a warning:
```
[WARN] Shiki syntax highlighting uses inline styles incompatible with CSP.
```

**Solutions (pick one):**
1. Switch to **Prism** syntax highlighting (class-based, no inline styles)
2. Adjust CSP config to permit `style-src 'unsafe-inline'` (weakens security)
3. **Current project state:** Shiki warning is accepted; build passes. CSP is active.

### Other `security` Options (Astro v6)

```js
security: {
  csp: true,           // auto-generate CSP meta tags
  // Future: csrf, headers, etc.
}
```

---

## Quick Reference: Full Config Shape

```js
import { defineConfig } from 'astro/config';
import fs from 'node:fs';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';

// Build local font faces from filesystem
const fontDir = './public/fonts/atkinson/';
const fontFaces = fs.existsSync(fontDir)
  ? fs.readdirSync(fontDir)
      .filter(f => f.endsWith('.woff2'))
      .map(f => {
        const match = f.match(/Atkinson-Hyperlegible-(Regular|Bold)(Italic)?-\d+\.woff2/);
        if (!match) return null;
        return {
          src: [{ url: `/fonts/atkinson/${f}`, format: 'woff2' }],
          weight: match[1] === 'Bold' ? 700 : 400,
          style: match[2] ? 'italic' : 'normal',
          display: 'swap',
        };
      })
      .filter(Boolean)
  : [];

export default defineConfig({
  site: 'https://ericcarlisle.com',
  output: 'static',
  integrations: [sitemap(), mdx()],
  vite: { css: { transformer: 'lightningcss' } },
  fonts: [
    ...fontFaces.map(face => ({
      provider: 'local',
      name: 'Atkinson Hyperlegible',
      cssVariable: '--font-atkinson',
      fallbacks: ['Inter', 'sans-serif'],
      face,
    })),
    { provider: 'fontsource', name: 'Inter', cssVariable: '--font-family-body', fallbacks: ['sans-serif'], weights: [400, 500, 700], styles: ['normal'], subsets: ['latin'] },
    { provider: 'fontsource', name: 'Fira Code', cssVariable: '--font-family-mono', fallbacks: ['monospace'], weights: [400, 600], styles: ['normal'], subsets: ['latin'] },
  ],
  security: { csp: true },
});
```

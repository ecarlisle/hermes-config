# Astro 6 Build Error Catalog

Error signatures and fixes from debugging sessions.

---

## 1. `Could not import '../styles/global.css'`

**Cause:** Import references `.css` but file uses `.scss`.

**Fix:** Change import from `../styles/global.css` → `../styles/global.scss`.

---

## 2. SCSS `lighten()` / `darken()` not recognized

**Cause:** Sass removed legacy color functions in the modern spec.

**Fix:** Replace with pre-computed hex values. Do NOT use `color.adjust()` or `color.scale()` — not supported in Dart Sass embedded.

---

## 3. `<Image>` with string paths for `public/` folder images

**Cause:** Astro's `<Image />` component requires `width` and `height` for images in `public/` (it cannot analyze those files to infer dimensions).

**Fix:** Always provide explicit `width` and `height` props when using `src` strings pointing to `public/`:
```astro
<Image src="/photo.jpg" alt="Description" width="800" height="600" />
```
For local images in `src/assets/`, import the file and pass the import — dimensions are auto-inferred:
```astro
import { Image } from 'astro:assets';
import myImage from '../assets/photo.png';
<Image src={myImage} alt="Description" />
```
**Do NOT fall back to plain `<img>` tags** — `<Image />` provides lazy loading, WebP conversion, and proper `decoding` attributes automatically.

---

## 4. Content config in wrong location

**Full error:** `LegacyContentConfigError: Found legacy content config in "src/content/config.ts"`

**Cause:** Astro 6 expects config at `src/content.config.ts`, NOT `src/content/config.ts`.

**Fix:** Delete `src/content/config.ts`, ensure `src/content.config.ts` has a `glob` loader. Run `ls src/content*config*` to check for stale files.

---

## 5. Stale build cache

**Fix:** `rm -rf dist .astro node_modules/.cache && npm run build`

---

## 6. Vite HMR stale cache — styles correct on disk but wrong in browser

**Symptom:** Component `<style>` block on disk uses correct CSS custom properties (e.g., `var(--color-sys-bg)`), built `dist/index.html` output confirms the rules are present, but browser DevTools show old/different computed styles (e.g., `background: white; border-bottom: 0px`).

**Cause:** Vite HMR dev server is serving a cached version of the stylesheet. Astro's scoped style hashes can become stale in the running process.

**Diagnosis steps:**
1. Verify file on disk matches expected styles: `cat src/components/Component.astro`
2. Check browser console expression: `getComputedStyle(document.querySelector('header')).background` — if it's wrong despite correct disk, HMR cache is the cause
3. Kill the dev server: `lsof -ti:4321 | xargs kill -9` (or `pkill -f "astro dev"`)
4. Restart dev server and verify styles are correct

**Fix:** Kill the dev server. Do NOT chase CSS specificity issues when the file on disk is already correct — the problem is the running process, not the stylesheet.

---

## Quick Diagnostic Checklist

1. `rm -rf dist .astro node_modules/.cache`
2. `grep -rn "\.css" src/`
3. `grep -rn "lighten\|darken\|mix(" src/styles/`
4. `ls src/content*config*` — should only be `src/content.config.ts`
5. Check `content.config.ts` schema — `image()` vs `z.string()`
6. If styles are correct on disk but wrong in browser → kill dev server (HMR stale cache)

---

## 7. `ReferenceError: <Name> is not defined` in prerender chunks (underscore-prefix mismatch)

**Symptom:** Build output shows `ReferenceError: Tag is not defined` (or `scores`, `title`, `canonicalURL`, `metrics`, `combinedClass`, etc.) at runtime in prerender chunks. Stack trace points to `AstroComponentInstance.<ComponentName> [as factory]`.

**Cause:** Variable declared with underscore prefix in frontmatter but referenced *without* the prefix in the template:
```astro
---
// ❌ WRONG — _Tag declared, Tag used
const { tag: _Tag, variant } = Astro.props;
const _scores = { ... };
const _combinedClass = '...';
---
<Tag class={combinedClass}>     <!-- ReferenceError: Tag is not defined -->
  <slot />
</Tag>
```

This is commonly introduced by lint autofix passes that rename "unused" variables to `_var` without updating template references.

**Fix:** Remove the underscore prefix from declarations so they match template usage:
```astro
---
// ✅ CORRECT — names match
const { tag: Tag, variant } = Astro.props;
const scores = { ... };
const combinedClass = '...';
---
```

**Prevention search:** After any lint autofix pass, run:
```bash
grep -rn "const _\w\+\s*=" src/ --include="*.astro"
```
Verify each `_`-prefixed variable is actually used with the `_` prefix in the template. If the template uses the bare name, the declaration must match.

**Files affected in 2026-06-04 session (all fixed):** `RetroText.astro`, `BlogPost.astro`, `SEOHead.astro`, `PostAuditBanner.astro`, `GlobalScoreboard.astro`, `HeaderLink.astro`, `Footer.astro`, `FormattedDate.astro`, `blog/index.astro`, `[...id].astro`

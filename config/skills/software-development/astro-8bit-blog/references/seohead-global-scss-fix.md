# SEOHead Missing global.scss Import — Diagnostic Path

## Date
2026-06-03

## Symptom
About page (`/about/`) and all blog article pages (`/blog/[slug]/`) rendered with light/transparent theme — white backgrounds, black text, missing pixel borders. Homepage and blog listing page (`/blog/`) rendered correctly in dark NES theme.

## Root Cause
`BlogPost.astro` uses `SEOHead.astro` for `<head>` metadata. `SEOHead.astro` is a pure meta-tag component (OG tags, Twitter cards, canonical URL) that did NOT import `../styles/global.scss`. Without this import, the `:root` CSS custom properties (`--color-sys-bg`, `--color-sys-text`, etc.) and global body styles were never loaded on these pages. Scoped component styles referencing these variables collapsed to CSS defaults (transparent background, black text).

Meanwhile, `blog/index.astro` used `BaseHead.astro` directly, which DOES import `global.scss` — so the blog listing page was fine.

## Diagnostic Steps
1. Browser console: `getComputedStyle(document.querySelector('main')).backgroundColor` returned `rgba(0,0,0,0)` — transparent, not dark.
2. Browser console: `getComputedStyle(document.documentElement).getPropertyValue('--color-sys-bg')` returned empty string — CSS custom property not defined.
3. Compared `SEOHead.astro` vs `BaseHead.astro`: `BaseHead` has `import '../styles/global.scss'`, `SEOHead` does not.
4. Traced page hierarchy: `about.astro` → `BlogPost.astro` → `SEOHead.astro` (missing import).

## Fix
```diff
 // SEOHead.astro
+import '../styles/global.scss';
+
 interface Props {
```

## Secondary Fix — Legacy Token Migration
`BlogPost.astro` and `blog/index.astro` scoped styles used legacy light-theme tokens (`rgb(var(--gray-dark))`, `rgb(var(--gray))`, `border-radius: 12px`, `box-shadow: var(--box-shadow)`). These were migrated to dark NES tokens per the migration map in the SKILL.md pitfalls section.

## Verification
After fix, all pages confirmed:
- `header` background: `rgb(9, 9, 11)` ✓
- `main` background: `rgb(9, 9, 11)` ✓
- Text color: `rgb(228, 228, 231)` ✓
- Date/meta color: `rgb(161, 161, 170)` ✓

## Lesson
**Always verify that EVERY `<head>` component in an Astro project imports the global stylesheet.** A page that compiles and renders HTML but shows broken styles may have a missing stylesheet import, not a CSS specificity issue. Check the import chain before chasing specificity.

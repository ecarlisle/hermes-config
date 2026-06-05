# SCSS → Native CSS Migration Reference

## Summary

The blog project migrated from SCSS to native CSS in this session. All SCSS-specific syntax was removed, `$variables` replaced with literal hex values, and the `sass` package was uninstalled.

## File Changes

| Before | After | Action |
|--------|-------|--------|
| `src/styles/global.scss` (12,405 chars) | Deleted | Removed after migration |
| `src/styles/global.css` (new) | Native CSS replacement | Created from SCSS source |
| `<style lang="scss">` in 4+ components | `<style>` (plain CSS) | `lang` attribute removed |
| `import '../styles/global.scss'` in head components | `import '../styles/global.css'` | Import rewired |
| `"sass": "^1.100.0"` in `package.json` | Removed | `npm uninstall sass` |

## SCSS → CSS Conversion Rules

1. **`$variables` → literal hex**: `$nes-bg: #09090b` → just use `#09090b` directly in `:root`
2. **`rgba($var, alpha)` → literal rgba**: `rgba($nes-surface, 0.5)` → `rgba(26, 26, 36, 0.5)`
3. **`//` comments → `/* */`**: Native CSS doesn't support `//`
4. **`#{}` interpolation → literal**: `#{$nes-bg}` → `#09090b`
5. **`&` nesting → preserved**: Native CSS supports `&` nesting in all modern browsers
6. **`darken()`/`lighten()`/`color.adjust()` → pre-computed hex**: Not available without SCSS

## Biome Post-Migration Fixes

Run after SCSS→CSS migration:
```bash
npx biome check --write --unsafe .
```

This auto-fixes safe issues but leaves warnings for:
- **Unused variables in Astro frontmatter**: Underscore-prefix them (`_pubDate`, `_tags`, `_date`, `_props`, `_Content`, `_coverAlt`, `_Tag`, etc.)
- **`!important` on utility classes**: Remove from `.sr-only`, `.no-js-emsembly` — specificity is sufficient

## Verification Steps

1. `npm run build` — must exit 0
2. `npx playwright test` — smoke tests pass
3. Browser: `getComputedStyle(document.documentElement).getPropertyValue('--color-sys-bg')` returns `#09090b` (not empty)
4. Browser: h1 uses Syncopate, body uses Inter, code uses Fira Code
5. `grep -r "font-family" src/components/ --include="*.astro" | grep -v "var(--font-family"` — zero results
6. `grep -r "lang=\"scss\"" src/ --include="*.astro"` — zero results

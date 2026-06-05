# 8-Bit NES Design Token Reference

Full variable map from `src/styles/global.scss`.

## Architecture: SCSS Vars → CSS Custom Properties

The project uses **SCSS variables** (`$nes-*`) as the source-of-truth palette, then exposes them as **CSS custom properties** (`--color-*`, `--size-*`, `--font-*`) via a `:root` block. Components consume the CSS custom properties in their `<style>` blocks.

Some components also use **semantic alias tokens** (`--color-sys-*`, `--font-family-display`) that map to the base custom properties for a clean abstraction boundary.

## SCSS Source Variables (`src/styles/global.scss`)

### Backgrounds & Surfaces
| SCSS Variable | Hex / Value | Role |
|---------------|-------------|------|
| `$nes-bg` | `#09090b` | Deep arcade CRT background |
| `$nes-surface` | oklch-derived | Elevated surface (cards, panels) |
| `$nes-surface-raised` | oklch-derived | Highest lift (modals, dropdowns) |

### Text Hierarchy
| SCSS Variable | Hex / Value | Role |
|---------------|-------------|------|
| `$nes-text` | `#e4e4e7` | High-contrast reading text |
| `$nes-text-dim` | `#a1a1aa` | Muted gray — nav links, captions |

### 8-Bit Brand Accents
| SCSS Variable | Hex / Value | Role |
|---------------|-------------|------|
| `$nes-capcom-blue` | `#3b82f6` | Capcom Blue — hover, highlights |
| `$nes-konami-red` | `#ef4444` | Konami Red — active states, alerts |
| `$nes-nintendo-gold` | `#eab308` | Gold — select/focus states |

### Borders
| SCSS Variable | Hex / Value | Role |
|---------------|-------------|------|
| `$nes-border` | oklch-derived | Standard borders |

### Typography (SCSS)
| SCSS Variable | Stack | Role |
|---------------|-------|------|
| `$font-pixel` | `'Syncopate', sans-serif` | All-caps display headers, UI labels, nav |
| `$font-body` | `'Inter', sans-serif` | Reading prose, body text |
| `$font-mono` | `'Fira Code', monospace` | Code blocks, technical content |

## CSS Custom Properties (`:root` block)

### Base Tokens
| CSS Custom Property | Maps To | Purpose |
|---------------------|---------|---------|
| `--color-bg` | `#{$nes-bg}` | Base canvas |
| `--color-surface` | `#{$nes-surface}` | Elevated surface |
| `--color-surface-raised` | `#{$nes-surface-raised}` | Highest lift |
| `--color-text` | `#{$nes-text}` | Reading text |
| `--color-border` | `#{$nes-border}` | Borders |
| `--color-brand-primary` | `#{$nes-text-dim}` | Nav links, secondary interactive |
| `--color-brand-accent` | `#{$nes-capcom-blue}` | Capcom Blue — hover, highlights |
| `--color-brand-danger` | `#{$nes-konami-red}` | Konami Red — active, alerts |
| `--color-brand-gold` | `#{$nes-nintendo-gold}` | Gold accents |
| `--size-border-pixel` | `2px` | Chunky pixel-stepped borders |

### Semantic Alias Tokens (for component use)
| CSS Custom Property | Maps To | Purpose |
|---------------------|---------|---------|
| `--color-sys-bg` | `var(--color-bg)` | Component-level background |
| `--color-sys-text` | `var(--color-text)` | Component-level text |
| `--color-sys-surface` | `var(--color-surface)` | Component-level surface |
| `--font-family-display` | `#{$font-pixel}` | Syncopate — all-caps display headers/nav/UI |
| `--font-family-body` | `#{$font-body}` | Inter — reading prose, body text |
| `--font-family-mono` | `#{$font-mono}` | Fira Code — code blocks, technical content |
| `--font-atkinson` | `var(--font-family-body)` | Legacy bridge alias — do NOT use for new work |

> **Usage rule:** Component `<style>` blocks should use the semantic aliases (`--color-sys-*`, `--font-family-display`) rather than the raw `--color-*` forms. This maintains a clean abstraction boundary and makes future theme changes trivial.

## Google Font Loading

Fonts are loaded via preconnected `<link>` tags (zero-runtime, no `<Font>` component, no font loader JS). Must be present in **both** `BaseHead.astro` and `SEOHead.astro`:

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Syncopate:wght@700&family=Inter:wght@400;500;700&family=Fira+Code:wght@400;600&display=swap" rel="stylesheet" />
```

### Typography Rules in `global.scss`

- **Body:** Inter, 16px, line-height 1.625, letter-spacing -0.011em
- **Headings (h1–h6):** Syncopate 700, uppercase, letter-spacing 0.06em
- **Code/pre:** Fira Code via `var(--font-family-mono)`

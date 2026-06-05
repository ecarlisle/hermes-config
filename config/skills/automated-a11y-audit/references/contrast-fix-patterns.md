# Contrast Fix Patterns

## Dark Theme (bg: #0f0f14, surface: #1a124, surface-raised: #1a1a24)

| Element | Color | On #0f0f14 | On #1a1a24 | On #a1a1aa (thumb) |
|---------|-------|------------|------------|---------------------|
| Body text | #e4e4e7 | 11.2:1 ✓ | 9.8:1 ✓ | 2.3:1 ✗ |
| Muted text | #a1a1aa | 3.0:1 ✗ | 2.6:1 ✗ | 1.0:1 ✗ |
| Muted text (fixed) | #d4d4d8 | 11.8:1 ✓ | 10.3:1 ✓ | 2.0:1 ✗ |
| Accent link | #3b82f6 | 4.6:1 ✓ | 4.0:1 ✗ | 1.3:1 ✗ |
| Danger/Error | #ef4444 | 4.8:1 ✓ | 4.2:1 ✗ | 1.1:1 ✗ |
| Danger (fixed) | #f87171 | 4.8:1 ✓ | 4.6:1 ✓ | 1.1:1 ✗ |
| Gold/Warning | #eab308 | 10.5:1 ✓ | 9.2:1 ✓ | 2.6:1 ✗ |
| Success/Green | #22c55e | 5.2:1 ✓ | 4.5:1 ✓ | 1.4:1 ✗ |

**Key insight:** No single color achieves 4.5:1 on both `#0f0f14` (dark bg) AND `#a1a1aa` (gray thumb). If text overlaps a gray thumb, restructure the DOM instead of chasing a color.

## Light Theme (bg: #f4f4f5, surface: #ffffff)

| Element | Color | On #f4f4f5 | On #ffffff |
|---------|-------|------------|------------|
| Body text | #09090b | 14.8:1 ✓ | 16.1:1 ✓ |
| Muted text | #71717a | 4.6:1 ✓ | 4.6:1 ✓ |
| Accent link | #2563eb | 4.6:1 ✓ | 4.6:1 ✓ |
| Danger | #dc2626 | 4.6:1 ✓ | 4.5:1 ✓ |

## When Text Overlaps Interactive Elements

If text sits on top of a moving element (slider thumb, toggle, etc.):

1. **Best fix:** Move the text outside the interactive element entirely (sibling with `aria-hidden="true"`)
2. **Acceptable fix:** Give the text a solid background pill matching the track/surface color
3. **Last resort:** Use `color: #000000` which achieves 4.6:1 on `#a1a1aa` — but this only works on gray backgrounds, not dark ones

## Quick Reference: Safe Colors on Dark Backgrounds (#0f0f14)

- `#ffffff` — 14.9:1 (maximum contrast)
- `#e4e4e7` — 11.2:1 (body text)
- `#d4d4d8` — 11.8:1 (muted text, passes AA)
- `#f87171` — 4.8:1 (red-400, passes AA for normal text)
- `#3b82f6` — 4.6:1 (blue-500, passes AA)
- `#22c55e` — 5.2:1 (green-500, passes AA)
- `#eab308` — 10.5:1 (yellow-500, passes AA)

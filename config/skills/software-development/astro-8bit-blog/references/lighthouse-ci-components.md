# Lighthouse CI Component Patterns — Astro Blog

## GlobalScoreboard.astro

Reads `.unlighthouse/ci-result.json` at build time and renders a site-wide NES card showing 4 Lighthouse metrics.

### Props

None — reads data from filesystem at build time.

### File Resolution Pattern

```astro
---
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

let scores = { perf: 100, a11y: 100, seo: 100, bestPractices: 100 };
let ciFound = false;

try {
  const ciPath = fileURLToPath(new URL('../../.unlighthouse/ci-result.json', import.meta.url));
  const raw = readFileSync(ciPath, 'utf-8');
  const data = JSON.parse(raw);
  scores = { ...scores, ...data.categories };
  ciFound = true;
} catch {
  // Audit not yet run — render defaults
}
---
```

### Rendering

- 4 metric rows: Performance, Accessibility, SEO, Best Practices
- NES dark-mode card with chunky 2px retro borders
- When `ciFound === false`, show hint: "Run `npm run audit` to generate scores"
- Each score displayed as integer (multiply raw score × 100)

### Integration

Place in `src/pages/index.astro` directly below `<h1>` and before the first `<p>`:

```astro
---
import GlobalScoreboard from '../components/GlobalScoreboard.astro';
---
<h1>8-Bit Blog</h1>
<GlobalScoreboard />
<p>Welcome to the official...</p>
```

---

## PostAuditBanner.astro

Renders per-post audit scores from frontmatter `auditAssert` field, displayed as horizontal metric rows under the post title.

### Props

```ts
interface Props {
  perf: number;
  a11y: number;
  seo: number;
  bestPractices: number;
}
```

### Rendering

- Horizontal rows for each metric with label + score
- Gold `[PERFECT SCORE]` tag (Press Start 2P font) appended to any category scoring exactly 100
- Styled with NES dark-mode tokens (borders, retro colors)

### Integration

In `src/layouts/BlogPost.astro`, render conditionally below `<h1>{title}</h1>`:

```astro
---
import PostAuditBanner from '../components/PostAuditBanner.astro';
interface Props {
  title: string;
  // ... other fields
  auditAssert?: { perf: number; a11y: number; seo: number; bestPractices: number };
}
const { auditAssert } = Astro.props;
---
<h1>{title}</h1>
{auditAssert && <PostAuditBanner {...auditAssert} />}
```

The conditional render `{auditAssert && ...}` ensures graceful handling if the field is absent.

---

## Build-Time File Reading — Rules

1. **Never use `process.cwd()`** in Astro frontmatter — ESLint flags it as undefined
2. **Always use `fileURLToPath(new URL(relativePath, import.meta.url))`** for path resolution
3. **Always wrap `readFileSync` in try/catch** — the CI result file won't exist until `npm run audit` is run
4. **Default values should be optimistic** (all 100s) so the UI looks good before first audit run

# Content Schema Patterns — Astro Blog

## Current Schema (as of 2026-06-02)

File: `src/content.config.ts`

```ts
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro:schema';

const blog = defineCollection({
  loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    title: z.string().max(60),
    description: z.string().max(160),
    pubDate: z.coerce.date(),
    coverImage: z.string(),
    coverAlt: z.string(),
    ogTitle: z.string().optional(),
    ogDescription: z.string().optional(),
    auditAssert: z.object({
      perf: z.number().min(90),
      a11y: z.number().min(90),
      seo: z.number().min(90),
      bestPractices: z.number().min(90),
    }).default({ perf: 100, a11y: 100, seo: 100, bestPractices: 100 }),
  }),
});

export const collections = { blog };
```

## Pattern: Adding a Typed Sub-Object with Defaults

When adding a structured sub-object to a Zod content schema:

1. **Use `.default()`** so existing content files without the field get sensible defaults — avoids build errors on posts that haven't been updated yet.
2. **Use `.min()` not `.max()` for score floors** — rejects values below threshold at build time without capping high performers.
3. **Group related fields into a sub-object** rather than flattening — keeps frontmatter readable and the schema extensible.
4. **After schema change**: Astro's content store auto-invalidates and resyncs. This is expected — not an error.

### Example: Adding `auditAssert`

```ts
auditAssert: z.object({
  perf: z.number().min(90),
  a11y: z.number().min(90),
  seo: z.number().min(90),
  bestPractices: z.number().min(90),
}).default({ perf: 100, a11y: 100, seo: 100, bestPractices: 100 }),
```

- Posts without `auditAssert` in frontmatter get perfect scores by default.
- Posts with scores below 90 fail at build time (Zod validation error).
- The sub-object can be extended later (e.g., adding `pwa: z.number().min(90)`).

## Schema Evolution Checklist

When modifying the content schema:

1. Update `src/content.config.ts`
2. Update any layout components that consume the new fields
3. Update all content files (`.md`/`.mdx`) in `src/content/blog/` if the field is required
4. If optional with `.default()`, existing posts are safe — but add the field for documentation
5. Run `npm run lint` — must pass
6. Run `npm run build` — content store will resync; verify all posts load
7. Run `npm run format` — ensure consistent formatting

## Field Naming Conventions

- `coverImage` / `coverAlt` — NOT `heroImage`/`heroAlt` (renamed for clarity)
- `ogTitle` / `ogDescription` — optional OG overrides, fall back to `title`/`description`
- `pubDate` — use `z.coerce.date()` for flexible date parsing
- `auditAssert` — sub-object for Lighthouse CI score thresholds

## Fields NOT in the Schema (common mistakes)

The following fields are frequently assumed but NOT defined in the current schema. Including them in frontmatter causes `InvalidContentEntryDataError`:

- `tags` — not a schema field. Do NOT add `tags: [...]` to frontmatter.
- `category` — not a schema field. Do NOT add `category: "..."` to frontmatter.
- `heroImage` / `heroAlt` — renamed to `coverImage` / `coverAlt`. Old names will fail validation.

**Before writing a new content entry:** Read the schema in `src/content.config.ts` and use only the fields defined there. If you need a new field, add it to the schema first, then update all existing content files if it's required.

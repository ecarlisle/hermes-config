# SEO & Social Metadata — Astro Blog Pattern

## SEOHead Component

A dedicated `<SEOHead>` component replaces the default `<BaseHead>` in blog layouts. It outputs canonical URLs, Open Graph tags, and Twitter Card tags with cascading fallback logic.

### Component: `src/components/SEOHead.astro`

```astro
---
interface Props {
  title: string;
  description: string;
  coverImage: string;
  coverAlt: string;
  ogTitle?: string;
  ogDescription?: string;
}

const {
  title,
  description,
  coverImage,
  coverAlt,
  ogTitle,
  ogDescription,
} = props;

const resolvedOgTitle = ogTitle || title;
const resolvedOgDescription = ogDescription || description;
const ogImageUrl = new URL(coverImage, Astro.url.origin).toString();
---

<link rel="canonical" href={Astro.url} />
<title>{title}</title>
<meta name="description" content={description} />
<meta property="og:title" content={resolvedOgTitle} />
<meta property="og:description" content={resolvedOgDescription} />
<meta property="og:image" content={ogImageUrl} />
<meta property="og:image:alt" content={coverAlt} />
<meta property="og:url" content={Astro.url} />
<meta property="og:type" content="article" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content={resolvedOgTitle} />
<meta name="twitter:description" content={resolvedOgDescription} />
<meta name="twitter:image" content={ogImageUrl} />
<meta name="twitter:image:alt" content={coverAlt} />
```

### Key Design Decisions

- **Fallback cascading**: `ogTitle || title` and `ogDescription || description` — optional OG fields fall back to the required base fields.
- **Absolute image URLs**: `new URL(coverImage, Astro.url.origin)` ensures OG image URLs are absolute (required by social media crawlers).
- **`twitter:card: summary_large_image`**: Large image preview for Twitter/X link unfurls.
- **`coverImage` + `coverAlt`**: Required fields in the content schema, always available for OG image output.

## Content Schema for Social Metadata

In `src/content.config.ts`, the blog collection schema should include:

```ts
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro:schema';

const blog = defineCollection({
  loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    title: z.string().max(60),          // SEO best practice: ≤60 chars
    description: z.string().max(160),   // SEO best practice: ≤160 chars
    pubDate: z.coerce.date(),
    coverImage: z.string(),             // Required — used for OG image
    coverAlt: z.string(),               // Required — alt text for OG image
    ogTitle: z.string().optional(),     // Falls back to title
    ogDescription: z.string().optional(), // Falls back to description
  }),
});

export const collections = { blog };
```

## Layout Integration

In `src/layouts/BlogPost.astro`, replace `BaseHead` with `SEOHead`:

```astro
---
import SEOHead from '../components/SEOHead.astro';
// ...
---
<head>
  <SEOHead
    title={frontmatter.title}
    description={frontmatter.description}
    coverImage={frontmatter.coverImage}
    coverAlt={frontmatter.coverAlt}
    ogTitle={frontmatter.ogTitle}
    ogDescription={frontmatter.ogDescription}
  />
</head>
```

## Content Migration Checklist

When renaming image fields (e.g., `heroImage` → `coverImage`) across a blog:

1. **Update schema** in `src/content.config.ts` — rename field, add new required fields
2. **Create/update layout** — pass new fields to the SEO component
3. **Migrate all content files** — rename frontmatter keys, add required new fields
4. **Update all page references** — e.g., `post.data.heroImage` → `post.data.coverImage` in listing pages
5. **Verify with search** — `search_files(pattern='heroImage')` should return 0 matches
6. **Run lint** — `npm run lint` must pass clean

### Pitfall: Sibling Repos

When the working directory is `my-blog` but the actual blog with content collections is in a sibling repo (e.g., `../blog/`), always verify which repo contains `src/content.config.ts` before editing. Use `ls ../` to list sibling directories.

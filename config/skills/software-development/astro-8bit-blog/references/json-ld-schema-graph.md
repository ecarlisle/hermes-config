# JSON-LD SchemaGraph Component

## Component: `src/components/SEO/SchemaGraph.astro`

Type-safe, zero-runtime JSON-LD `@graph` structured data component. Renders a `<script type="application/ld+json">` tag in `<head>`.

### Props Interface

```ts
type Props = {
  title: string;
  description: string;
  canonicalUrl: URL | string;
  pubDate?: Date;    // triggers BlogPosting node
  tags?: string[];   // passed to BlogPosting.keywords
};
```

### Graph Nodes (always emitted)

1. **Person** (`@id: {siteRoot}/#person`) — site author identity
2. **WebSite** (`@id: {siteRoot}/#website`) — site-wide web presence
3. **WebPage** (`@id: {absoluteUrl}#webpage`) — current page landmark

### Conditional Node (when `pubDate` is passed)

4. **BlogPosting** (`@id: {absoluteUrl}#blogpost`) — article-level structured data with `headline`, `datePublished`, `author`, `publisher`, `keywords`

### Rendering

```astro
<script type="application/ld+json" set:html={JSON.stringify(graphData)} />
```

No third-party NPM packages. Pure `JSON.stringify()` output injection via Astro's `set:html` directive.

### Canonical URL Resolution

In each layout that mounts SchemaGraph:

```ts
const canonicalUrl = new URL(Astro.url.pathname, Astro.site || 'https://ericcarlisle.com');
```

**Note:** `Astro.site` resolves from `astro.config.mjs` `site` key. Both `astro.config.mjs` AND `src/consts.ts` (`SITE_URL`) must be kept in sync — a mismatch causes contradicting `og:url` and canonical URLs.

### Mounting — Must Be in EVERY Layout Tree

The blog has two independent layout trees. SchemaGraph must be mounted in both:

| Layout | Pages Served | Mounted? |
|--------|-------------|----------|
| `BaseLayout.astro` | Homepage (`/`) | Import + mount in `<head>` |
| `BlogPost.astro` | Blog articles (`/blog/*`), About (`/about`) | Import + mount in `<head>` |

**Pattern for `BlogPost.astro`:**

```astro
---
import SchemaGraph from '../components/SEO/SchemaGraph.astro';
// ... existing imports
const { title, description, pubDate, /* etc */ } = Astro.props;
const canonicalUrl = new URL(Astro.url.pathname, Astro.site);
---
<head>
  <SEOHead ... />
  <SchemaGraph title={title} description={description} canonicalUrl={canonicalUrl} pubDate={pubDate} />
</head>
```

Missing a layout = zero structured data on those pages. Google Rich Results won't find `BlogPosting` nodes on blog articles if only `BaseLayout` mounts SchemaGraph.

### Verification

In browser DevTools console:

```js
JSON.parse(document.querySelector('script[type="application/ld+json"]').textContent)
```

Or paste the page URL into [Google Rich Results Test](https://search.google.com/test/rich-results).

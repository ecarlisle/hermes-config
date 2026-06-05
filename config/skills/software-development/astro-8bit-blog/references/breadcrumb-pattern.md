# Breadcrumb Navigation Pattern in Astro

Astro has **no native breadcrumb component or primitive**. Breadcrumbs must be built manually from `Astro.url.pathname` and `Astro.params` for dynamic route segments.

## Component Architecture

Split into two independent, composable components:

1. **`Breadcrumb.astro`** — Renders the visible `<nav>` breadcrumb trail
2. **`BreadcrumbList.astro`** — Renders Schema.org `BreadcrumbList` JSON-LD `<script>` tag

Both are standalone and can be mounted independently in any layout.

---

## Breadcrumb.astro — Visible Nav Trail

```astro
---
// src/components/Breadcrumb.astro
interface BreadcrumbItem {
  label: string;
  href: string;
}

const KNOWN_LABELS: Record<string, string> = {
  about: 'About',
  blog: 'Blog',
  tags: 'Tags',
  portfolio: 'Portfolio',
  categories: 'Categories',
};

const segments = Astro.url.pathname.split('/').filter(Boolean);
const items: BreadcrumbItem[] = [];
let accumulated = '';

items.push({ label: 'Home', href: '/' });

for (let i = 0; i < segments.length; i++) {
  const segment = segments[i];
  accumulated += `/${segment}`;
  const isLast = i === segments.length - 1;

  // Resolve dynamic segments via Astro.params
  let label = KNOWN_LABELS[segment] ?? segment;
  if (segment.startsWith('[') || isLast) {
    const resolved = Object.values(Astro.params ?? {}).find(Boolean);
    if (resolved) label = resolved.charAt(0).toUpperCase() + resolved.slice(1);
  }

  items.push({ label, href: accumulated });
}
---

<nav aria-label="breadcrumb" class="breadcrumb-nav">
  <ol class="breadcrumb-list">
    {items.map((item, i) => {
      const isLast = i === items.length - 1;
      return (
        <li class="breadcrumb-item">
          {isLast ? (
            <span aria-current="page" class="breadcrumb-current">{item.label}</span>
          ) : (
            <>
              <a href={item.href} class="breadcrumb-link">{item.label}</a>
              <span class="breadcrumb-separator" aria-hidden="true"> / </span>
            </>
          )}
        </li>
      );
    })}
  </ol>
</nav>
```

### Key Patterns

- **`KNOWN_LABELS` map** — Maps static route segments to human-readable labels. Add entries for every top-level route.
- **Dynamic segment resolution** — Reads `Astro.params` to resolve `[...id]` or `[slug]` params into display labels.
- **`aria-current="page"`** — Last breadcrumb item (current page) gets this attribute for screen reader accessibility.
- **Separator** — Visual separator (` / `) has `aria-hidden="true"` so screen readers don't announce it.

---

## BreadcrumbList.astro — Schema.org JSON-LD

```astro
---
// src/components/SEO/BreadcrumbList.astro
interface ListItem {
  '@type': 'ListItem';
  position: number;
  name: string;
  item: string;
}

const siteRoot = 'https://ericcarlisle.com';
const segments = Astro.url.pathname.split('/').filter(Boolean);
const listItems: ListItem[] = [
  { '@type': 'ListItem', position: 1, name: 'Home', item: `${siteRoot}/` },
];

let accumulated = '';
for (let i = 0; i < segments.length; i++) {
  const segment = segments[i];
  accumulated += `/${segment}`;
  let label = segment.charAt(0).toUpperCase() + segment.slice(1);
  if (i === segments.length - 1) {
    const resolved = Object.values(Astro.params ?? {}).find(Boolean);
    if (resolved) label = resolved.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
  }
  listItems.push({
    '@type': 'ListItem',
    position: i + 2,
    name: label,
    item: `${siteRoot}${accumulated}`,
  });
}

const breadcrumbLd = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: listItems,
};
---

<script type="application/ld+json" set:html={JSON.stringify(breadcrumbLd)} />
```

### Key Patterns

- **Composable alongside `SchemaGraph.astro`** — Mount `BreadcrumbList` *before* or *after* `SchemaGraph` in `<head>`. They are independent `<script>` tags.
- **Absolute URLs** — Every `item` URL is fully qualified with `https://ericcarlisle.com`.
- **Dynamic segment title-casing** — Hyphenated IDs like `the-zero-js-quiz-matrix` are converted to title case: `The Zero Js Quiz Matrix`.

---

## Mounting in Layouts

> **⚠️ CRITICAL:** The project has **two independent layout trees**:
> - `BaseLayout.astro` — homepage and top-level pages
> - `BlogPost.astro` — blog articles + about page (has its own `<html>/<head>`)
>
> **BOTH layouts must mount both breadcrumb components.**

```astro
---
// In BaseLayout.astro OR BlogPost.astro
import Breadcrumb from '../components/Breadcrumb.astro';
import BreadcrumbList from '../components/SEO/BreadcrumbList.astro';
---

<head>
  <!-- ...BaseHead or other head components... -->
  <!-- ...SchemaGraph... -->
  <BreadcrumbList />
</head>
<body>
  <!-- <Header /> -->
  <Breadcrumb />
  <main>
    <slot />
  </main>
</body>
```

---

## Pitfalls

- **BlogPost.astro has its own `<html>/<head>`** — It does NOT extend BaseLayout. Every `<head>` addition (breadcrumbs, SchemaGraph) must be duplicated here.
- **`siteRoot` is hardcoded** — Change `https://ericcarlisle.com` if the domain changes. Should match `astro.config.mjs` `site:` and `consts.ts` `SITE_URL`.
- **Only one `<script type="application/ld+json">` per component** — If you need multiple JSON-LD types on one page, merge them into a `@graph` array (see `SchemaGraph.astro` pattern) rather than adding multiple script tags.

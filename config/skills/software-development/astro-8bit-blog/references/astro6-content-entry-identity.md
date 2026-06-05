# Astro 6 Content Entry Identity: `post.id` vs `post.slug`

## The Bug

In Astro 6 with `glob` loaders (defined via `glob({ base, pattern })`), content collection entries expose **`id`** as the URL-safe slug identifier. The `slug` property is **`undefined`**.

Using `post.slug` to construct link paths produces `/blog/undefined/` URLs that silently resolve to 404s — no build error is thrown.

## The Fix

```astro
<!-- ❌ WRONG — produces /blog/undefined/ -->
<a href={`/blog/${post.slug}/`}>

<!-- ✅ CORRECT — produces /blog/stunningly-simple-architecture/ -->
<a href={`/blog/${post.id}/`}>
```

## Why This Happens

Astro 5 used `slug` as the primary identifier. Astro 6 introduced a breaking change: `id` replaces `slug` for `glob`-loaded collections. The `slug` field still exists on `defineCollection` entries that use a custom loader with an explicit `slug` implementation, but for the default `glob` loader it is not populated.

## Diagnostic Steps

1. Build the site: `npm run build`
2. Search the output for `undefined` in link hrefs: `grep -c 'undefined' dist/index.html`
3. If > 0, search source for `post.slug`: `rg 'post\.slug' src/`
4. Replace all occurrences with `post.id`

## Verification

After the fix, confirm zero undefined URLs:
```bash
npm run build
grep -c 'undefined' dist/index.html  # must be 0
grep -o '/blog/[^/]*/' dist/index.html | sort -u  # list all blog routes
```

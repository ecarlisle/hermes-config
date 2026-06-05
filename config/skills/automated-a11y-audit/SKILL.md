---
name: automated-a11y-audit
description: "Run automated WCAG 2.1 AA accessibility audits against local dev servers using Lighthouse CLI and axe-core. Parse JSON reports, identify contrast/label/semantic violations, and output structured remediation with exact code fixes."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [a11y, accessibility, lighthouse, axe-core, wcag, audit, qa]
    related_skills: [dogfood, requesting-code-review]
---

# Automated A11y Audit

## Overview

Run programmatic accessibility audits against a live local dev server. This skill covers the full pipeline: launching Lighthouse headless, parsing JSON output for WCAG 2.1 AA violations, and generating exact code fixes for `.astro`/`.html`/`.css` templates.

**This is NOT interactive browser QA** — use the `dogfood` skill for that. This skill is for automated, repeatable, CI-grade accessibility scanning.

## Prerequisites

- A live dev server (e.g., `http://localhost:4321`)
- Lighthouse CLI available (`node_modules/.bin/lighthouse` or `npx lighthouse`)
- Node.js project with the site built and serving

## Workflow

### Phase 1: Run Lighthouse Headless

```bash
node_modules/.bin/lighthouse http://localhost:PORT/ \
  --only-categories=accessibility \
  --output=json \
  --output-path=/tmp/a11y-report.json \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  --quiet
```

**Pitfall:** `lighthouse` binary may not be in PATH within tool subshells. Always use the full path from `node_modules/.bin/lighthouse` or `npx lighthouse`. Do NOT rely on `which lighthouse` — it may return a path that doesn't work in subshells.

**Pitfall:** The dev server must be restarted after code changes. Astro's dev server caches aggressively — if Lighthouse still reports old violations after you've fixed the code, kill and restart the dev server.

### Phase 2: Parse the JSON Report

The Lighthouse JSON report is large (~150KB). Use `search_files` to find violations efficiently:

1. **Find failing audits:** Search for `"score": 0` in the report JSON
2. **Get the overall score:** Search for `"id": "accessibility"` and read the `"score"` field (1.0 = 100/100)
3. **Read violation details:** Each failing audit has a `details.items[]` array with:
   - `node.selector` — CSS selector for the failing element
   - `node.snippet` — HTML snippet showing the element
   - `node.explanation` — Human-readable fix instructions with computed colors and contrast ratios
   - `node.nodeLabel` — The accessible name or visible text

**Pitfall:** `execute_code` and pipe-to-interpreter patterns may be blocked by security policy. Use `read_file` with offset/limit and `search_files` to extract data from the JSON instead.

**⚠️ CRITICAL — Fallback when Lighthouse/axe binaries are unavailable:** When `lighthouse` and `axe-core/cli` are not functional in PATH, use static HTML analysis via `curl` + `grep`:

```bash
curl -s http://localhost:4321/ > /tmp/homepage.html
grep -o '<html[^>]*lang="[^"]*"' /tmp/homepage.html   # Check lang attr
grep -o '<title>[^<]*</title>' /tmp/homepage.html      # Check title
grep -c '<h1' /tmp/homepage.html                        # Count h1 (should be 1)
grep -c '<h2' /tmp/homepage.html                        # Count h2
grep -c 'target="_blank"' /tmp/homepage.html             # External links missing rel
grep -c 'aria-label' /tmp/homepage.html                 # aria-label coverage
grep -c '<nav' /tmp/homepage.html                        # Nav landmarks
grep -c '<main' /tmp/homepage.html                       # Main landmark
grep -c 'noopener' /tmp/homepage.html                    # rel="noopener noreferrer"
```

**What this catches:** missing/duplicate `<title>`, heading hierarchy skips, `<nav>` without `aria-label>`, missing `<main>`, `target="_blank"` without `rel="noopener noreferrer"`, empty anchor text on social icon links, missing skip navigation link.

**What this MISSES:** color contrast (needs computed styles), `:focus-visible` styles (check CSS files for `:focus-visible` rules), ARIA state management, keyboard traps.

**⚠️ CRITICAL — Do NOT install packages to run accessibility audits.** If the project has pre-configured MCP server tools, use those instead of installing `lighthouse`, `axe-core/cli`, or `pa11y`. Installing packages is a last resort when NO MCP tool exists for the task.

**⚠️ CRITICAL — `execute_code` and pipe-to-interpreter are BLOCKED by security policy.** Running Python via `execute_code` or `curl | python3 -c "..."` will be blocked with "user has NOT consented" errors. This is NOT a transient failure — it is a permanent policy constraint. Use `read_file` + `search_files` + `grep` via `terminal` instead.

**⚠️ CRITICAL — `npx --yes @axe-core/cli` triggers a browser download prompt that blocks.** The axe-core CLI requires a Chromium download on first run, which hangs waiting for user input in a non-interactive terminal. Do NOT use `npx @axe-core/cli` for automated audits. Use the `curl + grep` static analysis fallback instead.

### Phase 2b: Static HTML Analysis (Reliable Fallback)

When Lighthouse/axe binaries are unavailable or blocked, use `curl` + `grep` via `terminal`:

```bash
curl -s http://localhost:4321/ > /tmp/homepage.html

# Structural checks
grep -c '<html[^>]*lang=' /tmp/homepage.html          # lang attr present
grep -c '<title>' /tmp/homepage.html                   # title present
grep -c '<h1' /tmp/homepage.html                       # exactly 1 h1
grep -c '<nav' /tmp/homepage.html                      # nav landmarks
grep -c '<main' /tmp/homepage.html                     # main landmark
grep -c 'target="_blank"' /tmp/homepage.html           # external links
grep -c 'noopener noreferrer' /tmp/homepage.html       # rel attributes
grep -c 'skip-link\|skipnav\|skip-link' /tmp/homepage.html  # skip nav
grep -c 'aria-label' /tmp/homepage.html                # aria-label coverage

# Social link checks — empty anchors without sr-only text
grep -oE '<a[^>]*href="https://(twitter|github|facebook|linkedin|mastodon)[^"]*"[^>]*>' /tmp/homepage.html

# Heading hierarchy — extract in document order
grep -oE '<h[1-6]\b[^>]*>[^<]+</h[1-6]>' /tmp/homepage.html

# Images without alt
grep -oE '<img[^>]*>' /tmp/homepage.html | grep -v 'alt='

# Inputs without labels
grep -oE '<input[^>]*>' /tmp/homepage.html
```

**What this catches:** missing/duplicate `<title>`, heading hierarchy skips, `<nav>` without `aria-label`, missing `<main>`, `target="_blank"` without `rel="noopener noreferrer"`, empty anchor text on social icon links, missing skip navigation link, images without `alt`, inputs without labels.

**What this MISSES:** color contrast (needs computed styles), `:focus-visible` styles (check CSS files for `:focus-visible` rules via `search_files`), ARIA state management, keyboard traps.

**Verify CSS patterns separately:**
```bash
search_files(pattern=':focus-visible|:focus', path='src/styles', file_glob='*.css')
search_files(pattern='\\.sr-only', path='src/styles', file_glob='*.css')
```

### Phase 3: Fix Violations

#### Color Contrast Failures

The `explanation` field gives you exact computed values:
```
Element has insufficient color contrast of 1.07 (foreground color: #f87171, background color: #a1a1aa, font size: 6.0pt (8px), font weight: normal). Expected contrast ratio of 4.5:1
```

**Debugging technique:** The "background color" in the explanation is the COMPUTED background — which may be a sibling/parent element behind the text, not the element's own `background-color`. Inspect the DOM path in `node.path` to understand which element provides the actual background.

**Fix strategy:**
1. Identify the actual background color from the explanation
2. Calculate a foreground color that achieves 4.5:1 (normal text) or 3:1 (large text ≥18pt or ≥14pt bold)
3. If the text overlaps a moving/interactive element (e.g., a slider thumb), consider restructuring the DOM so the text doesn't overlap — this is more reliable than trying to find a color that works on multiple backgrounds

#### Label-Content-Name Mismatch

This occurs when an element has visible text content that doesn't match its `aria-label` or computed accessible name.

**Pitfall:** Adding `aria-hidden="true"` to child elements does NOT suppress their text from axe-core's `label-content-name-mismatch` check. The rule still sees the text content.

**Correct fix:** Move the visible text OUTSIDE the element with the `aria-label`. Restructure the DOM so the labeled element contains no visible text that isn't part of its accessible name. Use a sibling element with `aria-hidden="true"` for purely visual labels.

#### Semantic Structure Failures

- Ensure `<nav>` elements have `aria-label` distinguishing them from other navs
- Ensure `<main>` exists and is unique
- Ensure heading hierarchy is logical (h1 → h2 → h3, no skips)
- Ensure form inputs have associated `<label>` elements

### Phase 4: Rebuild and Re-Audit

After every fix:

1. Rebuild: `npm run build`
2. **Restart the dev server** if fixes don't appear in the next Lighthouse run
3. **Verify fixes in built output** — `grep` the `dist/` HTML to confirm skip links, `rel` attributes, and `id="main-content"` are present in rendered output, not just source:
   ```bash
   grep -c 'skip-link' dist/index.html
   grep -c 'noopener noreferrer' dist/index.html
   grep -c 'id="main-content"' dist/index.html
   ```
4. Re-run Lighthouse (or static analysis) to verify the fix
5. Repeat until all violations are resolved and overall score is 1.0

## Common WCAG 2.1 AA Thresholds

| Text Size | Minimum Contrast |
|-----------|-----------------|
| Normal (< 18pt, < 14pt bold) | 4.5:1 |
| Large (≥ 18pt, ≥ 14pt bold) | 3:1 |

## Reference: Contrast Debugging

When Lighthouse reports a contrast failure, the `explanation` field contains everything you need:

```
foreground color: #f87171, background color: #a1a1aa, font size: 6.0pt (8px), font weight: normal
```

Use these exact values to calculate fixes. The background color is the computed background at the text's position — which may come from a parent or sibling element, not the text element itself.

See `references/contrast-fix-patterns.md` for common fix patterns and pre-computed safe color pairs for both dark and light themes.

See `references/static-html-audit-patterns.md` for grep/curl-based static HTML audit patterns when Lighthouse/axe binaries are unavailable.

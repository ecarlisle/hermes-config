# Static HTML Accessibility Audit Patterns

Use these grep/curl patterns when Lighthouse CLI and axe-core CLI are unavailable.

## Setup

```bash
curl -s http://localhost:4321/ > /tmp/homepage.html
```

## WCAG 2.1 AA Checks via Static Analysis

### 1. Language Attribute (WCAG 3.1.1)
```bash
grep -o '<html[^>]*lang="[^"]*"' /tmp/homepage.html
# FAIL: no match or lang=""
```

### 2. Page Title (WCAG 2.4.2)
```bash
grep -o '<title>[^<]*</title>' /tmp/homepage.html
# FAIL: no match or empty <title></title>
```

### 3. Heading Hierarchy (WCAG 1.3.1)
```bash
grep -c '<h1' /tmp/homepage.html   # Should be exactly 1
grep -c '<h2' /tmp/homepage.html   # Should be > 0 if h3 exists
grep -c '<h3' /tmp/homepage.html
# FAIL: h1 count != 1, or h3 > 0 but h2 == 0 (skip)
```

### 4. Landmark Structure (WCAG 1.3.1)
```bash
grep -c '<nav' /tmp/homepage.html    # Should be >= 1
grep -c '<main' /tmp/homepage.html   # Should be exactly 1
grep -c '<footer' /tmp/homepage.html # Should be >= 1
# Multiple <nav> must each have aria-label
grep -o '<nav[^>]*aria-label="[^"]*"' /tmp/homepage.html
```

### 5. Skip Navigation (WCAG 2.4.1)
```bash
grep -i 'skip' /tmp/homepage.html | grep -i 'main\|content'
# FAIL: no match — no skip link exists
```

### 6. External Links — rel attribute (WCAG 2.4.4, Security)
```bash
# Find target="_blank" links
grep -o '<a[^>]*target="_blank"[^>]*>' /tmp/homepage.html | wc -l
# Check if they have rel="noopener noreferrer"
grep -o '<a[^>]*target="_blank"[^>]*rel="noopener[^"]*"[^>]*>' /tmp/homepage.html | wc -l
# FAIL: counts differ — some links missing rel
```

### 7. Empty Anchor Text / Missing aria-label (WCAG 4.1.2)
```bash
# Find <a> tags with no visible text (icon links)
# Pattern: <a ...></a> or <a ...><svg ...></svg></a> with no text
python3 -c "
import re
with open('/tmp/homepage.html') as f:
    html = f.read()
# Find all <a> tags
links = re.findall(r'<a\s[^>]*>(.*?)</a>', html, re.DOTALL)
empty = [i for i, l in enumerate(links) if not l.strip() or l.strip().startswith('<svg') or l.strip().startswith('<i ')]
print(f'Empty/icon-only links: {len(empty)}')
"
```

### 8. Focus-Visible Styles (WCAG 1.4.11)
```bash
# Check CSS files for :focus-visible or :focus styles
grep -r ':focus-visible\|:focus' src/styles/ --include="*.css"
# FAIL: no match — keyboard users get zero focus indication
```

### 9. Image Alt Text (WCAG 1.1.1)
```bash
grep -o '<img[^>]*>' /tmp/homepage.html | grep -v 'alt="[^"]'
# FAIL: any match — images without alt attribute
```

## What Static Analysis Cannot Detect

- **Color contrast ratios** — requires computed styles (use Lighthouse or browser DevTools)
- **ARIA state correctness** — requires runtime DOM inspection
- **Keyboard trap detection** — requires interactive testing
- **Focus order** — requires tab-through testing
- **Dynamic content accessibility** — requires JS execution

## When to Use This Approach

- Lighthouse/axe-core binaries not in PATH
- `npx @axe-core/cli` blocked by browser download prompts
- `lighthouse` CLI returns "command not found" despite `which` listing it
- Quick pre-check before running full dynamic audit

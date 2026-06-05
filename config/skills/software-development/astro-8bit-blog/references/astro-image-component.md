# Astro `<Image />` Component — API Reference

Source: https://docs.astro.build/en/reference/modules/astro-assets/

## Import

```astro
---
import { Image } from 'astro:assets';
---
```

Also available from `astro:assets`: `Picture`, `Font`, `getImage`, `inferRemoteSize`, `getConfiguredImageService`, `imageConfig`.

## Required Props

| Prop | Type | Notes |
|------|------|-------|
| `src` | `ImageMetadata \| string \| Promise<{ default: ImageMetadata }>` | Required. Local import, `public/` path, or remote URL. |
| `alt` | `string` | Required. Use `""` for decorative images. |

## `src` Value by Location

### Local images in `src/` (auto-dimensions)
```astro
---
import { Image } from 'astro:assets';
import myImage from '../assets/my_image.png'; // Image is 1600x900
---
<Image src={myImage} alt="A description of my image." />
<!-- Output: width="1600" height="900" automatically -->
```

### Images in `public/` (manual dimensions required)
```astro
---
import { Image } from 'astro:assets';
---
<Image
  src="/images/my-public-image.png"
  alt="descriptive text"
  width="200"
  height="150"
/>
```

### Remote images (manual dimensions or `inferSize`)
```astro
---
import { Image } from 'astro:assets';
---
<Image
  src="https://example.com/remote-image.jpg"
  alt="descriptive text"
  width="200"
  height="150"
/>
<!-- OR use inferSize to auto-fetch dimensions: -->
<Image src="https://example.com/cat.png" inferSize alt="A cat sleeping." />
```

## Dimension Props

| Prop | Type | Required? |
|------|------|-----------|
| `width` | `number \| \`\${number}\` \| undefined` | Required for `public/` and remote; auto-inferred for local imports. |
| `height` | `number \| \`\${number}\` \| undefined` | Required for `public/` and remote; auto-inferred for local imports. |

## Responsive Image Props

### `layout` (recommended for responsive images)
Type: `'constrained' | 'full-width' | 'fixed' | 'none'`
Default: `image.layout` config or `'none'`

| Value | Behavior |
|-------|----------|
| `constrained` | Scales down to fit container, won't scale up beyond original. Auto-generates `srcset` + `sizes`. Best for most content images. |
| `full-width` | Always fills container width. Good for hero images. |
| `fixed` | Never resizes. Generates density-based srcset for HiDPI. Good for icons/logos. |
| `none` | No responsive behavior. No auto srcset/sizes. |

When `layout` is set, `widths` and `sizes` are auto-generated. You can override them manually.

### `widths` + `sizes` (manual responsive control)
```astro
<Image
  src={myImage}
  widths={[240, 540, 720, myImage.width]}
  sizes={`(max-width: 360px) 240px, (max-width: 720px) 540px, (max-width: 1600px) 720px, ${myImage.width}px`}
  alt="A description of my image."
/>
```

### `densities` (alternative to `widths` for density-based srcset)
```astro
<Image src={myImage} width={myImage.width / 2} densities={[1.5, 2]} alt="..." />
```

**Note:** `densities` and `widths` are mutually exclusive. Both are incompatible with `layout`.

## Other Props

| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `format` | `ImageOutputFormat` | `'webp'` | Output format: `'avif' \| 'webp' \| 'png' \| 'jpeg' \| 'svg'` |
| `quality` | `ImageQuality` | — | Preset (`'low' \| 'mid' \| 'high' \| 'max'`) or number 0–100 |
| `inferSize` | `boolean` | `false` | Auto-fetch dimensions for remote images (Astro 4.4+). Only works for allowed remote domains (5.17.3+). |
| `priority` | `boolean` | `false` | Sets `loading="eager"`, `decoding="sync"`, `fetchpriority="high"`. Use for above-the-fold images. |

## Common Patterns

### Hero image (full-width, priority loading)
```astro
---
import { Image } from 'astro:assets';
import hero from '../assets/hero.png';
---
<Image src={hero} alt="Hero description" layout="full-width" priority />
```

### Content image (constrained, lazy loaded)
```astro
---
import { Image } from 'astro:assets';
import diagram from '../assets/diagram.png';
---
<Image src={diagram} alt="Architecture diagram" layout="constrained" width={800} height={600} />
```

### Fixed-size icon/logo
```astro
---
import { Image } from 'astro:assets';
import logo from '../assets/logo.png';
---
<Image src={logo} alt="Site logo" layout="fixed" width={48} height={48} />
```

### Remote image with inferred dimensions
```astro
---
import { Image } from 'astro:assets';
---
<Image src="https://example.com/photo.jpg" inferSize alt="Remote photo" />
```

## Output

The component renders an optimized `<img>` tag with:
- `decoding="async"` (or `"sync"` with `priority`)
- `loading="lazy"` (or `"eager"` with `priority`)
- Auto-generated `srcset` when using `layout`, `widths`, or `densities`
- WebP format by default
- Hashed filename for cache busting

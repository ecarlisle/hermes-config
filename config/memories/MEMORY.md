skill_manage write_file uses `file_content` (not `content`). Biome `--unsafe` is DESTRUCTIVE on Astro: auto-prefixes used vars with `_`, re-introducing ReferenceErrors. Never use `--unsafe`. False-positive `noUnusedVariables` on `.astro` files = ignore, build is truth.
§
Astro 8-bit blog at /Users/eric/repos/blog. Astro v6.4.3, strict TS, CSS, Playwright. NES dark (#121212), Capcom Blue #3b82f6, Konami Red #ef4444, 2px pixel borders. Font stack: Syncopate 700 (display/headers), Inter 400/500/700 (body), Fira Code 400/600 (mono). Google Fonts <link> tags in BaseHead.astro. Domain: ericcarlisle.com — astro.config.mjs AND consts.ts SITE_URL AND BreadcrumbList.astro siteRoot must ALL sync. /Users/eric/repos/my-blog is DEPRECATED. Scoped <style> font-family MUST use var(--font-family-*) tokens — scoped overrides :root. SCSS retired: no darken/lighten/color.adjust — pre-computed hex only. Astro v6 native `fonts` array (local + fontsource providers) + `security: { csp: true }` enabled. Shiki/CSP warning accepted. Breadcrumb nav (Breadcrumb.astro + BreadcrumbList.astro) mounted in BOTH layout trees.
§
nvm default alias is set to Node v24.16.0 (lts/Krypton, active LTS as of 2025-06). Always prefix terminal commands with `export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" && nvm use 24` for Astro/Node projects.
§
Lighthouse a11y: use node_modules/.bin/lighthouse, parse JSON score:0 via search_files, restart dev server between rounds. aria-hidden=true on children does NOT fix label-content-name-mismatch. Fallback: curl+grep static HTML analysis when binaries unavailable.
§
macOS environment has NODE_ENV=production set globally, which causes npm install to skip devDependencies. Always use NODE_ENV=development npm install for this machine.
§
Default working repo is `/Users/eric/repos/blog` (full Astro blog with content collections). The `my-blog` repo at /Users/eric/repos/my-blog is deprecated — do not start new work there.
§
MCP tools exposed by server but NOT in runtime palette = gateway restart needed. Do NOT reinstall packages or edit config. Restart Hermes gateway.
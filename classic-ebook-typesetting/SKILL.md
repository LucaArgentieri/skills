---
name: classic-ebook-typesetting
description: This skill should be used when the user asks to "typeset an ebook", "impaginare un ebook come un libro classico", "convert an ebook/PDF into a classic book layout", "create a book cover for a PDF", "generate a Gumroad-ready ebook cover", or otherwise wants a PDF ebook laid out with classic print-book typography (serif font, justified text, chapter openings, page numbers) without using LaTeX. Also applies when the user wants a full-bleed illustrated book cover embedded as the first page of an ebook PDF, or wants that same cover exported in multiple aspect ratios for a storefront listing.
---

# Classic ebook typesetting (no LaTeX)

Typeset an existing ebook's text content as a classic printed book PDF, using HTML + CSS Paged Media (via the Paged.js polyfill) rendered through headless Chromium (Playwright) — no LaTeX, no Homebrew dependency, no PDF-authoring GUI. This produces trade-paperback-quality typography (serif font, justified/hyphenated text, running chapter openings, page numbers) purely from HTML/CSS.

Use this skill for the full pipeline: converting raw ebook content into semantic HTML, styling it as a 6×9in trade paperback, rendering it to PDF, and producing a matching illustrated cover in the formats a storefront (e.g. Gumroad) requires.

## When NOT to use this

Skip this skill for content with heavy math/formulas (LaTeX would genuinely be better), or for ebooks that already have acceptable layout and only need a cover image (in that case jump straight to the cover-generation step).

## Workflow overview

1. **Set up a scratch project folder** with `npm install playwright pagedjs` (or copy `assets/render.js`/`assets/render-cover.js`, which assume these two deps), then `npx playwright install chromium`.
2. **Download EB Garamond** (or another OFL/open serif) as self-hosted TTFs — Paged.js/Chromium needs local `@font-face` files, not a `<link>` to Google Fonts, because the polyfill's own asset-loading works more reliably with local files. Fetch Regular/Medium/SemiBold/Bold/Italic/MediumItalic directly from `fonts.gstatic.com` (find the URLs via the Google Fonts CSS API) into a local `fonts/` folder.
3. **Write `book.html`**: semantic sections — `.frontmatter.coverpage` (full-bleed cover image, see step 5), `.frontmatter.contents` (TOC), then one `<section class="chapter" data-title="...">` per chapter with a `.chapter-kicker` + `.chapter-title`. Keep prose in plain `<p>` tags — no manual line breaks. End the file with the two `<script>` tags shown in `assets/render.js`'s companion HTML pattern: a `window.PagedConfig` block that sets `window.__pagedjsDone = true` in `after`, then `<script src="node_modules/pagedjs/dist/paged.polyfill.js">`.
4. **Copy and adapt `assets/book.css`** — it already encodes every typography decision validated across multiple real projects: uniform margins on every page (not mirrored/alternating), page numbers centered at the bottom (not alternating left/right — see `references/pitfalls.md` for why), full-bleed cover page, chapter-opening spacing tuned to avoid orphaned single lines, no drop caps/no first-line indent (paragraph spacing instead), a `dl.glossary` pattern for reference sections. Adjust only the title/chapter names and font-family fallback if not using EB Garamond.
5. **Generate the cover** — see `references/cover-generation.md` for the full technique (canvas-based background whitening to erase visible borders around line-art illustrations, plus exporting 2:3/1:1/16:9 variants). Embed the 2:3 (trim-size-matching) version as the book's own first page via `.frontmatter.coverpage` in `book.html`.
6. **Render**: `node render.js` (adapted from `assets/render.js`) starts a local static HTTP server (Paged.js's asset loading fails under `file://` due to CORS — always serve over `http://localhost:PORT`), opens the page in headless Chromium, waits for `window.__pagedjsDone === true`, then exports via `page.pdf({ printBackground: true, preferCSSPageSize: true })`.
7. **Verify by reading the actual rendered PDF** page by page (not just trusting the page count) — check: no orphaned single lines/words on their own page, chapter openings start cleanly, page numbers appear on every content page in a consistent position, no visible seam around cover art, TOC page numbers match reality if referenced anywhere in text.

Read `references/pitfalls.md` before implementing — it documents specific bugs hit while building this pipeline and their fixes, so they aren't rediscovered from scratch.

## Key CSS decisions worth calling out inline

- `@page { size: 6in 9in; margin: ...; }` with **identical margins on every page** (left/right/top/bottom), not the mirrored inner/outer margins used in bound print books — a screen-read PDF has no "facing pages," so mirrored margins just look inconsistent between pages.
- Page number via a single `@page { @bottom-center { content: counter(page); } }` rule — not `@page :left`/`:right` with `@bottom-left`/`@bottom-right`, which alternates the folio position per page. That convention exists for physically bound books read as two-page spreads; a PDF read one page at a time should keep the number in one fixed place.
- A named `@page coverpage { margin: 0; }` page type (applied via `.frontmatter.coverpage { page: coverpage; }`) for the single full-bleed cover page, distinct from the body's `@page` margins.
- Chapter-opening pages get a custom Paged.js `Handler` (registered in `window.PagedConfig.before`) that tags the first rendered page of each `.chapter` section with a `chapter-open` class, used only to hide the running header box at the top of that page (`.pagedjs_margin-top-left`/`-right`) — do **not** also hide the bottom margin box there, or the page number silently disappears on every chapter-opening page (an easy, easy-to-miss bug — see `references/pitfalls.md`).

## Bundled resources

- `assets/book.css` — full template stylesheet, drop-in starting point.
- `assets/render.js` — generic Playwright PDF-render script (local server + wait + export). Takes the HTML/CSS/output filename as top-of-file constants to edit.
- `assets/render-cover.js` — generic Playwright screenshot-render script for cover images, supports rendering multiple `{html, out, width, height}` variants in one run.
- `references/pitfalls.md` — concrete bugs hit and fixes (CORS, waitForFunction signature, Paged.js native footnotes being unreliable, mirrored-margin/alternating-folio mistakes, the chapter-open header/footer bug, avoiding orphaned chapter-ending lines).
- `references/cover-generation.md` — the canvas-whitening technique for illustration backgrounds, and the multi-aspect-ratio export pattern.

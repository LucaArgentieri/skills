---
name: ebook-typesetting
description: Typeset an ebook's text as a classic print-style PDF (serif, justified, chapter openings, page numbers) with HTML + Paged.js + Playwright, no LaTeX, Calibre or pandoc. Use when the user wants an ebook laid out like a real book ("impagina come un libro"), a full-bleed illustrated cover as its first page, or the same book exported as a reflowable EPUB.
---

# Ebook typesetting

Turn existing ebook text into a 6×9in trade-paperback-style PDF. The pipeline is plain web tech: semantic `book.html` + `assets/book.css` (CSS Paged Media), paginated by the Paged.js polyfill, printed to PDF by headless Chromium through Playwright.

`book.html` is the **single source** of the text. The PDF, the EPUB and any later edit all derive from it.

Reach for LaTeX instead when the book is heavy on math. When the user only needs a cover image, go straight to [COVER.md](COVER.md).

## Steps

Read [PITFALLS.md](PITFALLS.md) before step 1. Every entry there is a bug already paid for once.

### 1. Scaffold

In a scratch folder: `npm install playwright pagedjs` and `npx playwright install chromium`, copy `assets/render.js` and `assets/book.css`, and download an OFL serif (EB Garamond: Regular, Medium, SemiBold, Bold, Italic, MediumItalic) as local TTFs into `fonts/`, referenced with `@font-face`.

**Done when** `node -e "require('playwright'); require('pagedjs')"` succeeds and `fonts/` holds the TTFs.

### 2. Write `book.html`

Structure, in order:

- `.frontmatter.coverpage`: the full-bleed cover image (from step 4).
- `.frontmatter.contents`: the table of contents.
- One `<section class="chapter" data-title="...">` per chapter, opening with `.chapter-kicker` + `.chapter-title`, prose in plain `<p>`.
- The two closing `<script>` tags shown in the header comment of `assets/render.js` (the `PagedConfig` with the chapter-open handler, then the polyfill).

Reference sections use `<dl class="glossary">`.

**Done when** every chapter of the source is present, in order, with no text lost and no manual line breaks.

### 3. Adapt `book.css`

The template already holds the validated layout decisions (uniform margins, fixed bottom-center folio, cover page type, chapter-opening spacing). Change only the font family and anything book-specific.

**Done when** the only diffs from the template are book-specific.

### 4. Cover

Follow [COVER.md](COVER.md): whiten the illustration's background on a canvas, render the 2:3 variant with `assets/render-cover.js`, and embed it in `.frontmatter.coverpage`. Render the other aspect ratios only when the user asks for them.

**Done when** the 2:3 cover renders with no visible seam around the illustration.

### 5. Render

`node render.js`. It serves the folder over `http://localhost`, waits for `window.__pagedjsDone`, and prints with `preferCSSPageSize`.

**Done when** `book.pdf` exists and the script exited cleanly.

### 6. Verify the PDF page by page

Read the rendered pages, every one. The page count proves nothing.

**Done when** each page passes all of these:

- chapter openings start cleanly at the top
- no single orphaned line or word alone on a page
- a page number on every content page, in the same position
- no seam around the cover art
- TOC entries match the real page numbers

Without image input, check each page as text instead: `pdftotext -layout -f N -l N book.pdf -` shows chapter starts, orphaned lines and folios. The cover seam still needs eyes, so ask the user to look at page 1.

Re-render and re-verify after every text or CSS change.

## EPUB (only when asked)

EPUB reflows: nothing about `@page`, folios or the cover page carries over. Read [EPUB.md](EPUB.md), then build from the same `book.html` with `assets/build-epub.js`.

**Done when** `unzip -l book.epub` shows the cover and one XHTML per chapter, in TOC order.

## Files

- `assets/book.css`: stylesheet template.
- `assets/render.js`: HTML to PDF renderer.
- `assets/render-cover.js`: renders cover variants as images.
- `assets/build-epub.js`: EPUB builder reading `book.html`.
- [PITFALLS.md](PITFALLS.md): known bugs and their fixes.
- [COVER.md](COVER.md): background whitening and aspect-ratio variants.
- [EPUB.md](EPUB.md): how EPUB differs and how to check it.

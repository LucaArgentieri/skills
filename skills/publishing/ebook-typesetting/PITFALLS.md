# Pitfalls hit while building this pipeline (and their fixes)

Concrete bugs encountered across real projects using this HTML+Paged.js+Playwright
typesetting approach. Read this before implementing so they aren't rediscovered.

## `pagedjs-cli` may fail to install — use Playwright + `pagedjs` directly instead

`pagedjs-cli`'s bundled Puppeteer version can fail its postinstall script under
newer Node versions (e.g. `ReferenceError: require is not defined in ES module
scope` inside a transitive dependency). Skip it entirely: `npm install
playwright pagedjs`, then `npx playwright install chromium`, and drive
rendering yourself (see `assets/render.js`). This also gives full control over
the wait condition and export options.

## CORS blocks `file://` — always serve over `http://localhost`

Paged.js fetches its own assets (stylesheets, sometimes fonts) via XHR, which
Chromium blocks under the `file://` origin ("Access to XMLHttpRequest ... has
been blocked by CORS policy"). Fix: start a small local static HTTP server
(plain Node `http` module is enough — see `assets/render.js`) and navigate to
`http://localhost:PORT/book.html` instead of opening the file directly.

## `page.waitForFunction(fn, arg, options)` — the second argument is NOT options

Passing `{ timeout: 120000 }` as the second argument silently does nothing
useful (Playwright treats it as `arg`, the function's parameter), so the real
timeout stays the default 30000ms and long documents can time out. Pass
`undefined` explicitly as the second argument, with the options object third:

```js
await page.waitForFunction('window.__pagedjsDone === true', undefined, { timeout: 120000 });
```

## Paged.js's native footnote feature (`data-note="footnote"`) is unreliable — avoid it

Attempted twice, in two different chapters, to use CSS Paged Media footnotes
(an element with `data-note="footnote"` + `data-ref="..."` that Paged.js is
supposed to auto-move into a `.pagedjs_footnote_area` at the page bottom, with
an auto-inserted call marker at the original location). Both attempts produced
the same reproducible broken rendering: a stray isolated digit where the call
marker should be, and the actual note content displaced onto a different page
at full body-text size instead of small and bottom-pinned. Checked `npm view
pagedjs version` — the installed version was already the latest published; no
fix is available upstream.

**Fix**: don't use true footnotes for anything short/simple. Either (a) keep
the explanatory content in the normal text flow with a small `.fine-print`-
style treatment, or (b) if the term is already explained elsewhere (e.g. in a
glossary chapter), just add a short cross-reference sentence in the body text
("see the Glossary for more on X") instead of a footnote.

## Mirrored/alternating margins and folio position are a print-bound-book convention — don't use them for a screen-read PDF

`@page :left { margin-... }` / `@page :right { margin-... }` with different
left/right margins (inner vs. outer) is the classic-print convention for books
that will be physically bound and read as two-page spreads. It also commonly
pairs with alternating page-number position (`@bottom-left` on even pages,
`@bottom-right` on odd pages). For a PDF that will only ever be opened on a
screen and read one page at a time, this convention **actively hurts**
readability — margins look inconsistent page to page in a page-by-page viewer,
and the page number visibly jumps left/right as you scroll. Use one `@page`
rule with identical margins on every side, and one `@page { @bottom-center {
content: counter(page); } }` rule for a fixed-position folio (see
`assets/book.css`).

This also applies to frontmatter pages: if `@page frontmatter` doesn't
explicitly repeat the same `margin-left`/`margin-right` as the base `@page`
rule (or, better, just inherits from a single shared `@page` block), those
pages will visibly have different margins than the rest of the book.

## The chapter-opening "hide the running header" handler can silently eat the page number too

A common pattern: register a Paged.js `Handler` in `window.PagedConfig.before`
that tags the first rendered page of each chapter with a `chapter-open` class
(by checking for `.chapter-kicker` in that page's DOM via `afterPageLayout`),
then hide the running-header margin boxes there with CSS. The mistake is
writing the CSS selector broadly:

```css
/* WRONG — also hides the page number on every chapter-opening page */
.pagedjs_page.chapter-open .pagedjs_margin-top-left,
.pagedjs_page.chapter-open .pagedjs_margin-top-right,
.pagedjs_page.chapter-open .pagedjs_margin-bottom-left,
.pagedjs_page.chapter-open .pagedjs_margin-bottom-right {
  display: none;
}
```

Only target the **top** margin boxes. The bottom margin box is where the page
number folio lives (via `@bottom-center` or similar) — hiding it removes the
page number specifically from every chapter-opening page, which is easy to
miss because those pages still look fine in isolation; the gap only shows up
when flipping through the whole PDF.

## Chapters ending with an orphaned single line on an otherwise empty page

If a chapter's closing line lands alone on a mostly blank page right before
the next chapter's forced page break, the usual cause is a chapter-opening
element (like `.chapter-kicker`) with a large `margin-top` (e.g. `1.4in`)
pushing the title down toward vertical center instead of near the page's top
margin. That wastes 2-4 lines of usable space on every single chapter, which
increases the odds of a short trailing paragraph spilling onto its own page.
Fix: reduce that margin-top substantially (e.g. to `0.2in`) — this is the
standard typographic mitigation and, in practice, resolves most cases without
touching the actual page margins.

## A short "fine print" line at the end of the book can push itself onto its own near-empty final page

Adding a short note (e.g. an AI-assistance disclosure, a colophon line) right
after the closing line of the last chapter can tip the page over its content
budget if the note wraps to two lines and/or has too much `margin-top`,
creating a trailing page that's otherwise empty. Fix: keep the note to one
line if possible, and use a small `margin-top` (`0.6em` or less) and a small
`font-size` (`~7.5-8pt`) rather than the default reading size — re-render and
check the actual last page after any text change here, since even a
same-length substitution can tip the balance differently depending on
character width.

## Always verify by reading the actual generated PDF, not just the reported page count

A stable page count across re-renders does not guarantee the content actually
looks right — verify visually (page by page) after every content or CSS
change: chapter openings starting cleanly, no orphaned lines, cover art with
no visible seam, TOC/cross-referenced page numbers matching the real output.

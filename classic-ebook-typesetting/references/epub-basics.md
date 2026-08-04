# EPUB basics — what's different from the PDF pipeline

EPUB and the Paged.js-rendered PDF share the same source content but are
fundamentally different formats. Read this before adapting `book.html` for
EPUB output.

## Reflowable, not fixed-layout

The PDF pipeline (`assets/render.js` + `assets/book.css`) produces a
**fixed-layout** document: every page is a specific size (6×9in), with fixed
margins and a page number printed at a fixed position. EPUB is
**reflowable**: the reading app (Apple Books, Kindle, etc.) decides font
size, margins, and where page breaks fall, based on the reader's device and
preferences. Concretely, this means none of the following concepts carry
over to EPUB and should not be ported into its CSS:

- `@page` rules (size, margin) — meaningless in a reflowable document.
- Page numbers / folios — the reading app manages pagination itself; there is
  no fixed "page 12" in the file.
- The cover-page-as-first-page trick (`.frontmatter.coverpage` with
  `object-fit: cover` filling the trim size exactly) — EPUB has its own
  dedicated cover mechanism (a `cover.xhtml` + manifest `cover-image`
  property), handled automatically by the generator library; don't try to
  reuse the PDF's cover markup.
- The `chapter-open` Paged.js Handler and its header-suppression CSS — that
  entire mechanism only exists because Paged.js renders a header/footer
  margin box per page; EPUB has no equivalent to suppress.

What *does* carry over cleanly: the actual prose content (`<p>`, `<em>`,
`<strong>`, `<dl class="glossary">`, etc.) — it's just semantic HTML either
way.

## Recommended approach: generate from the same `book.html`, don't duplicate content

Rather than retyping the book's text into a second source file, parse the
existing `book.html` and extract each `<section class="chapter">` into an
EPUB chapter (see `assets/build-epub.js`, which uses `cheerio` to do exactly
this). This keeps `book.html` as the single source of truth for the text —
both the PDF and the EPUB derive from it, and a future text edit only needs
to happen once.

Strip the Paged.js-specific chapter chrome (`.chapter-kicker`,
`.chapter-title`) before handing each section's HTML to the EPUB generator —
most EPUB-generation libraries render their own chapter heading from a
`title` field, so keeping the original `<h2 class="chapter-title">` around
too would duplicate it.

## Tooling: no LaTeX/Calibre/pandoc dependency assumed

Consistent with the PDF pipeline's "no Homebrew, no system-level ebook
tooling" constraint: use a pure-npm package rather than assuming `pandoc` or
Calibre's `ebook-convert` are installed. `@lesjoursfr/html-to-epub` (a
maintained fork of the older `epub-gen`) builds a complete, valid EPUB3 —
`mimetype`, `META-INF/container.xml`, per-chapter XHTML files, `content.opf`
manifest, `toc.ncx` (EPUB2-compat nav) and `toc.xhtml` (EPUB3 nav), cover
page — from a plain JS object: metadata, a cover image path, a shared CSS
string, and an array of `{title, data}` chapters. No hand-written XML needed.

```
npm install @lesjoursfr/html-to-epub cheerio
node build-epub.js
```

## Verifying the output

There's no visual "read the PDF page by page" equivalent for EPUB in a
text-only environment. Instead, verify structurally:

```
unzip -l book.epub          # confirm expected files: mimetype, content.opf,
                             # toc.ncx, toc.xhtml, cover.xhtml, cover.jpg,
                             # and one XHTML file per chapter in the right order
unzip -p book.epub OEBPS/<n>_<slug>.xhtml   # spot-check chapter content/order
```

Confirm: the chapter count and order match the intended table of contents,
the cover image is present and referenced, and glossary/reference sections
(if any) still render as `<dl>`/`<dt>`/`<dd>` rather than being flattened.

## Cover image reuse

The EPUB cover should be the same 2:3 illustrated cover generated for the PDF
(see the sibling `references/cover-generation.md`) — pass its file path
directly as the `cover` option; the generator handles embedding it and
wiring up the manifest's cover metadata. No separate cover asset is needed
for EPUB specifically.

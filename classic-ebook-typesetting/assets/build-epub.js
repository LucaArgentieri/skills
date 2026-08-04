// Generic EPUB builder for the classic-ebook-typesetting skill.
//
// Converts the same book.html used for the PDF pipeline into a reflowable
// EPUB3, by extracting each <section class="chapter"> and handing its
// content to @lesjoursfr/html-to-epub. See references/epub-basics.md for
// why EPUB needs a different (much simpler) CSS than the PDF's book.css,
// and for what this script deliberately does NOT try to reuse from it.
//
// Prerequisites: npm install @lesjoursfr/html-to-epub cheerio
// Edit the constants below, then run: node build-epub.js

const TITLE = 'Book Title';
const AUTHOR = 'Author Name';
const DESCRIPTION = 'One or two sentences describing the book.';
const HTML_FILE = 'book.html';
const COVER_IMAGE = 'cover-assets/cover-fullpage.jpg'; // reuse the 2:3 PDF cover
const OUTPUT_EPUB = 'book.epub';

const path = require('path');
const fs = require('fs');
const cheerio = require('cheerio');
const Epub = require('@lesjoursfr/html-to-epub').EPub;

const $ = cheerio.load(fs.readFileSync(path.join(__dirname, HTML_FILE), 'utf8'));

const content = [];

$('section.chapter').each((_, el) => {
  const $section = $(el);
  const title = $section.find('.chapter-title').first().text().trim();

  // Drop the Paged.js-only chrome (kicker label, title element) — the EPUB
  // generator renders its own <h1> from `title` below. Everything else
  // (paragraphs, <dl>, <em>/<strong>, etc.) is plain semantic HTML and
  // carries over to EPUB readers as-is.
  $section.find('.chapter-kicker, .chapter-title').remove();

  content.push({ title, data: $section.html().trim() });
});

const epub = new Epub(
  {
    title: TITLE,
    author: AUTHOR,
    description: DESCRIPTION,
    cover: path.join(__dirname, COVER_IMAGE),
    tocTitle: 'Contents',
    appendChapterTitles: true,
    // Minimal reflow-appropriate CSS — no @page, no fixed trim size, no
    // page numbers (none of those concepts exist in EPUB; the reading app
    // owns pagination). Keep only typography.
    css: `
      body { font-family: 'Georgia', 'EB Garamond', serif; line-height: 1.5; }
      h1 { font-weight: 500; }
      p { text-align: justify; margin: 0 0 0.9em 0; text-indent: 0; }
      em { font-style: italic; }
      strong { font-weight: 600; }
      dl.glossary dt { font-weight: 600; font-style: italic; margin-top: 0.9em; }
      dl.glossary dd { margin: 0.1em 0 0 0; }
    `,
    content,
  },
  path.join(__dirname, OUTPUT_EPUB),
);

epub
  .render()
  .then(() => console.log('EPUB written:', OUTPUT_EPUB))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

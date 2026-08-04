---
name: gumroad-listing
description: This skill should be used when the user asks to "prepare a Gumroad listing", "write a Gumroad product description", "prepara la scheda Gumroad", "che categoria/tag uso su Gumroad", "set up a Gumroad receipt", or otherwise needs help drafting the text and asset requirements for a Gumroad product page (description, URL slug, category, tags, cover image formats, receipt button text / custom message) for a digital product such as an ebook.
---

# Gumroad listing preparation

Draft the text content and asset checklist for a Gumroad product listing. This
skill covers copy (description, summary), discovery metadata (category,
tags, URL slug), image requirements, and receipt customization — it does not
touch the Gumroad site itself (there is no API/browser access assumed here);
produce ready-to-paste text and a list of files to upload, and hand them to
the user to enter manually.

## Description structure

Write the description as continuous prose with clear paragraph breaks — no
horizontal-rule separators (`---`), since those don't paste cleanly into
Gumroad's editor and the user will want to copy the block as-is. Structure:

1. **Hook** (1-2 sentences) — the problem/desire the product addresses, in the
   reader's own words, not marketing language.
2. **What it is** (1 sentence) — name the product and its core promise.
3. **What's inside** — a concrete list of what the reader gets (chapters,
   modules, features), specific enough to set accurate expectations. Bullet
   points are fine here even though the rest is prose.
4. **Format/logistics** (1 short line) — file type, length/page count, any
   notable production detail (e.g. typography, resolution) if it's genuinely a
   selling point.

Keep total length short enough to read in under a minute — a Gumroad listing
page is a quick-decision context, not a landing page with room for a full
sales letter.

## Category

Gumroad's category taxonomy (top-level, as of recent versions) includes:
`3D`, `Audio`, `Business & Money`, `Comics & Graphic Novels`, `Design`,
`Drawing & Painting`, `Education`, `Fiction Books`, `Films`, `Gaming`,
`Music & Sound Design`, `Photography`, `Self Improvement`,
`Software Development`, `Writing & Publishing`, `Other`.

For a nonfiction/explainer ebook, `Education` is usually the best fit. If the
framing leans more toward personal growth/motivation than technical content,
`Self Improvement` is a reasonable alternative — pick based on how the
description itself is framed, not the topic alone. `Writing & Publishing` fits
better for craft-of-writing content, not content that merely happens to be a
book. See `references/gumroad-fields.md` if a more unusual category is needed.

## Tags

Suggest 5-8 specific, on-topic tags — not a maximal list. Favor: the exact
subject matter (e.g. `ai`, `machine learning`), the format (`ebook`,
`nonfiction`), and terms a buyer would actually search (e.g. `beginners
guide`, `llm`, specific named concepts covered). Avoid generic filler tags
that add noise without adding discoverability.

## URL slug

Gumroad product URLs follow `gumroad.com/l/<slug>`. Recommend a short,
readable slug derived from the title (lowercase, hyphen-separated, no stop
words if it stays clear without them) — e.g. a book titled "It Is Never Too
Late to Understand AI" → `never-too-late-ai`, not a long literal transcription
of the full title.

## Cover image formats

Prepare (or point to, if already generated with the
`classic-ebook-typesetting` skill's cover-generation reference) at least:

- A **2:3 book-cover-style image** (e.g. 1600×2400px) for the primary product
  cover, matching a typical ebook trim size.
- A **1:1 square** version (e.g. 1600×1600px) for contexts that crop to
  square thumbnails.
- A **16:9 landscape** version, **at least 1280×720px**, for wider preview
  contexts.

Reuse one design across all three rather than stretching a single image —
each aspect ratio needs its own composition (see the sibling skill's
`references/cover-generation.md` for the layout pattern and the
canvas-whitening technique that keeps illustrated covers seam-free).

## Receipt customization

Two optional fields under the product's Receipt settings:

- **Button text** — max 26 characters. Default is a generic "Download"-style
  label; a more specific label (e.g. "Download the ebook", "Get your PDF")
  reads better than the default at negligible cost.
- **Custom message** — max 500 characters, shown in the receipt email buyers
  get after purchase. Write it as a short, warm note: thank them, point to
  where to start (e.g. "start with the Introduction"), and invite a
  review/reply — this is a good place for a light call-to-action since the
  buyer has already converted.

Keep both genuinely short — the char limits are hard caps, not targets to
fill.

## Additional resources

- `references/gumroad-fields.md` — fuller field-by-field reference (complete
  category list, additional taxonomy notes) for cases needing more than the
  summary above.

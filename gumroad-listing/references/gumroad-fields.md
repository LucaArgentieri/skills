# Gumroad listing fields — detailed reference

## Category taxonomy (top-level)

- `3D`
- `Audio`
- `Business & Money`
- `Comics & Graphic Novels`
- `Design`
- `Drawing & Painting`
- `Education`
- `Fiction Books`
- `Films`
- `Gaming`
- `Music & Sound Design`
- `Photography`
- `Self Improvement`
- `Software Development`
- `Writing & Publishing`
- `Other`

Each top-level category has subcategories in the actual Gumroad product
editor; the top-level choice matters most for discovery/browse pages, so
prioritize getting that right over hunting for the perfect subcategory.

### Choosing between the common nonfiction-ebook candidates

| Category | Best fit when... |
|---|---|
| `Education` | The product primarily teaches a concept/skill, framed neutrally/informatively (most explainer or how-it-works ebooks). |
| `Self Improvement` | The framing emphasizes personal growth, motivation, or "you can do this" — the topic is secondary to the transformation promised. |
| `Writing & Publishing` | The subject matter is itself about writing/publishing/creative craft, not just delivered as a book. |
| `Business & Money` | The content is specifically about business strategy, entrepreneurship, or personal finance. |
| `Fiction Books` | Only for actual fiction — never for nonfiction/explainer content even if narrative in style. |

## URL slug

- Format: `gumroad.com/l/<slug>`.
- Lowercase, hyphen-separated, no spaces or punctuation.
- Prefer 2-4 meaningful words over a literal full-title transcription.
- Check it reads sensibly on its own (it's public and gets shared as a raw
  link) — avoid abbreviations that only make sense with the title in view.

## Tags

- No strict enforced limit observed in practice, but more than ~8 tags adds
  noise rather than reach — favor precision.
- Include: exact subject-matter terms, format (`ebook`), and a couple of
  buyer-intent search phrases (e.g. `beginners guide`).
- Avoid duplicating the category name as a tag (adds nothing) and avoid overly
  broad single-word tags that put the listing in a huge, uncompetitive pool
  (e.g. `technology` alone) unless paired with more specific tags too.

## Receipt fields — exact limits

- **Button text**: 26 characters max, shown on the download button on the
  receipt page/email.
- **Custom message**: 500 characters max, plain text, shown in the purchase
  receipt email body.

Both fields are optional; leaving them blank falls back to Gumroad's default
generic copy.

## Cover image guidance

- Gumroad displays a primary cover image plus an optional gallery of
  additional images on the product page.
- No single mandated aspect ratio is enforced, but a **2:3** cover
  reads naturally as a book cover, a **1:1** version covers square-crop
  thumbnail contexts, and a **16:9 landscape (≥1280×720px)** covers wider
  preview/share contexts (e.g. social link previews).
- Export all sizes from one design rather than stretching a single asset —
  see the `classic-ebook-typesetting` skill's `references/cover-generation.md`
  for the layout + technique used to do this cleanly for illustrated covers.

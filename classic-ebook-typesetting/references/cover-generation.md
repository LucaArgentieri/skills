# Cover generation: canvas whitening + multi-aspect-ratio export

## The problem: a visible seam/box around line-art illustrations

When placing a user-supplied line-art illustration (e.g. an ink-drawing style
image with a nominally "white" background) onto a page background of a
different flat color — or even the *same* nominal color — a faint rectangular
seam is often still visible around the image. This happens because:

- The image's own background usually isn't perfectly uniform: JPEG
  compression artifacts, a paper-texture filter, or slight anti-aliasing at
  the edges all introduce small (single-digit) RGB variation across what
  looks like "white" to the eye.
- Matching the page's flat background color to a *sampled average* of the
  image's corner pixels reduces the seam but rarely eliminates it, because
  the mismatch isn't uniform across the image edge.
- `mix-blend-mode: multiply` on the `<img>` helps (white areas become
  optically transparent against whatever is behind them) but still leaves a
  faint edge if the image's "white" isn't exactly 255,255,255 — multiplying a
  near-white value by a near-white background still isn't identical to the
  background alone.

## The fix: clip near-white pixels to true white via canvas, then use a pure-white page background

Draw the image to an off-screen `<canvas>`, read its pixel data, and clip any
pixel whose R, G, and B all exceed a threshold (e.g. 234) to pure white
(255,255,255). This removes the paper-texture noise entirely, producing a
truly uniform white background that then blends seamlessly into a page
background that is *also* pure white (`#ffffff`) — no seam is possible because
both sides of the boundary are now identical.

```html
<canvas id="illust"></canvas>
<script>
  const img = new Image();
  img.onload = () => {
    const canvas = document.getElementById('illust');
    canvas.width = img.naturalWidth;
    canvas.height = img.naturalHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0);

    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    const threshold = 234; // tune per source image if needed
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i], g = data[i + 1], b = data[i + 2];
      if (r > threshold && g > threshold && b > threshold) {
        data[i] = 255; data[i + 1] = 255; data[i + 2] = 255;
      }
    }
    ctx.putImageData(imageData, 0, 0);
    window.__coverReady = true; // signal to the renderer that it's safe to screenshot
  };
  img.src = 'cover-assets/illustration.jpg';
</script>
```

Set the page/body background to `#ffffff` (not an off-white/cream tone) —
even a very close cream match still leaves a faint but visible rectangle,
because the source image's "white" is itself not perfectly uniform. Pure
white eliminates the problem structurally rather than by approximation.

If a design genuinely calls for a cream/off-white page (not pure white), this
same clipping technique still helps a lot but won't be 100% seamless —
consider it a "good enough" fallback, not the primary recommendation.

## Sizing and layout for a single design across formats

Reuse the same title/subtitle markup and the same whitened-canvas illustration
across differently-proportioned cover variants by writing one small HTML file
per aspect ratio rather than trying to force one responsive layout to cover
all of them — the compositions genuinely differ (stacked vs. side-by-side):

- **2:3 (book cover)** — e.g. 1600×2400px. Matches a 6×9in (or any 2:3) trim
  size exactly, so it can be embedded directly as the ebook's own first page
  with no cropping. Layout: illustration centered, title block below it,
  generous vertical whitespace.
- **1:1 (square)** — e.g. 1600×1600px. Same stacked layout, compressed
  vertically (smaller illustration, tighter spacing) since there's much less
  height to work with relative to width.
- **16:9 landscape, ≥1280×720px** — e.g. 1600×900px. Needs a genuinely
  different layout: illustration on one side, title/subtitle block vertically
  centered on the other side, since there isn't room to stack everything
  vertically and stay legible.

Render all variants with `assets/render-cover.js`, which takes a list of
`{html, out, width, height}` entries and screenshots each at its own
viewport size in one script run (see the `VARIANTS` array at the top of that
file).

## Sourcing/preparing the illustration itself

If the user supplies an illustration with a visibly non-white or textured
background and asks for a "white background" version, that's a separate
image-generation/editing step (outside this skill's scope) — get the
corrected asset first, then apply the canvas-whitening technique above to
clean up any *remaining* near-white noise. The canvas technique is a finishing
pass, not a substitute for starting with a reasonably clean source image.

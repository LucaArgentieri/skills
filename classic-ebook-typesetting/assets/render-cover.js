// Generic Playwright screenshot renderer for book-cover HTML pages, for the
// classic-ebook-typesetting skill. Renders one or more {html, out, width,
// height} variants — e.g. a 2:3 book cover, a 1:1 square, and a 16:9
// landscape crop — from separate small HTML files that share the same
// illustration/title markup but different layout.
//
// Each cover HTML file should apply the canvas-whitening technique from
// references/cover-generation.md to the illustration image and set
// `window.__coverReady = true` when the canvas has been painted, so this
// script knows when it's safe to screenshot.
//
// Prerequisites: npm install playwright; npx playwright install chromium
// Run: node render-cover.js

const VARIANTS = [
  { html: 'cover.html', out: 'cover.jpg', width: 1600, height: 2400 }, // 2:3 trim-size cover
  // { html: 'cover-square.html', out: 'cover-square.jpg', width: 1600, height: 1600 },
  // { html: 'cover-landscape.html', out: 'cover-landscape.jpg', width: 1600, height: 900 },
];

const PORT = 8793;

const { chromium } = require('playwright');
const path = require('path');
const http = require('http');
const fs = require('fs');

const MIME = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
  '.ttf': 'font/ttf', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
};

function startServer(root, port) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const filePath = path.join(root, decodeURIComponent(req.url.split('?')[0]));
      fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('not found'); return; }
        const ext = path.extname(filePath);
        res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
        res.end(data);
      });
    });
    server.listen(port, () => resolve(server));
  });
}

(async () => {
  const server = await startServer(__dirname, PORT);
  const browser = await chromium.launch();

  for (const v of VARIANTS) {
    const page = await browser.newPage({ viewport: { width: v.width, height: v.height } });
    await page.goto(`http://localhost:${PORT}/${v.html}`, { waitUntil: 'networkidle' });
    await page.waitForFunction('window.__coverReady === true', undefined, { timeout: 30000 });
    await page.screenshot({
      path: path.resolve(__dirname, v.out),
      type: 'jpeg',
      quality: 95,
    });
    await page.close();
    console.log(`Written ${v.out} (${v.width}x${v.height})`);
  }

  await browser.close();
  server.close();
})().catch((err) => {
  console.error(err);
  process.exit(1);
});

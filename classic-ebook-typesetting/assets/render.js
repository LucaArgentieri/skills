// Generic Paged.js -> PDF renderer for the classic-ebook-typesetting skill.
//
// Prerequisites in the project folder this script lives in:
//   npm install playwright pagedjs
//   npx playwright install chromium
//
// The companion book.html must end with (before </body>):
//
//   <script>
//     window.PagedConfig = {
//       before: async () => {
//         class ChapterOpenHandler extends window.Paged.Handler {
//           afterPageLayout(pageElement) {
//             if (pageElement.querySelector('.chapter-kicker')) {
//               pageElement.classList.add('chapter-open');
//             }
//           }
//         }
//         window.Paged.registerHandlers(ChapterOpenHandler);
//       },
//       after: (flow) => { window.__pagedjsDone = true; }
//     };
//   </script>
//   <script src="node_modules/pagedjs/dist/paged.polyfill.js"></script>
//
// Edit the three constants below, then run: node render.js

const HTML_FILE = 'book.html';
const OUTPUT_PDF = 'book.pdf';
const PORT = 8791;

const { chromium } = require('playwright');
const path = require('path');
const http = require('http');
const fs = require('fs');

const MIME = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
  '.ttf': 'font/ttf', '.woff': 'font/woff', '.woff2': 'font/woff2',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
};

// Paged.js fetches its own assets (fonts, CSS) via XHR, which Chromium
// blocks under file:// due to CORS. Always serve over http://localhost.
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
  const page = await browser.newPage();
  page.on('console', (msg) => console.log('PAGE:', msg.type(), msg.text()));
  page.on('pageerror', (err) => console.log('PAGEERROR:', err));

  await page.goto(`http://localhost:${PORT}/${HTML_FILE}`, { waitUntil: 'load' });

  // page.waitForFunction(fn, arg, options) — the second argument is `arg`,
  // NOT options. Pass `undefined` explicitly so the timeout in the third
  // argument actually applies (a common mistake silently keeps the default
  // 30s timeout instead of the intended longer one).
  await page.waitForFunction('window.__pagedjsDone === true', undefined, { timeout: 120000 });
  // give web fonts / layout a moment to settle after pagedjs reports done
  await page.waitForTimeout(500);

  const pageCount = await page.evaluate(() => document.querySelectorAll('.pagedjs_page').length);
  console.log('Paged.js rendered pages:', pageCount);

  await page.pdf({
    path: path.resolve(__dirname, OUTPUT_PDF),
    printBackground: true,
    preferCSSPageSize: true,
  });

  await browser.close();
  server.close();
  console.log('PDF written:', OUTPUT_PDF);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});

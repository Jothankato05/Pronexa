// Renders the SVG app icon to the PNG sizes Android needs. Run: node scripts/make-icons.mjs
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');
import { readFileSync } from 'node:fs';

const svg = readFileSync(new URL('../public/icons/icon.svg', import.meta.url), 'utf8');
const browser = await chromium.launch();
const page = await browser.newPage();
async function shot(size, file, maskable = false) {
  await page.setViewportSize({ width: size, height: size });
  const inner = maskable
    ? `<div style="width:${size}px;height:${size}px;background:#07101c;display:grid;place-items:center"><div style="width:${size * 0.8}px;height:${size * 0.8}px">${svg.replace('rx="116"', 'rx="0"')}</div></div>`
    : `<div style="width:${size}px;height:${size}px">${svg}</div>`;
  await page.setContent(`<html><body style="margin:0;background:transparent">${inner}<style>svg{width:100%;height:100%;display:block}</style></body></html>`);
  await page.screenshot({ path: new URL(`../public/icons/${file}`, import.meta.url).pathname, omitBackground: !maskable });
}
await shot(192, 'icon-192.png');
await shot(512, 'icon-512.png');
await shot(512, 'icon-maskable-512.png', true);
await browser.close();
console.log('icons written');

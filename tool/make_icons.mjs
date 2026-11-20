// Dev tool: renders the flat navy Pronexa launcher icons and launch mark into the
// Android resources. Needs Node 22 and Playwright (Chromium) on the machine:
//   node tool/make_icons.mjs
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

const RES = new URL('../android/app/src/main/res/', import.meta.url).pathname;
const NAVY = '#20296B';
const MARK = `<svg viewBox="0 0 170 124" xmlns="http://www.w3.org/2000/svg"><path d="M2 122C2 60 40 12 118 2c4 62-34 112-116 120Z" fill="#FFFFFF"/><rect x="122" y="74" width="47" height="49" rx="6" fill="#FFFFFF"/></svg>`;
const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };

const browser = await chromium.launch();
const page = await browser.newPage();
async function render(size, html, path) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<html><body style="margin:0;background:transparent">${html}<style>svg{display:block;width:100%}</style></body></html>`);
  await page.screenshot({ path, omitBackground: true });
}
const tile = (s, radius, markShare) =>
  `<div style="width:${s}px;height:${s}px;border-radius:${radius};background:${NAVY};display:grid;place-items:center"><div style="width:${s * markShare}px">${MARK}</div></div>`;
for (const [d, k] of Object.entries(dens)) {
  const legacy = Math.round(48 * k), fg = Math.round(108 * k);
  await render(legacy, tile(legacy, '22%', 0.56), `${RES}mipmap-${d}/ic_launcher.png`);
  await render(legacy, tile(legacy, '50%', 0.5), `${RES}mipmap-${d}/ic_launcher_round.png`);
  // Adaptive foreground: the mark inside the 66/108 safe zone, transparent around it.
  await render(fg, `<div style="width:${fg}px;height:${fg}px;display:grid;place-items:center"><div style="width:${fg * 0.42}px">${MARK}</div></div>`, `${RES}mipmap-${d}/ic_launcher_foreground.png`);
  await render(Math.round(96 * k), `<div style="width:${Math.round(96 * k)}px;height:${Math.round(96 * k)}px;display:grid;place-items:center"><div style="width:${Math.round(96 * k) * 0.8}px">${MARK}</div></div>`, `${RES}mipmap-${d}/launch_mark.png`);
}
await browser.close();
console.log('icons written');

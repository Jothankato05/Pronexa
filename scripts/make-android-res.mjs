// Renders Pronexa launcher icons and splash screens for the Android app.
// Run after `npx cap add android`: node scripts/make-android-res.mjs
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
const { chromium } = createRequire(import.meta.url)('playwright');

const RES = new URL('../android/app/src/main/res/', import.meta.url).pathname;
const icon = readFileSync(new URL('../public/icons/icon.svg', import.meta.url), 'utf8');
const MARK = `<svg viewBox="0 0 170 124" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#e4efe0"/></linearGradient></defs><path d="M2 122C2 60 40 12 118 2c4 62-34 112-116 120Z" fill="url(#g)"/><rect x="122" y="74" width="47" height="49" rx="4" fill="#d9a441"/></svg>`;
const BG = 'linear-gradient(180deg,#5a9a68 -10%,#2e6340 45%,#1f4a33 100%)';

const browser = await chromium.launch();
const page = await browser.newPage();
async function render(w, h, html, path, transparent = false) {
  await page.setViewportSize({ width: w, height: h });
  await page.setContent(`<html><body style="margin:0;width:${w}px;height:${h}px;overflow:hidden;background:transparent">${html}<style>svg{display:block}</style></body></html>`);
  await page.screenshot({ path, omitBackground: transparent });
}
const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, k] of Object.entries(dens)) {
  const legacy = Math.round(48 * k), fg = Math.round(108 * k);
  const full = `<div style="width:${legacy}px;height:${legacy}px">${icon.replace('<svg ', `<svg width="${legacy}" height="${legacy}" `)}</div>`;
  await render(legacy, legacy, full, `${RES}mipmap-${d}/ic_launcher.png`, true);
  const round = `<div style="width:${legacy}px;height:${legacy}px;border-radius:50%;overflow:hidden;background:${BG};display:grid;place-items:center"><div style="width:${legacy * 0.5}px">${MARK}</div></div>`;
  await render(legacy, legacy, round, `${RES}mipmap-${d}/ic_launcher_round.png`, true);
  // Adaptive foreground: keep the mark inside the 66/108 safe zone.
  const fore = `<div style="width:${fg}px;height:${fg}px;display:grid;place-items:center"><div style="width:${fg * 0.46}px">${MARK}</div></div>`;
  await render(fg, fg, fore, `${RES}mipmap-${d}/ic_launcher_foreground.png`, true);
}
const splash = (w, h) => `<div style="width:${w}px;height:${h}px;background:${BG};display:grid;place-items:center"><div style="width:${Math.min(w, h) * 0.28}px">${MARK}</div></div>`;
const sizes = { 'drawable': [480, 320], 'drawable-land-mdpi': [480, 320], 'drawable-land-hdpi': [800, 480], 'drawable-land-xhdpi': [1280, 720], 'drawable-land-xxhdpi': [1600, 960], 'drawable-land-xxxhdpi': [1920, 1280],
  'drawable-port-mdpi': [320, 480], 'drawable-port-hdpi': [480, 800], 'drawable-port-xhdpi': [720, 1280], 'drawable-port-xxhdpi': [960, 1600], 'drawable-port-xxxhdpi': [1280, 1920] };
for (const [dir, [w, h]] of Object.entries(sizes)) await render(w, h, splash(w, h), `${RES}${dir}/splash.png`);
await browser.close();
console.log('android resources written');

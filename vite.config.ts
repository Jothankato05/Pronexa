import type { Plugin } from 'vite';
import { defineConfig } from 'vitest/config';
import preact from '@preact/preset-vite';
import { readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

/**
 * Generates dist/sw.js with a precache list of the built app shell.
 * Fonts are cached at runtime instead, so low-data mode never downloads them.
 */
function serviceWorker(): Plugin {
  return {
    name: 'pronexa-sw',
    apply: 'build',
    generateBundle(_, bundle) {
      const fromBundle = Object.keys(bundle).filter((f) => !f.endsWith('.woff2') && !f.endsWith('.map'));
      const publicDir = join(process.cwd(), 'public');
      const walk = (d: string): string[] => readdirSync(d).flatMap((n) => (statSync(join(d, n)).isDirectory() ? walk(join(d, n)) : [relative(publicDir, join(d, n))]));
      const fromPublic = walk(publicDir).map((p) => p.split('\\').join('/'));
      const files = ['./', ...new Set([...fromBundle, ...fromPublic])].map((f) => (f === './' ? f : `./${f}`));
      const version = Date.now().toString(36);
      const src = `/* Pronexa service worker (generated) */
const VERSION = '${version}';
const SHELL = 'pronexa-shell-' + VERSION;
const RUNTIME = 'pronexa-runtime';
const PRECACHE = ${JSON.stringify(files)};

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(SHELL).then((c) => c.addAll(PRECACHE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k.startsWith('pronexa-shell-') && k !== SHELL).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return; // never cache AI or sync calls

  // App navigation: serve the cached shell (works offline), refresh in the background.
  if (req.mode === 'navigate') {
    e.respondWith(
      caches.match('./', { ignoreSearch: true }).then((cached) => {
        const network = fetch(req).then((res) => { caches.open(SHELL).then((c) => c.put('./', res.clone())); return res; }).catch(() => cached);
        return cached || network;
      })
    );
    return;
  }

  // Everything else: cache first, then network (fonts land in the runtime cache on first use).
  e.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      if (res.ok && (url.pathname.endsWith('.woff2') || url.pathname.includes('/assets/'))) {
        const copy = res.clone();
        caches.open(RUNTIME).then((c) => c.put(req, copy));
      }
      return res;
    }))
  );
});
`;
      this.emitFile({ type: 'asset', fileName: 'sw.js', source: src });
    },
  };
}

export default defineConfig({
  base: './',
  plugins: [preact(), serviceWorker()],
  build: {
    target: 'es2019',
    cssCodeSplit: false,
    assetsInlineLimit: 0,
    reportCompressedSize: true,
  },
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
  },
});

// Pronexa's service worker: makes the web app work offline.
// - The app itself is stored when it is installed (precache.json, written by
//   tool/web/finalize.py) and updated when a new version is published.
// - The photo recogniser's large files are stored only when the student
//   downloads them (web/lens.js); this worker just serves them.
// - Pages get cross-origin isolation headers so the recogniser can use
//   several threads where the browser supports it.
'use strict';
const VERSION = '__PRONEXA_VERSION__';
const SHELL = 'pronexa-shell-' + VERSION;
const MODELS = 'pronexa-models-v1';

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const list = await (await fetch('precache.json', { cache: 'no-store' })).json();
    const cache = await caches.open(SHELL);
    await cache.addAll(list.map((p) => new Request(p, { cache: 'reload' })));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('pronexa-shell-') && key !== SHELL) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

// The page sends the files it loaded (for example the graphics engine its
// browser chose) so they are kept for offline use too.
self.addEventListener('message', (event) => {
  const urls = event.data && event.data.cacheUrls;
  if (!Array.isArray(urls)) return;
  event.waitUntil((async () => {
    const cache = await caches.open(SHELL);
    for (const u of urls) {
      try {
        const url = new URL(u);
        if (url.origin !== self.location.origin || isLarge(url) || (await cache.match(url.href, { ignoreSearch: true }))) continue;
        const res = await fetch(url.href);
        if (res.ok) await cache.put(url.href, res);
      } catch (_) {
        // Best effort.
      }
    }
  })());
});

function isLarge(url) {
  return url.pathname.endsWith('.onnx') || (url.pathname.includes('/ort/') && !url.pathname.endsWith('ort.wasm.min.js'));
}

function isolate(res) {
  if (!res || res.type === 'opaque' || res.status === 0) return res;
  const headers = new Headers(res.headers);
  headers.set('Cross-Origin-Embedder-Policy', 'credentialless');
  headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  if (req.mode === 'navigate') {
    // Network first, so a new version shows up; the stored page offline.
    event.respondWith((async () => {
      try {
        return isolate(await fetch(req));
      } catch (_) {
        const cache = await caches.open(SHELL);
        return isolate(await cache.match(new URL('index.html', self.registration.scope).href));
      }
    })());
    return;
  }

  event.respondWith((async () => {
    const stored = await (await caches.open(MODELS)).match(url.href);
    if (stored) return isolate(stored);
    if (isLarge(url)) return isolate(await fetch(req));
    const cache = await caches.open(SHELL);
    const hit = await cache.match(req, { ignoreSearch: true });
    if (hit) return isolate(hit);
    const res = await fetch(req);
    if (res.ok && res.type === 'basic') await cache.put(req, res.clone());
    return isolate(res);
  })());
});

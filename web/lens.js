// Pronexa's food recogniser in the browser: the same ONNX model as the
// Android and iPhone apps, run with ONNX Runtime Web (web/ort, fetched and
// checked at build time by tool/web/build.sh). Called from lib/ai/lens_web.dart.
//
// Nothing is downloaded until the student asks for it. The model and engine
// are then kept in Cache Storage, so photos are recognised offline, and the
// photo itself never leaves the device.
(function () {
  'use strict';
  var CACHE = 'pronexa-models-v1';
  var ORT_DIR = 'ort/';
  var ENGINE = ['ort-wasm-simd-threaded.wasm', 'ort-wasm-simd-threaded.mjs'];
  // Filled in by tool/web/finalize.py from the built files.
  var MODEL_BYTES = Number('__MODEL_BYTES__') || 80769637;
  var ENGINE_BYTES = Number('__ENGINE_BYTES__') || 14873590;
  var SIZE = 384;

  var abs = function (p) { return new URL(p, document.baseURI).href; };
  var session = null;
  var sessionPromise = null;
  var ortPromise = null;

  function loadOrt() {
    if (self.ort) return Promise.resolve();
    if (!ortPromise) {
      ortPromise = new Promise(function (resolve, reject) {
        var s = document.createElement('script');
        s.src = abs(ORT_DIR + 'ort.wasm.min.js');
        s.onload = resolve;
        s.onerror = function () { ortPromise = null; reject(new Error('Could not load the recogniser engine')); };
        document.head.appendChild(s);
      });
    }
    return ortPromise;
  }

  async function cached(url) {
    if (!('caches' in self)) return undefined;
    var c = await caches.open(CACHE);
    return c.match(url);
  }

  function files(modelUrl) {
    return [abs(modelUrl)].concat(ENGINE.map(function (f) { return abs(ORT_DIR + f); }));
  }

  async function isDownloaded(modelUrl) {
    var list = files(modelUrl);
    for (var i = 0; i < list.length; i++) {
      if (!(await cached(list[i]))) return false;
    }
    return true;
  }

  // Streams one file, reporting bytes as they arrive, and stores it.
  async function fetchInto(url, onBytes) {
    var res = await fetch(url, { cache: 'no-store' });
    if (!res.ok || !res.body) throw new Error('Download failed: ' + res.status);
    var reader = res.body.getReader();
    var parts = [];
    for (;;) {
      var r = await reader.read();
      if (r.done) break;
      parts.push(r.value);
      onBytes(r.value.byteLength);
    }
    var type = res.headers.get('content-type') || 'application/octet-stream';
    var blob = new Blob(parts, { type: type });
    if ('caches' in self) {
      var c = await caches.open(CACHE);
      await c.put(url, new Response(blob, { headers: { 'content-type': type } }));
    }
  }

  async function download(modelUrl, onProgress) {
    var total = MODEL_BYTES + ENGINE_BYTES;
    var got = 0;
    var list = files(modelUrl);
    onProgress(0);
    for (var i = 0; i < list.length; i++) {
      if (await cached(list[i])) {
        got += i === 0 ? MODEL_BYTES : 0;
        continue;
      }
      await fetchInto(list[i], function (n) {
        got += n;
        onProgress(Math.min(0.99, got / total));
      });
    }
    onProgress(1);
  }

  async function getSession(modelUrl) {
    if (session) return session;
    if (!sessionPromise) {
      sessionPromise = (async function () {
        await loadOrt();
        self.ort.env.wasm.wasmPaths = abs(ORT_DIR);
        // Threads need a cross-origin isolated page (web/sw.js adds the headers).
        self.ort.env.wasm.numThreads = self.crossOriginIsolated ? Math.max(1, Math.min(4, navigator.hardwareConcurrency || 2)) : 1;
        var hit = await cached(abs(modelUrl));
        var model = hit ? new Uint8Array(await hit.arrayBuffer()) : abs(modelUrl);
        session = await self.ort.InferenceSession.create(model, { executionProviders: ['wasm'], graphOptimizationLevel: 'all' });
        return session;
      })().catch(function (e) { sessionPromise = null; throw e; });
    }
    return sessionPromise;
  }

  self.pronexaLens = {
    downloadBytes: MODEL_BYTES + ENGINE_BYTES,
    isDownloaded: isDownloaded,
    download: download,
    prepare: function (modelUrl) { return getSession(modelUrl).then(function () { return null; }); },
    // image: 384 x 384 RGB values in 0..1, row by row (NHWC), from lensInput().
    recognise: async function (modelUrl, image) {
      var s = await getSession(modelUrl);
      var out = await s.run({ image: new self.ort.Tensor('float32', image, [1, SIZE, SIZE, 3]) });
      return { scores: out.scores.data, features: out.features.data };
    },
  };
})();

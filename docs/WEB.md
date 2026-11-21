# Pronexa on the web (PWA)

The same Flutter app runs in the browser and installs like an app ("Add to Home screen" on Android, "Share > Add to Home Screen" on iPhone). Everything works offline after the first visit, and data stays in the browser on that device.

## What's different from the apps

- **Photo recognition is a one-time download, on request.** The Photo screen offers it ("Recognise foods in photos, about 96 MB, best on Wi-Fi"). Nothing is fetched until the student taps Download. The model and engine are then kept in the browser's storage, so photos are recognised offline and never leave the device. Students who skip it pick foods by hand, as before.
- The recogniser is the same model as the Android and iPhone apps, run with ONNX Runtime Web 1.31.1 (MIT). Checked in Chromium: the same numbers as the reference run (largest difference under 0.0001), about 0.4 s per photo with 4 threads.
- Photo memory, the meal reader, lessons, planner and everything else work the same. Data is stored in the browser (clearing site data deletes it).

## How it's built

- `web/`: the page, manifest and icons (`tool/make_icons.mjs`), `lens.js` (the recogniser in the browser) and `sw.js` (offline service worker).
- `lib/ai/lens_web.dart`: the web recogniser, picked automatically by `lib/ai/lens_platform.dart`.
- `tool/web/build.sh [base-href]`: fetches ONNX Runtime Web (pinned and checked against the npm registry's SHA-512), runs `flutter build web` with the graphics engine bundled (no CDN), then `tool/web/finalize.py` versions the service worker and lists the 5 MB of app files kept offline.

The service worker:
- keeps the app shell for offline use and picks up new versions when online;
- serves the photo recogniser's files from the browser's storage once downloaded;
- adds cross-origin isolation headers, so ONNX Runtime can use several threads.

## Publishing

The **Web app** workflow (`.github/workflows/web.yml`) builds the recogniser, runs the tests, builds the PWA and publishes it to GitHub Pages on every push to `main` that touches the app. One-time setup: in the repository's **Settings > Pages**, set **Source** to **GitHub Actions**. The app is then at `https://<owner>.github.io/<repo>/`.

Any static host works too: run `tool/web/build.sh /` and upload `build/web`. Serve it over HTTPS (service workers need it).

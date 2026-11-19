import { render } from 'preact';
import { App } from './app';
import { boot } from './lib/store';
import './styles/app.css';

render(<App />, document.getElementById('app')!);
void boot();

// Offline-first: cache the app shell so it opens with no connection.
// Inside the Android app (Capacitor) the files are already on the phone, so no service worker is needed.
const isNative = !!(window as unknown as { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor?.isNativePlatform?.();
if ('serviceWorker' in navigator && import.meta.env.PROD && !isNative) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch(() => {
      /* The app still works online without it. */
    });
  });
}

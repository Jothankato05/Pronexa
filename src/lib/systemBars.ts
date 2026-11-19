/**
 * Status-bar icon colour for the Android app: light icons over the green
 * headers, dark icons over the warm off-white screens. A no-op on the web.
 * Capacitor's core is only loaded inside the native app.
 */
type Tone = 'on-green' | 'on-light';
let last: Tone | null = null;

export function setBarTone(tone: Tone) {
  if (tone === last) return;
  last = tone;
  const cap = (window as unknown as { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor;
  if (!cap?.isNativePlatform?.()) return;
  import('@capacitor/core')
    .then(({ SystemBars, SystemBarsStyle }) => SystemBars.setStyle({ style: tone === 'on-green' ? SystemBarsStyle.Dark : SystemBarsStyle.Light }))
    .catch(() => { /* older shells: keep the default */ });
}

import type { ComponentType } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { Celebration, Skeleton, TabBar, Toast } from './components/ui';
import { current, type Route } from './lib/router';
import { celebrate, profile, ready, settings } from './lib/store';
import { Today } from './screens/Today';
import { setBarTone } from './lib/systemBars';

/**
 * Route-level code splitting keeps the first load small on low-end phones:
 * the shell and Today load first; other screens load on demand (and are
 * prefetched when the phone is idle, unless low-data mode is on).
 */
function lazy(loader: () => Promise<ComponentType>) {
  let Comp: ComponentType | null = null;
  let pending: Promise<void> | null = null;
  const load = () => (pending ??= loader().then((c) => { Comp = c; }));
  function Lazy() {
    const [, force] = useState(0);
    useEffect(() => { if (!Comp) void load().then(() => force((n) => n + 1)); }, []);
    return Comp ? <Comp /> : <ScreenSkeleton />;
  }
  Lazy.preload = load;
  return Lazy;
}

const Onboarding = lazy(() => import('./screens/Onboarding').then((m) => m.Onboarding));
const LogHome = lazy(() => import('./screens/LogHome').then((m) => m.LogHome));
const QuickPick = lazy(() => import('./screens/QuickPick').then((m) => m.QuickPick));
const PortionMode = lazy(() => import('./screens/PortionMode').then((m) => m.PortionMode));
const Describe = lazy(() => import('./screens/Describe').then((m) => m.Describe));
const Confirm = lazy(() => import('./screens/Confirm').then((m) => m.Confirm));
const Suggestions = lazy(() => import('./screens/Suggestions').then((m) => m.Suggestions));
const Learn = lazy(() => import('./screens/Learn').then((m) => m.Learn));
const ComingSoon = lazy(() => import('./screens/Learn').then((m) => m.ComingSoon));
const Settings = lazy(() => import('./screens/Settings').then((m) => m.Settings));

const SCREENS: Partial<Record<Route, ComponentType>> = {
  log: LogHome,
  'log/quick': QuickPick,
  'log/portion': PortionMode,
  'log/describe': Describe,
  'log/confirm': Confirm,
  'log/photo': ComingSoon,
  suggestions: Suggestions,
  learn: Learn,
  'learn/soon': ComingSoon,
  settings: Settings,
};

let prefetched = false;
function prefetchAll() {
  if (prefetched || settings.value.lowData) return;
  prefetched = true;
  const run = () => [LogHome, QuickPick, PortionMode, Confirm, Suggestions, Describe, Learn, Settings].forEach((c) => void c.preload());
  const ric = (window as unknown as { requestIdleCallback?: (cb: () => void) => void }).requestIdleCallback;
  ric ? ric(run) : setTimeout(run, 1500);
}

export function App() {
  const [party, setParty] = useState(false);
  useEffect(() => {
    if (celebrate.value > 0) setParty(true);
  }, [celebrate.value]);
  useEffect(() => {
    if (ready.value && profile.value) prefetchAll();
  }, [ready.value, !!profile.value]);

  const { route } = current.value;
  useEffect(() => {
    // Light status-bar icons over the green Today header; dark icons on the off-white screens.
    if (ready.value && profile.value) setBarTone(SCREENS[route] ? 'on-light' : 'on-green');
  }, [route, ready.value, !!profile.value]);

  if (!ready.value) return <ScreenSkeleton />;
  if (!profile.value) return <Onboarding />;

  const hideTabs = route === 'log/confirm' || route === 'settings';
  const Screen = SCREENS[route] ?? Today;

  return (
    <>
      <main class={`app${hideTabs ? ' no-tabs' : ''}`} key={route}><Screen /></main>
      {!hideTabs && <TabBar />}
      <Toast />
      {party && <Celebration onDone={() => setParty(false)} />}
    </>
  );
}

function ScreenSkeleton() {
  return (
    <div class="app" aria-busy="true" aria-label="Loading">
      <div class="topbar">
        <div class="grow stack" style={{ gap: '8px' }}><Skeleton h={24} w="60%" /><Skeleton h={14} w="40%" /></div>
      </div>
      <div class="stack">
        <Skeleton h={96} r={24} /><Skeleton h={96} r={24} /><Skeleton h={96} r={24} />
      </div>
    </div>
  );
}

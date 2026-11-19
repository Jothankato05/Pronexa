import { signal } from '@preact/signals';

export type Route =
  | 'today'
  | 'log'
  | 'log/quick'
  | 'log/portion'
  | 'log/describe'
  | 'log/confirm'
  | 'log/photo'
  | 'suggestions'
  | 'learn'
  | 'learn/soon'
  | 'settings';

const ROUTES: Route[] = ['today', 'log', 'log/quick', 'log/portion', 'log/describe', 'log/confirm', 'log/photo', 'suggestions', 'learn', 'learn/soon', 'settings'];

function parse(): { route: Route; param?: string } {
  const raw = (typeof location === 'undefined' ? '' : location.hash).replace(/^#\/?/, '');
  const [path, param] = raw.split('?');
  const route = (ROUTES as string[]).includes(path) ? (path as Route) : 'today';
  return { route, param };
}

export const current = signal(parse());

if (typeof window !== 'undefined') {
  window.addEventListener('hashchange', () => {
    current.value = parse();
    window.scrollTo({ top: 0 });
  });
}

export function go(route: Route, param?: string, opts: { replace?: boolean } = {}) {
  const hash = `#/${route}${param ? `?${param}` : ''}`;
  if (opts.replace) {
    history.replaceState(null, '', hash);
    current.value = parse();
    window.scrollTo({ top: 0 });
  } else {
    location.hash = hash;
  }
}

export function back(fallback: Route = 'today') {
  if (history.length > 1) history.back();
  else go(fallback);
}

export const tabOf = (r: Route): 'today' | 'log' | 'suggestions' | 'learn' | null =>
  r === 'settings' ? null : (r.split('/')[0] as 'today' | 'log' | 'suggestions' | 'learn');

import type { ComponentChildren } from 'preact';
import { useEffect, useRef } from 'preact/hooks';
import { lastSyncedAt, online, settings, syncNow, syncState, toast, unsyncedCount } from '../lib/store';
import { go, tabOf, current } from '../lib/router';
import { IBook, IBulb, IChevronLeft, IHome, IInfo, IPlusCircle, ISettings } from './icons';

// ── Status pill: offline / saved on phone / syncing / synced ──

export function StatusPill({ onlyWhenOffline }: { onlyWhenOffline?: boolean } = {}) {
  const isOnline = online.value;
  if (onlyWhenOffline && isOnline) return null;
  const sync = settings.value.syncEnabled;
  const pending = unsyncedCount.value;
  let cls = 'status';
  let text: string;
  if (!isOnline) {
    cls += ' is-offline';
    text = 'Offline';
  } else if (!sync) {
    text = 'On phone';
  } else if (syncState.value === 'syncing') {
    cls += ' is-syncing is-synced';
    text = 'Syncing…';
  } else if (pending > 0) {
    text = `${pending} to sync`;
  } else {
    cls += ' is-synced';
    text = lastSyncedAt.value ? 'Synced' : 'Sync on';
  }
  const canSync = isOnline && sync && pending > 0;
  return (
    <button class={cls} onClick={() => (canSync ? void syncNow() : go('settings'))} aria-label={`${!isOnline ? 'Offline: meals are saved on this phone' : text}. ${canSync ? 'Tap to sync now' : 'Open settings'}`}>
      <span class="dot" aria-hidden="true" />
      {text}
    </button>
  );
}

export function TopBar({ title, subtitle, backTo, right }: { title: string; subtitle?: string; backTo?: () => void; right?: ComponentChildren }) {
  return (
    <header class={`topbar${backTo ? '' : ' no-back'}`}>
      {backTo && (
        <button class="icon-btn plain" onClick={backTo} aria-label="Back">
          <IChevronLeft />
        </button>
      )}
      <div class="title">
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
      <div class="right">{right ?? <StatusPill onlyWhenOffline={!!backTo} />}</div>
    </header>
  );
}

export function SettingsButton() {
  return (
    <button class="icon-btn plain" onClick={() => go('settings')} aria-label="Settings and profile">
      <ISettings />
    </button>
  );
}

// ── Bottom tabs ──

const TABS = [
  { id: 'today', label: 'Today', Icon: IHome },
  { id: 'log', label: 'Log', Icon: IPlusCircle },
  { id: 'suggestions', label: 'Suggestions', Icon: IBulb },
  { id: 'learn', label: 'Learn', Icon: IBook },
] as const;

export function TabBar() {
  const active = tabOf(current.value.route);
  return (
    <div class="tabbar">
      <nav aria-label="Main">
        {TABS.map(({ id, label, Icon }) => (
          <a class="tab" href={`#/${id}`} aria-current={active === id ? 'page' : undefined} aria-label={label}>
            <Icon />
            <span class="tab-label" aria-hidden="true">{label}</span>
          </a>
        ))}
      </nav>
    </div>
  );
}

export function Footnote() {
  return (
    <p class="footnote">
      <IInfo />
      Nutrition awareness tool, not medical advice.
    </p>
  );
}

// ── Controls ──

export function Switch({ checked, onChange, label, id }: { checked: boolean; onChange: (v: boolean) => void; label: string; id: string }) {
  return (
    <span class="switch">
      <input id={id} type="checkbox" role="switch" checked={checked} aria-label={label} onChange={(e) => onChange((e.target as HTMLInputElement).checked)} />
      <span class="track" />
      <span class="thumb" />
    </span>
  );
}

export function Stepper({ value, onChange, min = 0.25, max = 20, step = 1, format }: { value: number; onChange: (v: number) => void; min?: number; max?: number; step?: number; format?: (v: number) => string }) {
  return (
    <div class="stepper" role="group" aria-label="Amount">
      <button onClick={() => onChange(Math.max(min, +(value - step).toFixed(2)))} disabled={value <= min} aria-label="Less">−</button>
      <output aria-live="polite">{format ? format(value) : value}</output>
      <button onClick={() => onChange(Math.min(max, +(value + step).toFixed(2)))} disabled={value >= max} aria-label="More">+</button>
    </div>
  );
}

export function Sheet({ open, onClose, title, children }: { open: boolean; onClose: () => void; title: string; children: ComponentChildren }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    ref.current?.focus();
    document.body.style.overflow = 'hidden';
    return () => { window.removeEventListener('keydown', onKey); document.body.style.overflow = ''; };
  }, [open]);
  if (!open) return null;
  return (
    <>
      <div class="sheet-backdrop" onClick={onClose} />
      <div class="sheet paper" role="dialog" aria-modal="true" aria-label={title} tabIndex={-1} ref={ref}>
        <div class="grabber" />
        <h2>{title}</h2>
        {children}
      </div>
    </>
  );
}

export function Toast() {
  const t = toast.value;
  if (!t) return null;
  return (
    <div class="toast" role="status" aria-live="polite" key={t.id}>
      <span>{t.text}</span>
      {t.action && (
        <button onClick={() => { t.action!.run(); toast.value = null; }}>{t.action.label}</button>
      )}
    </div>
  );
}

// ── Progress ring ──

export function ProgressRing({ value, max, children }: { value: number; max: number; children: ComponentChildren }) {
  const r = 44;
  const circ = 2 * Math.PI * r;
  const pct = max > 0 ? Math.min(1, value / max) : 0;
  const fill = useRef<SVGCircleElement>(null);
  // Start empty, then ease to the real value.
  useEffect(() => {
    const el = fill.current;
    if (!el) return;
    requestAnimationFrame(() => { el.style.strokeDashoffset = String(circ * (1 - pct)); });
  }, [pct]);
  return (
    <div class="ring-wrap" role="img" aria-label={`About ${Math.round(value)} of ${Math.round(max)} grams of protein eaten`}>
      <svg viewBox="0 0 104 104">
        <defs>
          <linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stop-color="#f6ebcf" />
            <stop offset="1" stop-color="#c9dfc3" />
          </linearGradient>
        </defs>
        <circle class="ring-track" cx="52" cy="52" r={r} fill="none" stroke-width="8" />
        <circle ref={fill} class="ring-fill" cx="52" cy="52" r={r} fill="none" stroke-width="8" stroke-linecap="round" stroke-dasharray={String(circ)} style={{ strokeDashoffset: String(circ) }} />
      </svg>
      <div class="ring-center">{children}</div>
    </div>
  );
}

export function Skeleton({ h = 20, w = '100%', r }: { h?: number; w?: string | number; r?: number }) {
  return <div class="skel" style={{ height: `${h}px`, width: typeof w === 'number' ? `${w}px` : w, borderRadius: r ? `${r}px` : undefined }} aria-hidden="true" />;
}

// ── Celebration when the gap closes ──

export function Celebration({ onDone }: { onDone: () => void }) {
  useEffect(() => {
    const t = setTimeout(onDone, 3600);
    return () => clearTimeout(t);
  }, []);
  const colors = ['#5a9a68', '#d9a441', '#c8743f', '#97c487', '#efc86f'];
  const sparks = Array.from({ length: 22 }, (_, i) => {
    const a = (i / 22) * Math.PI * 2;
    const d = 90 + (i % 3) * 40;
    return { x: Math.cos(a) * d, y: Math.sin(a) * d, c: colors[i % colors.length], s: 6 + (i % 3) * 3, delay: (i % 4) * 40 };
  });
  return (
    <>
      <div class="celebrate" aria-hidden="true">
        <div class="burst">
          {sparks.map((s) => (
            <i style={{ '--x': `${s.x}px`, '--y': `${s.y}px`, background: s.c, width: `${s.s}px`, height: `${s.s}px`, animationDelay: `${s.delay}ms` } as Record<string, string>} />
          ))}
        </div>
      </div>
      <div class="celebrate-card" role="status" onClick={onDone}>
        <svg viewBox="0 0 72 72" aria-hidden="true">
          <circle cx="36" cy="36" r="32" fill="rgb(255 255 255 / 0.12)" />
          <path d="M22 37l9 9 19-20" fill="none" stroke="#dcefd5" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <h2>Gap closed. Nice one!</h2>
        <p class="small" style={{ marginTop: '6px' }}>You've reached today's estimated protein target. Keep it easy and keep it going.</p>
      </div>
    </>
  );
}

export function SectionHead({ title, action }: { title: string; action?: ComponentChildren }) {
  return (
    <div class="section-head">
      <h2>{title}</h2>
      {action}
    </div>
  );
}

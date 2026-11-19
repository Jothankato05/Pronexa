import { computed, effect, signal } from '@preact/signals';
import type { Confidence, DraftItem, Question } from '../ai/types';
import type { LogSource, Meal, Profile, Settings } from '../data/types';
import { itemsProtein, proteinGap, proteinTarget, ZERO } from './calc';
import * as db from './db';

// ── Types ────────────────────────────────────────────────────

export interface Draft {
  source: LogSource;
  text?: string;
  price?: number | null;
  items: DraftItem[];
  confidence?: Confidence;
  question?: Question;
  notes?: string[];
  unknown?: string[];
  /** Editing an existing meal instead of adding a new one. */
  editingId?: string;
}

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export const DEFAULT_SETTINGS: Settings = {
  lowData: false,
  syncEnabled: false,
  plantFirst: true,
  budget: 500,
  simulateAiDown: false,
};

// ── State ────────────────────────────────────────────────────

export const ready = signal(false);
export const profile = signal<Profile | null>(null);
export const settings = signal<Settings>(DEFAULT_SETTINGS);
export const meals = signal<Meal[]>([]);
export const online = signal(typeof navigator === 'undefined' ? true : navigator.onLine);
export const syncState = signal<'idle' | 'syncing' | 'error'>('idle');
export const lastSyncedAt = signal<number | null>(null);
export const draft = signal<Draft | null>(null);
export const toast = signal<{ id: number; text: string; action?: { label: string; run: () => void } } | null>(null);
export const installPrompt = signal<BeforeInstallPromptEvent | null>(null);
export const celebrate = signal(0);
const now = signal(Date.now());

// ── Derived ──────────────────────────────────────────────────

export function dateKey(d = new Date()): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export const todayKey = computed(() => dateKey(new Date(now.value)));
export const todayMeals = computed(() => meals.value.filter((m) => m.date === todayKey.value).sort((a, b) => a.time - b.time));
export const target = computed(() => (profile.value ? proteinTarget(profile.value) : ZERO));
export const eaten = computed(() => todayMeals.value.reduce((acc, m) => {
  const p = itemsProtein(m.items);
  return { min: acc.min + p.min, max: acc.max + p.max, mid: acc.mid + p.mid };
}, ZERO));
export const gap = computed(() => proteinGap(target.value, eaten.value));
export const unsyncedCount = computed(() => meals.value.filter((m) => !m.synced).length);

// ── Persistence helpers ──────────────────────────────────────

const persistKv = (key: string, value: unknown) => void db.set('kv', key, value).catch(() => {});

let toastSeq = 0;
export function showToast(text: string, action?: { label: string; run: () => void }) {
  const id = ++toastSeq;
  toast.value = { id, text, action };
  setTimeout(() => { if (toast.value?.id === id) toast.value = null; }, action ? 6000 : 3200);
}

// ── Boot ─────────────────────────────────────────────────────

export async function boot() {
  try {
    const [p, s, m, ls] = await Promise.all([
      db.get<Profile>('kv', 'profile'),
      db.get<Settings>('kv', 'settings'),
      db.all<Meal>('meals'),
      db.get<number>('kv', 'lastSyncedAt'),
    ]);
    profile.value = p ?? null;
    settings.value = { ...DEFAULT_SETTINGS, ...(s ?? {}) };
    meals.value = m ?? [];
    lastSyncedAt.value = ls ?? null;
    tombstones = (await db.get<string[]>('kv', 'tombstones')) ?? [];
  } catch {
    // Storage unavailable: the app still works for this session.
  }
  ready.value = true;

  if (typeof window !== 'undefined') {
    window.addEventListener('online', () => { online.value = true; void autoSync(); });
    window.addEventListener('offline', () => { online.value = false; });
    window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); installPrompt.value = e as BeforeInstallPromptEvent; });
    document.addEventListener('visibilitychange', () => { now.value = Date.now(); });
    setInterval(() => { now.value = Date.now(); }, 60_000);
  }
  effect(() => {
    document.documentElement.classList.toggle('low-data', settings.value.lowData);
  });
  void autoSync();
}

// ── Profile & settings ───────────────────────────────────────

export function saveProfile(p: Profile) {
  profile.value = p;
  persistKv('profile', p);
}

export function updateSettings(patch: Partial<Settings>) {
  settings.value = { ...settings.value, ...patch };
  persistKv('settings', settings.value);
  if (patch.syncEnabled) void autoSync();
}

// ── Meals ────────────────────────────────────────────────────

const uid = () => `m_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;

export function saveDraftAsMeal(d: Draft): Meal {
  const before = gap.value.mid;
  const existing = d.editingId ? meals.value.find((m) => m.id === d.editingId) : undefined;
  const meal: Meal = {
    id: existing?.id ?? uid(),
    date: existing?.date ?? todayKey.value,
    time: existing?.time ?? Date.now(),
    items: d.items.map(({ foodId, portionId, qty, eaten }) => ({ foodId, portionId, qty, eaten })),
    source: d.source,
    text: d.text,
    price: d.price ?? undefined,
    synced: false,
    updatedAt: Date.now(),
  };
  meals.value = existing ? meals.value.map((m) => (m.id === meal.id ? meal : m)) : [...meals.value, meal];
  void db.set('meals', null, meal).catch(() => {});
  draft.value = null;
  // A small celebration the first time today's gap closes.
  if (before > 0 && gap.value.mid <= 0 && settings.value.lastCelebrated !== todayKey.value) {
    updateSettings({ lastCelebrated: todayKey.value });
    celebrate.value++;
  }
  void autoSync();
  return meal;
}

export function deleteMeal(id: string) {
  const meal = meals.value.find((m) => m.id === id);
  if (!meal) return;
  meals.value = meals.value.filter((m) => m.id !== id);
  void db.del('meals', id).catch(() => {});
  addTombstone(id);
  showToast('Meal removed.', {
    label: 'Undo',
    run: () => {
      meals.value = [...meals.value, meal];
      void db.set('meals', null, { ...meal, synced: false }).catch(() => {});
      removeTombstone(id);
    },
  });
}

// ── Sync (offline-first; a real backend drops in via SyncAdapter) ──

export interface SyncAdapter {
  push(changed: Meal[], deletedIds: string[]): Promise<void>;
}

/** Stand-in backend: pretends to upload. Swap for a real endpoint later. */
export const mockSyncAdapter: SyncAdapter = {
  push: () => new Promise((resolve, reject) => setTimeout(() => (navigator.onLine ? resolve() : reject(new Error('offline'))), 700)),
};
let syncAdapter: SyncAdapter = mockSyncAdapter;
export function setSyncAdapter(a: SyncAdapter) { syncAdapter = a; }

let tombstones: string[] = [];
function addTombstone(id: string) { tombstones = [...tombstones, id]; persistKv('tombstones', tombstones); }
function removeTombstone(id: string) { tombstones = tombstones.filter((t) => t !== id); persistKv('tombstones', tombstones); }

export async function syncNow(): Promise<boolean> {
  if (!settings.value.syncEnabled || !online.value || syncState.value === 'syncing') return false;
  const changed = meals.value.filter((m) => !m.synced);
  if (!changed.length && !tombstones.length) { lastSyncedAt.value = Date.now(); return true; }
  syncState.value = 'syncing';
  try {
    await syncAdapter.push(changed, tombstones);
    const ids = new Set(changed.map((m) => m.id));
    meals.value = meals.value.map((m) => (ids.has(m.id) ? { ...m, synced: true } : m));
    for (const m of meals.value) if (ids.has(m.id)) void db.set('meals', null, m).catch(() => {});
    tombstones = [];
    persistKv('tombstones', tombstones);
    lastSyncedAt.value = Date.now();
    persistKv('lastSyncedAt', lastSyncedAt.value);
    syncState.value = 'idle';
    return true;
  } catch {
    syncState.value = 'error';
    return false;
  }
}

/** Background sync. In low-data mode we wait for the student to tap "Sync now". */
async function autoSync() {
  if (settings.value.lowData) return;
  await syncNow();
}

// ── Demo + privacy tools ─────────────────────────────────────

export function loadDemoDay() {
  const today = todayKey.value;
  const base = new Date();
  const at = (h: number, m: number) => new Date(base.getFullYear(), base.getMonth(), base.getDate(), h, m).getTime();
  const demo: Meal[] = [
    { id: uid(), date: today, time: at(8, 10), source: 'quick', synced: false, updatedAt: Date.now(), items: [{ foodId: 'bread', portionId: 'slice', qty: 3, eaten: 1 }, { foodId: 'akara', portionId: 'ball', qty: 3, eaten: 1 }] },
    { id: uid(), date: today, time: at(13, 30), source: 'describe', text: '₦1,000 rice and beans, medium takeaway', price: 1000, synced: false, updatedAt: Date.now(), items: [{ foodId: 'rice_beans', portionId: 'md_pack', qty: 1, eaten: 1 }] },
  ];
  meals.value = [...meals.value.filter((m) => m.date !== today), ...demo];
  for (const m of meals.value.filter((x) => x.date === today)) void db.set('meals', null, m).catch(() => {});
  updateSettings({ lastCelebrated: undefined });
  showToast('Demo day loaded: breakfast and lunch.');
}

export async function resetAll() {
  await db.clearAll();
  profile.value = null;
  meals.value = [];
  settings.value = DEFAULT_SETTINGS;
  lastSyncedAt.value = null;
  draft.value = null;
}

export function exportData(): string {
  return JSON.stringify({ exportedAt: new Date().toISOString(), profile: profile.value, settings: settings.value, meals: meals.value }, null, 2);
}

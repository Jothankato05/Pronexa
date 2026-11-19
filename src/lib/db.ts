/**
 * Tiny IndexedDB wrapper (no dependencies). Everything the student logs lives on the
 * phone first. Falls back to localStorage, then memory, on browsers that block IndexedDB.
 */

type StoreName = 'kv' | 'meals' | 'aicache';
const DB_NAME = 'pronexa';
const DB_VER = 1;

let dbPromise: Promise<IDBDatabase | null> | null = null;

function open(): Promise<IDBDatabase | null> {
  if (dbPromise) return dbPromise;
  dbPromise = new Promise((resolve) => {
    try {
      if (typeof indexedDB === 'undefined') return resolve(null);
      const req = indexedDB.open(DB_NAME, DB_VER);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains('kv')) db.createObjectStore('kv');
        if (!db.objectStoreNames.contains('meals')) db.createObjectStore('meals', { keyPath: 'id' }).createIndex('date', 'date');
        if (!db.objectStoreNames.contains('aicache')) db.createObjectStore('aicache');
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => resolve(null);
      req.onblocked = () => resolve(null);
    } catch {
      resolve(null);
    }
  });
  return dbPromise;
}

const mem = new Map<string, unknown>();
const lsKey = (store: StoreName, key: string) => `pronexa:${store}:${key}`;

function lsGet<T>(store: StoreName, key: string): T | undefined {
  try {
    const v = localStorage.getItem(lsKey(store, key));
    return v ? (JSON.parse(v) as T) : undefined;
  } catch {
    return mem.get(lsKey(store, key)) as T | undefined;
  }
}
function lsSet(store: StoreName, key: string, value: unknown) {
  try {
    localStorage.setItem(lsKey(store, key), JSON.stringify(value));
  } catch {
    mem.set(lsKey(store, key), value);
  }
}

function tx<T>(db: IDBDatabase, store: StoreName, mode: IDBTransactionMode, fn: (s: IDBObjectStore) => IDBRequest<T> | void): Promise<T | undefined> {
  return new Promise((resolve, reject) => {
    const t = db.transaction(store, mode);
    const s = t.objectStore(store);
    const req = fn(s);
    t.oncomplete = () => resolve(req ? (req.result as T) : undefined);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  });
}

export async function get<T>(store: StoreName, key: string): Promise<T | undefined> {
  const db = await open();
  if (!db) return lsGet<T>(store, key);
  return tx<T>(db, store, 'readonly', (s) => s.get(key) as IDBRequest<T>);
}

export async function set(store: StoreName, key: string | null, value: unknown): Promise<void> {
  const db = await open();
  if (!db) {
    const k = key ?? (value as { id: string }).id;
    if (store === 'meals') {
      const all = lsGet<Record<string, unknown>>('meals', 'all') ?? {};
      all[k] = value;
      lsSet('meals', 'all', all);
    } else lsSet(store, k, value);
    return;
  }
  await tx(db, store, 'readwrite', (s) => (key === null ? s.put(value) : s.put(value, key)));
}

export async function del(store: StoreName, key: string): Promise<void> {
  const db = await open();
  if (!db) {
    if (store === 'meals') {
      const all = lsGet<Record<string, unknown>>('meals', 'all') ?? {};
      delete all[key];
      lsSet('meals', 'all', all);
    } else {
      try { localStorage.removeItem(lsKey(store, key)); } catch { mem.delete(lsKey(store, key)); }
    }
    return;
  }
  await tx(db, store, 'readwrite', (s) => s.delete(key));
}

export async function all<T>(store: StoreName): Promise<T[]> {
  const db = await open();
  if (!db) return Object.values(lsGet<Record<string, T>>(store, 'all') ?? {});
  return (await tx<T[]>(db, store, 'readonly', (s) => s.getAll() as IDBRequest<T[]>)) ?? [];
}

export async function clearAll(): Promise<void> {
  const db = await open();
  if (db) {
    for (const s of ['kv', 'meals', 'aicache'] as StoreName[]) await tx(db, s, 'readwrite', (st) => st.clear());
  }
  try {
    Object.keys(localStorage).filter((k) => k.startsWith('pronexa:')).forEach((k) => localStorage.removeItem(k));
  } catch { /* ignore */ }
  mem.clear();
}

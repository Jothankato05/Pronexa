import { useMemo, useState } from 'preact/hooks';
import { FOODS, GROUP_LABELS } from '../data/foods';
import type { Food } from '../data/types';
import { FoodIcon, ISearch } from './icons';
import { Sheet } from './ui';

export function matchesQuery(f: Food, q: string): boolean {
  if (!q) return true;
  const s = q.toLowerCase().trim();
  return f.name.toLowerCase().includes(s) || (f.local ?? '').toLowerCase().includes(s) || f.aliases.some((a) => a.includes(s));
}

export const GROUP_ORDER = ['plant', 'staple', 'soup', 'animal', 'drink'] as const;

export function FoodPicker({ open, title, onClose, onPick }: { open: boolean; title: string; onClose: () => void; onPick: (f: Food) => void }) {
  const [q, setQ] = useState('');
  const list = useMemo(() => FOODS.filter((f) => matchesQuery(f, q)), [q]);
  return (
    <Sheet open={open} onClose={() => { setQ(''); onClose(); }} title={title}>
      <div class="search" style={{ marginBottom: '12px' }}>
        <ISearch />
        <input class="input" type="search" placeholder="Search: beans, eba, akara…" value={q} onInput={(e) => setQ((e.target as HTMLInputElement).value)} aria-label="Search foods" />
      </div>
      {GROUP_ORDER.map((g) => {
        const foods = list.filter((f) => f.group === g);
        if (!foods.length) return null;
        return (
          <div>
            <p class="eyebrow group-label">{GROUP_LABELS[g]}</p>
            <div class="choice-list">
              {foods.map((f) => (
                <button class="choice boxy" onClick={() => { setQ(''); onPick(f); }}>
                  <span class="choice-icon"><FoodIcon name={f.icon} /></span>
                  <span class="grow"><strong>{f.name}</strong>{f.local && <span class="sub">{f.local}</span>}</span>
                </button>
              ))}
            </div>
          </div>
        );
      })}
      {!list.length && <p class="muted" style={{ padding: '16px 0' }}>No match yet. Try another word, like "beans" or "swallow".</p>}
    </Sheet>
  );
}

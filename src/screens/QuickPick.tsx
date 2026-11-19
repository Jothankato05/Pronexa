import { useMemo, useState } from 'preact/hooks';
import { GROUP_ORDER, matchesQuery } from '../components/FoodPicker';
import { FoodIcon, ICheck, ILeaf, ISearch } from '../components/icons';
import { TopBar } from '../components/ui';
import { FOOD_BY_ID, FOODS, GROUP_LABELS } from '../data/foods';
import { back, go } from '../lib/router';
import { draft, meals } from '../lib/store';
import { newKey } from '../lib/keys';
import type { Food } from '../data/types';

export function QuickPick() {
  const [q, setQ] = useState('');
  const [picked, setPicked] = useState<string[]>([]);
  const list = useMemo(() => FOODS.filter((f) => matchesQuery(f, q)), [q]);

  const recent = useMemo(() => {
    const ids: string[] = [];
    for (const m of [...meals.value].sort((a, b) => b.time - a.time)) {
      for (const i of m.items) if (!ids.includes(i.foodId) && FOOD_BY_ID[i.foodId]) ids.push(i.foodId);
      if (ids.length >= 6) break;
    }
    return ids.slice(0, 6);
  }, []);

  const toggle = (id: string) => setPicked((p) => (p.includes(id) ? p.filter((x) => x !== id) : [...p, id]));

  const next = () => {
    draft.value = {
      source: 'quick',
      items: picked.map((id) => {
        const f = FOOD_BY_ID[id];
        return { key: newKey(), foodId: id, portionId: f.defaultPortion, qty: f.defaultQty ?? 1, eaten: 1, portionSource: 'default' };
      }),
    };
    go('log/confirm');
  };

  const tile = (f: Food) => (
    <button class="food-tile" aria-pressed={picked.includes(f.id)} onClick={() => toggle(f.id)}>
      <span class="fi-bg"><FoodIcon name={f.icon} class="fi" /></span>
      <strong>{f.name}</strong>
      {f.local && <span class="small">{f.local}</span>}
      {f.altProtein && <span class="alt" title="Plant protein"><ILeaf width={16} height={16} /></span>}
      <span class="check"><ICheck /></span>
    </button>
  );

  return (
    <div class="screen">
      <TopBar title="Quick pick" subtitle="Tap everything that was in the meal" backTo={() => back('log')} />
      <div class="search">
        <ISearch />
        <input class="input" type="search" placeholder="Search: beans, eba, akara, Pidgin is fine" value={q} onInput={(e) => setQ((e.target as HTMLInputElement).value)} aria-label="Search foods" />
      </div>

      {!q && recent.length > 0 && (
        <>
          <p class="eyebrow group-label">Your recent foods</p>
          <div class="food-grid">{recent.map((id) => tile(FOOD_BY_ID[id]))}</div>
        </>
      )}

      {GROUP_ORDER.map((g) => {
        const foods = list.filter((f) => f.group === g && (q || !recent.includes(f.id)));
        if (!foods.length) return null;
        return (
          <section>
            <p class="eyebrow group-label">{g === 'plant' && <ILeaf width={14} height={14} />}{GROUP_LABELS[g]}</p>
            <div class="food-grid">{foods.map(tile)}</div>
          </section>
        );
      })}
      {!list.length && (
        <div class="card flat empty" style={{ marginTop: '16px' }}>
          <h3>Not on the list yet</h3>
          <p>Try a different word, like "swallow" or "soup". We're adding more Nigerian foods all the time.</p>
        </div>
      )}

      {picked.length > 0 && (
        <div class="tray">
          <div>
            <span class="grow" style={{ fontWeight: 700 }}>{picked.length} food{picked.length > 1 ? 's' : ''} picked</span>
            <button class="btn btn-primary" onClick={next}>Next: portions</button>
          </div>
        </div>
      )}
      <div style={{ height: '80px' }} />
    </div>
  );
}

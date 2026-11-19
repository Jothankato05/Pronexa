import { useState } from 'preact/hooks';
import { AssistantPill } from '../assistant/AssistantPill';
import { FoodIcon, IBulb, IDownload, IGrid, IMenu, IPencil, ISparkle, ITrash } from '../components/icons';
import { Footnote, ProgressRing, Sheet, StatusPill } from '../components/ui';
import { FOOD_BY_ID } from '../data/foods';
import type { Meal } from '../data/types';
import { describeItems, fmtRange, itemsProtein } from '../lib/calc';
import { dietLabel } from '../lib/diet';
import { newKey } from '../lib/keys';
import { go } from '../lib/router';
import { deleteMeal, draft, eaten, gap, installPrompt, online, profile, settings, target, todayMeals } from '../lib/store';

export function mealLabel(time: number): string {
  const h = new Date(time).getHours();
  if (h < 11) return 'Breakfast';
  if (h < 16) return 'Lunch';
  if (h < 21) return 'Dinner';
  return 'Late snack';
}

const timeFmt = (t: number) => new Date(t).toLocaleTimeString('en-NG', { hour: 'numeric', minute: '2-digit' });
const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

export function editMeal(m: Meal) {
  draft.value = { source: m.source, text: m.text, price: m.price ?? null, items: m.items.map((i) => ({ ...i, key: newKey(), portionSource: 'stated' })), editingId: m.id };
  go('log/confirm');
}

const PHRASES = ['₦1,000 rice and beans, medium pack', 'Eba and egusi with one meat', 'Bread and 4 akara', 'Soaked garri and groundnut'];

export function Today() {
  const t = target.value;
  const e = eaten.value;
  const g = gap.value;
  const list = todayMeals.value;
  const closed = list.length > 0 && g.mid <= 0;
  const pct = t.mid > 0 ? Math.min(100, Math.round((e.mid / t.mid) * 100)) : 0;
  const [quick, setQuick] = useState('');
  const [selected, setSelected] = useState<Meal | null>(null);
  const aiReady = online.value && !settings.value.simulateAiDown;
  const date = new Date().toLocaleDateString('en-NG', { weekday: 'long', day: 'numeric', month: 'short' });

  return (
    <div class="screen">
      <header class="dash-head">
        <div class="dash-top">
          <button class="icon-btn plain" onClick={() => go('settings')} aria-label="Profile and settings"><IMenu /></button>
          <span class="caption muted">{date}</span>
          <StatusPill />
        </div>

        <div class="pill-row" aria-label="Today at a glance">
          <span class="mini-pill"><i style={{ background: 'var(--ochre-400)' }} />TARGET <span class="v num">~{Math.round(t.mid)} g</span></span>
          <span class="mini-pill"><i style={{ background: closed ? 'var(--leaf-300)' : 'var(--clay-200)' }} />{closed ? 'GAP CLOSED' : <>GAP <span class="v num">{fmtRange(list.length ? g : t)}</span></>}</span>
          <span class="mini-pill"><i style={{ background: 'var(--leaf-200)' }} />{dietLabel(profile.value!.diet).toUpperCase()}</span>
        </div>

        <div class="balance">
          <div>
            <div class="big num" aria-label={`About ${Math.round(e.mid)} grams of protein eaten`}>{Math.round(e.mid)}<small>g</small></div>
            <p class="sub">{list.length ? `about ${fmtRange(e)} eaten · estimate` : 'protein eaten today'}</p>
          </div>
          <ProgressRing value={e.mid} max={t.mid}>
            <span class="pct num">{pct}%</span>
            <span class="of">of target</span>
          </ProgressRing>
        </div>

        <nav class="actions" aria-label="Log a meal">
          <button class="action primary" onClick={() => go('log/quick')}><span class="a-ico"><IGrid /></span><span class="a-label">Pick</span></button>
          <button class="action" onClick={() => go('log/portion')}><span class="a-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" aria-hidden="true"><path d="M3 11h18l-1.6 7.2a2 2 0 0 1-2 1.8H6.6a2 2 0 0 1-2-1.8Z" /><path d="M4 11 6 5h12l2 6" /></svg></span><span class="a-label">Portion</span></button>
          <button class="action" onClick={() => go('log/describe')}><span class="a-ico"><ISparkle /></span><span class="a-label">Describe</span></button>
          <button class="action" onClick={() => go('suggestions')}><span class="a-ico"><IBulb /></span><span class="a-label">Solve</span></button>
        </nav>
      </header>

      <div style={{ marginTop: '28px' }}>
        <AssistantPill
          compact value={quick} onInput={setQuick} phrases={PHRASES} placeholder="Describe a meal…"
          disabled={!aiReady}
          onSubmit={(v) => go('log/describe', `q=${encodeURIComponent(v)}`)}
        />
        {!aiReady && <p class="caption faint" style={{ marginTop: '10px', textAlign: 'center' }}>Describing needs internet. Pick and Portion work offline.</p>}
      </div>

      <section class="paper-sheet paper" aria-labelledby="meals-title">
        <div class="section-head">
          <h2 id="meals-title">Today's meals</h2>
          {list.length > 0 && !closed && <button class="link" onClick={() => go('suggestions')}>Close the gap</button>}
        </div>

        {list.length === 0 ? (
          <div class="empty">
            <FoodIcon name="empty-plate" class="illus" />
            <h3>Nothing logged yet today</h3>
            <p>Start with your last meal. Even bread and tea counts. It takes about 20 seconds.</p>
          </div>
        ) : (
          list.map((m) => <MealRow meal={m} onOpen={() => setSelected(m)} />)
        )}

        {closed && (
          <div class="card tint-leaf" style={{ marginTop: '24px', padding: '16px 20px' }}>
            <strong style={{ color: 'var(--good)' }}>You've reached today's estimate. Well done!</strong>
          </div>
        )}

        {installPrompt.value && (
          <div class="card inset row" style={{ marginTop: '24px', padding: '16px 20px' }}>
            <span class="grow"><strong>Install Pronexa</strong><span class="small faint" style={{ display: 'block' }}>Opens like an app and works offline.</span></span>
            <button class="btn btn-primary btn-small" onClick={async () => { const p = installPrompt.value!; await p.prompt(); installPrompt.value = null; }}><IDownload /> Install</button>
          </div>
        )}

        {profile.value?.diet === 'vegan' && list.length > 0 && (
          <p class="small faint" style={{ marginTop: '24px' }}>Plant-based tip: B12 comes from fortified foods or supplements. See Learn.</p>
        )}
        <Footnote />
      </section>

      <Sheet open={!!selected} onClose={() => setSelected(null)} title={selected ? cap(describeItems(selected.items)) : ''}>
        {selected && (
          <div class="stack">
            <p class="small faint">{mealLabel(selected.time)} · {timeFmt(selected.time)} · about {fmtRange(itemsProtein(selected.items))} protein</p>
            <button class="btn btn-primary btn-block" onClick={() => { const m = selected; setSelected(null); editMeal(m); }}><IPencil /> Edit meal</button>
            <button class="btn btn-danger btn-block" onClick={() => { const id = selected.id; setSelected(null); deleteMeal(id); }}><ITrash /> Remove meal</button>
          </div>
        )}
      </Sheet>
    </div>
  );
}

function MealRow({ meal, onOpen }: { meal: Meal; onOpen: () => void }) {
  const p = itemsProtein(meal.items);
  const first = FOOD_BY_ID[meal.items[0]?.foodId];
  const title = cap(describeItems(meal.items));
  return (
    <button class="meal" onClick={onOpen} style={{ width: '100%', background: 'none', border: 0, textAlign: 'left', color: 'inherit' }} aria-label={`${title}, about ${fmtRange(p)} protein. Edit or remove`}>
      <span class="meal-ico"><FoodIcon name={first?.icon ?? 'plate'} /></span>
      <span class="meal-body">
        <strong>{title}</strong>
        <span class="small">{mealLabel(meal.time)} · {timeFmt(meal.time)}{meal.synced ? ' · synced' : ''}</span>
      </span>
      <span class="meal-p">
        <b class="num">+{fmtRange(p)}</b>
        <span class="caption num">≈ {Math.round(p.mid)} g</span>
      </span>
    </button>
  );
}

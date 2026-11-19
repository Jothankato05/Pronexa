import { useEffect, useState } from 'preact/hooks';
import { pickQuestion } from '../ai/validate';
import { newKey } from '../lib/keys';
import type { Confidence, DraftItem, QuestionAction } from '../ai/types';
import { FoodPicker } from '../components/FoodPicker';
import { EatenIcon, FoodIcon, IClose, IInfo, IPencil, IPlus } from '../components/icons';
import { Footnote, Sheet, Stepper, TopBar } from '../components/ui';
import { FOOD_BY_ID, PRICES_AS_OF_LABEL } from '../data/foods';
import { EATEN_OPTIONS, PORTIONS } from '../data/portions';
import { EATEN_LABEL, fmtNaira, fmtQty, fmtRange, itemProtein, itemsProtein, portionLabel } from '../lib/calc';
import { back, go } from '../lib/router';
import { draft, saveDraftAsMeal, showToast, type Draft } from '../lib/store';

const CONF_COPY: Record<Confidence, { title: string; sub: string; bars: number }> = {
  high: { title: 'Pretty sure', sub: 'Have a quick look, then add it.', bars: 3 },
  medium: { title: 'Fairly sure', sub: 'Please check the highlighted bits.', bars: 2 },
  low: { title: 'Not too sure', sub: 'Please check each food and portion.', bars: 1 },
};

type Editing = { key: string; field: 'food' | 'portion' | 'eaten' } | { key: null; field: 'add' } | null;

export function Confirm() {
  const d = draft.value;
  const [editing, setEditing] = useState<Editing>(null);

  useEffect(() => {
    if (!d) go('log', undefined, { replace: true });
  }, [d]);
  if (!d) return null;

  const update = (patch: Partial<Draft>) => { draft.value = { ...d, ...patch }; };
  const updateItem = (key: string, patch: Partial<DraftItem>) => {
    update({ items: d.items.map((i) => (i.key === key ? { ...i, ...patch, portionSource: 'stated', generic: false } : i)) });
  };
  const removeItem = (key: string) => update({ items: d.items.filter((i) => i.key !== key) });

  const answer = (a: QuestionAction) => {
    let items = d.items;
    if (a.type === 'portion') items = items.map((i) => (i.key === a.key ? { ...i, portionId: a.portionId, qty: 1, portionSource: 'stated' } : i));
    if (a.type === 'food') items = items.map((i) => (i.key === a.key ? { ...i, foodId: a.foodId, generic: false, portionId: FOOD_BY_ID[a.foodId].portions.some((p) => p.id === i.portionId) ? i.portionId : FOOD_BY_ID[a.foodId].defaultPortion } : i));
    if (a.type === 'add') {
      const f = FOOD_BY_ID[a.foodId];
      items = [...items, { key: newKey(), foodId: f.id, portionId: f.defaultPortion, qty: f.defaultQty ?? 1, eaten: items[0]?.eaten ?? 1, portionSource: 'default' }];
    }
    const unknown = a.type === 'add' || a.type === 'dismiss' ? (d.unknown ?? []).slice(1) : d.unknown;
    // One question at a time: after an answer, see if anything important is still unclear.
    const nextQ = pickQuestion(items, unknown ?? []);
    const bumped: Confidence = d.confidence === 'low' ? 'medium' : 'high';
    update({ items, unknown, question: nextQ && nextQ.id !== d.question?.id ? nextQ : undefined, confidence: nextQ ? d.confidence : bumped });
  };

  const total = itemsProtein(d.items);
  const editItem = editing && editing.key ? d.items.find((i) => i.key === editing.key) : undefined;

  const save = () => {
    const wasEditing = !!d.editingId;
    saveDraftAsMeal(d);
    showToast(wasEditing ? 'Meal updated.' : `Added. About ${fmtRange(total)} of protein.`);
    go('today', undefined, { replace: true });
  };

  return (
    <div class="screen">
      <TopBar title={d.editingId ? 'Edit meal' : 'Check your meal'} subtitle="Fix anything before we count it" backTo={() => back('log')} />

      {d.text && (
        <p class="small muted" style={{ marginBottom: '16px' }}>You said: <q style={{ color: 'var(--ink)', fontWeight: 500 }}>{d.text}</q></p>
      )}

      {d.source === 'describe' && d.confidence && (
        <div class={`confidence ${d.confidence}`} role="status">
          <span class="bars" aria-hidden="true">{[1, 2, 3].map((n) => <i class={n <= CONF_COPY[d.confidence!].bars ? 'on' : ''} />)}</span>
          <span><strong>{CONF_COPY[d.confidence].title}</strong><span class="small">{CONF_COPY[d.confidence].sub}</span></span>
        </div>
      )}

      {d.question && (
        <div class="question" style={{ marginTop: '16px' }} role="group" aria-label="Quick question">
          <h3>{d.question.text}</h3>
          <div class="chips">
            {d.question.options.map((o) => (
              <button class="chip" aria-pressed={!!o.selected} onClick={() => answer(o.action)}>{o.label}</button>
            ))}
          </div>
        </div>
      )}

      <section class="paper-sheet paper" aria-label="Foods">
        <div class="section-head"><h2>What we understood</h2><span class="caption faint">{d.items.length} food{d.items.length === 1 ? '' : 's'}</span></div>
        {d.items.length === 0 && (
          <div class="card flat empty">
            <h3>No foods yet</h3>
            <p>Add what you ate and we'll count it.</p>
          </div>
        )}
        {d.items.map((it) => {
          const f = FOOD_BY_ID[it.foodId];
          const p = itemProtein(it);
          const guess = it.portionSource && it.portionSource !== 'stated' && d.source === 'describe';
          return (
            <article class="item-card" key={it.key}>
              <div class="item-head">
                <span class="fi-bg"><FoodIcon name={f.icon} class="fi" /></span>
                <div class="grow">
                  <button class={`edit-chip food${it.generic && d.source === 'describe' ? ' guess' : ''}`} onClick={() => setEditing({ key: it.key, field: 'food' })} aria-label={`Food: ${f.name}. Change`}>
                    {f.name} <IPencil />
                  </button>
                </div>
                <button class="icon-btn plain" onClick={() => removeItem(it.key)} aria-label={`Remove ${f.name}`}><IClose /></button>
              </div>
              <div class="item-chips">
                <button class={`edit-chip${guess ? ' guess' : ''}`} onClick={() => setEditing({ key: it.key, field: 'portion' })} aria-label={`Portion: ${portionLabel(it)}. Change`}>
                  {portionLabel(it)} <IPencil />
                </button>
                <button class="edit-chip" onClick={() => setEditing({ key: it.key, field: 'eaten' })} aria-label={`Amount eaten: ${EATEN_LABEL[String(it.eaten)]}. Change`}>
                  {it.eaten === 1 ? 'Ate all' : EATEN_LABEL[String(it.eaten)]} <IPencil />
                </button>
              </div>
              <div class="item-foot">
                <span class="caption faint">{f.local ?? 'Protein'}{guess ? ' · please check the size' : ''}</span>
                <b class="num">{fmtRange(p)}</b>
              </div>
            </article>
          );
        })}
        <button class="btn btn-secondary btn-block" style={{ marginTop: '12px', minHeight: '52px' }} onClick={() => setEditing({ key: null, field: 'add' })}>
          <IPlus /> Add another food
        </button>


      {(d.notes?.length || d.price) ? (
        <div class="card inset stack" style={{ marginTop: '24px', padding: '20px' }}>
          {d.price ? <p class="note"><IInfo />You paid about {fmtNaira(d.price)}. Price is only a clue for the portion, never a measure.</p> : null}
          {d.notes?.map((n) => <p class="note"><IInfo />{n}</p>)}
        </div>
      ) : null}

      {d.items.length > 0 && (
        <div class="total-bar" style={{ marginTop: '24px' }}>
          <span><strong style={{ display: 'block' }}>This meal</strong><span class="caption faint">estimated protein</span></span>
          <b class="num"><small>about</small>{fmtRange(total)}</b>
        </div>
      )}

      <div class="sticky-cta">
        <button class="btn btn-primary btn-block" disabled={!d.items.length} onClick={save}>
          {d.editingId ? 'Save changes' : 'Looks right, add to today'}
        </button>
      </div>
      <p class="caption faint" style={{ textAlign: 'center', marginTop: '12px' }}>Numbers from Pronexa's starter food database. Prices from {PRICES_AS_OF_LABEL}.</p>
      <Footnote />
      </section>

      {/* ── Edit sheets ── */}
      <FoodPicker
        open={editing?.field === 'food' || editing?.field === 'add'}
        title={editing?.field === 'add' ? 'Add a food' : 'Change food'}
        onClose={() => setEditing(null)}
        onPick={(f) => {
          if (editing?.field === 'add') {
            update({ items: [...d.items, { key: newKey(), foodId: f.id, portionId: f.defaultPortion, qty: f.defaultQty ?? 1, eaten: 1, portionSource: 'default' }] });
          } else if (editItem) {
            const keepPortion = f.portions.some((p) => p.id === editItem.portionId);
            updateItem(editItem.key, { foodId: f.id, portionId: keepPortion ? editItem.portionId : f.defaultPortion, qty: keepPortion ? editItem.qty : f.defaultQty ?? 1 });
          }
          setEditing(null);
        }}
      />

      <Sheet open={editing?.field === 'portion' && !!editItem} onClose={() => setEditing(null)} title={editItem ? `How much ${FOOD_BY_ID[editItem.foodId].name.toLowerCase()}?` : ''}>
        {editItem && (
          <div class="stack">
            <div class="choice-list" role="radiogroup" aria-label="Portion">
              {FOOD_BY_ID[editItem.foodId].portions.map((p) => (
                <button class="choice" role="radio" aria-checked={editItem.portionId === p.id} onClick={() => updateItem(editItem.key, { portionId: p.id })}>
                  <span class="choice-icon"><FoodIcon name={PORTIONS[p.id].icon} /></span>
                  <span class="grow">
                    <strong>{(p.label ?? PORTIONS[p.id].one).replace(/^./, (c) => c.toUpperCase())}</strong>
                    {p.price && <span class="sub">about {fmtNaira(p.price[0])}–{fmtNaira(p.price[1]).slice(1)}</span>}
                  </span>
                </button>
              ))}
            </div>
            <div class="row-between card inset">
              <strong>How many?</strong>
              <Stepper value={editItem.qty} min={0.25} max={20} step={editItem.qty < 1 || PORTIONS[editItem.portionId].container ? 0.25 : 1} format={fmtQty} onChange={(v) => updateItem(editItem.key, { qty: v })} />
            </div>
            <button class="btn btn-primary btn-block" onClick={() => setEditing(null)}>Done</button>
          </div>
        )}
      </Sheet>

      <Sheet open={editing?.field === 'eaten' && !!editItem} onClose={() => setEditing(null)} title="How much did you eat?">
        {editItem && (
          <div class="eaten-grid">
            {EATEN_OPTIONS.map((o) => (
              <button class="eaten-tile" aria-pressed={editItem.eaten === o.value} onClick={() => { updateItem(editItem.key, { eaten: o.value }); setEditing(null); }}>
                <EatenIcon fraction={o.value} />
                <strong>{o.label}</strong>
              </button>
            ))}
          </div>
        )}
      </Sheet>
    </div>
  );
}

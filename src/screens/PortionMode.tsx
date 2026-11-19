import { useState } from 'preact/hooks';
import { EatenIcon, FoodIcon, ICheck } from '../components/icons';
import { Stepper, TopBar } from '../components/ui';
import { FOOD_BY_ID, FOODS } from '../data/foods';
import { CONTAINERS, EATEN_OPTIONS, PORTIONS } from '../data/portions';
import type { Food, PortionId } from '../data/types';
import { back, go } from '../lib/router';
import { draft } from '../lib/store';
import { newKey } from '../lib/keys';
import type { DraftItem } from '../ai/types';

const EXTRA_IDS = ['beef', 'chicken', 'fish', 'egg', 'moi_moi', 'akara', 'tofu', 'soya_chunks', 'beans', 'plantain', 'stew', 'egusi', 'efo_riro', 'okra', 'ewedu', 'groundnuts'];
const SWALLOW_EXTRAS = ['egusi', 'efo_riro', 'okra', 'ewedu', 'beef', 'fish', 'chicken', 'tofu', 'soya_chunks'];
const CONTAINER_LABEL: Record<string, string> = { sm_pack: 'Small takeaway', md_pack: 'Medium takeaway', lg_pack: 'Large takeaway', plate: 'Plate', bowl: 'Bowl', wrap: 'Swallow wrap' };

export function PortionMode() {
  const [step, setStep] = useState(0);
  const [container, setContainer] = useState<PortionId | null>(null);
  const [fill, setFill] = useState<string[]>([]);
  const [wraps, setWraps] = useState(1);
  const [extras, setExtras] = useState<Record<string, number>>({});
  const [eaten, setEaten] = useState<number>(1);

  // Soups only "fill" a bowl; otherwise they are a side.
  const fillFoods = container ? FOODS.filter((f) => f.portions.some((p) => p.id === container) && (f.group !== 'soup' || container === 'bowl')) : [];
  const extraIds = (container === 'wrap' ? SWALLOW_EXTRAS : EXTRA_IDS).filter((id) => !fill.includes(id));

  const toggleFill = (id: string) => setFill((f) => (f.includes(id) ? f.filter((x) => x !== id) : [...f, id]));
  const setExtra = (id: string, n: number) => setExtras((e) => ({ ...e, [id]: n }));

  const finish = () => {
    if (!container) return;
    const share = 1 / Math.max(1, fill.length);
    const items: DraftItem[] = fill.map((id) => ({
      key: newKey(), foodId: id, portionId: container, qty: container === 'wrap' ? wraps : +share.toFixed(2), eaten, portionSource: 'stated',
    }));
    for (const [id, n] of Object.entries(extras)) {
      if (!n) continue;
      const f = FOOD_BY_ID[id];
      items.push({ key: newKey(), foodId: id, portionId: f.defaultPortion, qty: n, eaten, portionSource: 'stated' });
    }
    draft.value = { source: 'portion', items };
    go('log/confirm');
  };

  const titles = ['What did it come in?', 'What filled it?', 'Anything on top or on the side?', 'How much did you eat?'];

  return (
    <div class="screen ambient">
      <TopBar title="Portion mode" subtitle={`Step ${step + 1} of 4`} backTo={() => (step ? setStep(step - 1) : back('log'))} />
      <div class="steps" aria-hidden="true">{[0, 1, 2, 3].map((i) => <i class={i <= step ? 'on' : ''} />)}</div>
      <h2 style={{ marginBottom: '14px' }}>{titles[step]}</h2>

      <div class="screen" key={step}>
        {step === 0 && (
          <div class="container-grid" role="radiogroup" aria-label="Container">
            {CONTAINERS.map((c) => (
              <button class="container-tile" role="radio" aria-pressed={container === c} aria-checked={container === c} onClick={() => { setContainer(c); setFill([]); setStep(1); }}>
                <span class="ct-ico"><FoodIcon name={PORTIONS[c].icon} /></span>
                <strong>{CONTAINER_LABEL[c]}</strong>
                <span>{PORTIONS[c].hint}</span>
              </button>
            ))}
          </div>
        )}

        {step === 1 && container && (
          <>
            <p class="small muted" style={{ marginBottom: '12px' }}>Pick one or more. If it was shared, like rice and beans in one pack, pick both and we'll split it.</p>
            <div class="food-grid">
              {fillFoods.map((f: Food) => (
                <button class="food-tile" aria-pressed={fill.includes(f.id)} onClick={() => toggleFill(f.id)}>
                  <span class="fi-bg"><FoodIcon name={f.icon} class="fi" /></span>
                  <strong>{f.name}</strong>
                  {f.local && <span class="small">{f.local}</span>}
                  <span class="check"><ICheck /></span>
                </button>
              ))}
            </div>
            {container === 'wrap' && fill.length > 0 && (
              <div class="card row-between" style={{ marginTop: '16px', padding: '12px 12px 12px 24px', borderRadius: '999px' }}>
                <strong>How many wraps?</strong>
                <Stepper value={wraps} min={0.5} max={6} step={0.5} onChange={setWraps} />
              </div>
            )}
          </>
        )}

        {step === 2 && (
          <div class="stack">
            {extraIds.map((id) => {
              const f = FOOD_BY_ID[id];
              const n = extras[id] ?? 0;
              const unit = PORTIONS[f.defaultPortion];
              return (
                <div class="choice boxy" aria-pressed={n > 0} style={{ cursor: 'default', paddingRight: '8px' }}>
                  <span class="choice-icon"><FoodIcon name={f.icon} /></span>
                  <span class="grow"><strong>{f.name}</strong><span class="sub">{n > 0 ? `${n} ${n > 1 ? unit.many : unit.one}` : unit.one}</span></span>
                  <Stepper value={n} min={0} max={10} step={f.defaultPortion === 'piece' || f.defaultPortion === 'ball' || f.defaultPortion === 'spoon' || f.defaultPortion === 'handful' ? 1 : 0.5} onChange={(v) => setExtra(id, v)} />
                </div>
              );
            })}
          </div>
        )}

        {step === 3 && (
          <div class="eaten-grid" role="radiogroup" aria-label="How much you ate">
            {EATEN_OPTIONS.map((o) => (
              <button class="eaten-tile" role="radio" aria-pressed={eaten === o.value} aria-checked={eaten === o.value} onClick={() => setEaten(o.value)}>
                <EatenIcon fraction={o.value} />
                <strong>{o.label}</strong>
              </button>
            ))}
          </div>
        )}
      </div>

      {step > 0 && (
        <div class="sticky-cta">
          {step === 1 && <button class="btn btn-primary btn-block" disabled={!fill.length} onClick={() => setStep(2)}>Next</button>}
          {step === 2 && <button class="btn btn-primary btn-block" onClick={() => setStep(3)}>{Object.values(extras).some(Boolean) ? 'Next' : 'Nothing else, next'}</button>}
          {step === 3 && <button class="btn btn-primary btn-block" onClick={finish}>Check my meal</button>}
        </div>
      )}
    </div>
  );
}

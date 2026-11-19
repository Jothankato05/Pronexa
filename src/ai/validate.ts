import { FOOD_BY_ID, PRICES_AS_OF_LABEL } from '../data/foods';
import { PORTIONS } from '../data/portions';
import type { Food, PortionId } from '../data/types';
import { fmtNaira } from '../lib/calc';
import { closestFoods } from './mockInterpreter';
import type { Confidence, DraftItem, Interpretation, Question, RawInterpretation } from './types';

/**
 * The guard rail between "AI interprets" and "the database calculates".
 * Whatever an interpreter returns, only foods and portions that exist in the
 * checked database survive. Price is used only to suggest which portion to confirm.
 */

const EATEN_STEPS = [1, 0.75, 0.5, 0.25];
const SIZE_PORTIONS: PortionId[] = ['sm_pack', 'md_pack', 'lg_pack', 'plate', 'spoon', 'bowl'];
export { newKey } from '../lib/keys';
import { newKey } from '../lib/keys';

function snapEaten(v: unknown): number {
  const n = typeof v === 'number' && isFinite(v) ? v : 1;
  return EATEN_STEPS.reduce((best, s) => (Math.abs(s - n) < Math.abs(best - n) ? s : best), 1);
}

function clampQty(v: unknown, fallback: number): number {
  const n = typeof v === 'number' && isFinite(v) ? v : fallback;
  return Math.min(20, Math.max(0.25, Math.round(n * 4) / 4));
}

const priceMid = (p: [number, number]) => (p[0] + p[1]) / 2;

/** Pick the size whose price range fits the money left for this food. */
function sizeFromPrice(food: Food, money: number): PortionId | null {
  const sized = food.portions.filter((p) => p.price && ['sm_pack', 'md_pack', 'lg_pack', 'plate'].includes(p.id));
  if (!sized.length) return null;
  const inRange = sized.find((p) => money >= p.price![0] && money <= p.price![1]);
  if (inRange) return inRange.id;
  return sized.reduce((best, p) => (Math.abs(priceMid(p.price!) - money) < Math.abs(priceMid(best.price!) - money) ? p : best)).id;
}

export function validate(raw: RawInterpretation, interpreter: string): Interpretation {
  const notes: string[] = [];
  const rejected: string[] = [];
  const items: DraftItem[] = [];

  for (const r of raw.items ?? []) {
    const food = FOOD_BY_ID[r.foodId];
    if (!food) { rejected.push(String(r.foodId)); continue; }
    const validPortion = food.portions.some((p) => p.id === r.portionId);
    items.push({
      key: newKey(),
      foodId: food.id,
      portionId: validPortion ? (r.portionId as PortionId) : food.defaultPortion,
      qty: clampQty(r.qty, food.defaultQty ?? 1),
      eaten: snapEaten(r.eaten),
      portionSource: validPortion ? r.portionSource ?? 'stated' : 'default',
      matched: r.matched,
      generic: r.generic,
    });
  }

  const price = typeof raw.price === 'number' && raw.price > 0 ? raw.price : null;
  let priceMismatch = false;

  // ── Price as a clue ──
  if (price) {
    // Soups and stews usually come with the main food, so leave them out of the sum.
    const priced = items.filter((i) => FOOD_BY_ID[i.foodId].group !== 'soup');
    const uncertain = priced.filter((i) => i.portionSource !== 'stated' && SIZE_PORTIONS.includes(i.portionId) && FOOD_BY_ID[i.foodId].portions.some((p) => ['sm_pack', 'md_pack', 'lg_pack'].includes(p.id)));
    if (uncertain.length === 1) {
      const target = uncertain[0];
      const others = priced.filter((i) => i !== target).reduce((sum, i) => {
        const p = FOOD_BY_ID[i.foodId].portions.find((x) => x.id === i.portionId)?.price;
        return sum + (p ? priceMid(p) * i.qty : 0);
      }, 0);
      const money = Math.max(price - others, price * 0.4);
      const food = FOOD_BY_ID[target.foodId];
      const size = sizeFromPrice(food, money);
      if (size) {
        target.portionId = size;
        target.qty = 1;
        target.portionSource = 'price';
        notes.push(`${fmtNaira(price)} usually buys about a ${PORTIONS[size].one} of ${food.name.toLowerCase()} on campus (prices from ${PRICES_AS_OF_LABEL}). Please check the size.`);
      }
    } else if (priced.length) {
      let lo = 0, hi = 0;
      for (const i of priced) {
        const p = FOOD_BY_ID[i.foodId].portions.find((x) => x.id === i.portionId)?.price;
        if (p) { lo += p[0] * i.qty; hi += p[1] * i.qty; }
      }
      if (hi > 0) {
        if (price > hi * 1.4 || price < lo * 0.6) {
          priceMismatch = true;
          notes.push(`${fmtNaira(price)} is ${price > hi ? 'more' : 'less'} than this usually costs (${fmtNaira(lo)}–${fmtNaira(hi).slice(1)}, ${PRICES_AS_OF_LABEL}). Prices vary, so just check the portions.`);
        } else {
          notes.push(`${fmtNaira(price)} fits ${priced.length === 1 && FOOD_BY_ID[priced[0].foodId] ? 'this portion' : 'these portions'} at typical campus prices (${PRICES_AS_OF_LABEL}).`);
        }
      }
    }
  }

  for (const s of raw.skipped ?? []) notes.push(`Skipped ${s}: no protein to count there.`);
  for (const i of items) {
    if (i.matched === 'meat' && i.foodId === 'beef') notes.push(`Took "meat" as a buka piece of beef. Change it if it was something else.`);
  }

  // ── Confidence ──
  const unknown = (raw.unknown ?? []).filter((u) => u.length >= 3);
  let score = items.length ? 1 : 0;
  score -= unknown.length * 0.3;
  for (const i of items) {
    const isSoup = FOOD_BY_ID[i.foodId].group === 'soup';
    if (i.portionSource === 'price') score -= 0.15;
    else if (i.portionSource === 'size-default') score -= 0.2;
    else if (i.portionSource === 'default') score -= isSoup ? 0.05 : SIZE_PORTIONS.includes(i.portionId) ? 0.3 : 0.1;
    if (i.generic) score -= 0.1;
  }
  if (priceMismatch) score -= 0.2;
  if (rejected.length) score -= 0.2;
  const confidence: Confidence = score >= 0.8 ? 'high' : score >= 0.5 ? 'medium' : 'low';

  return {
    items,
    confidence,
    question: pickQuestion(items, unknown),
    notes,
    unknown,
    price,
    rejected,
    interpreter,
  };
}

/** One simple question, only when it matters. */
export function pickQuestion(items: DraftItem[], unknown: string[]): Question | undefined {
  if (!items.length) return undefined;

  // 1. Something we did not recognise.
  if (unknown.length) {
    const word = unknown[0];
    const close = closestFoods(word.split(' ')[0]);
    if (word === 'soup' || word.endsWith(' soup')) {
      return {
        id: `unknown-${word}`,
        text: 'Which soup was it?',
        options: [...['egusi', 'efo_riro', 'okra', 'ewedu'].map((id) => ({ label: FOOD_BY_ID[id].name, action: { type: 'add' as const, foodId: id } })), { label: 'Skip it', action: { type: 'dismiss' as const } }],
      };
    }
    return {
      id: `unknown-${word}`,
      text: close.length ? `I'm not sure what "${word}" is. Is it one of these?` : `I don't know "${word}" yet. You can add it from Quick pick, or skip it.`,
      options: [...close.map((f) => ({ label: f.name, action: { type: 'add' as const, foodId: f.id } })), { label: 'Skip it', action: { type: 'dismiss' as const } }],
    };
  }

  // 2. A portion we guessed (from price, or a default).
  const guessed = items.find((i) => (i.portionSource === 'price' || i.portionSource === 'size-default' || i.portionSource === 'default') && SIZE_PORTIONS.includes(i.portionId) && FOOD_BY_ID[i.foodId].group !== 'soup');
  if (guessed) {
    const food = FOOD_BY_ID[guessed.foodId];
    const opts = food.portions.filter((p) => SIZE_PORTIONS.includes(p.id)).slice(0, 4);
    return {
      id: `size-${guessed.key}`,
      text: `About how big was the ${food.name.toLowerCase()}?`,
      options: opts.map((p) => ({ label: cap(PORTIONS[p.id].one), action: { type: 'portion' as const, key: guessed.key, portionId: p.id }, selected: p.id === guessed.portionId })),
    };
  }

  // 3. A broad word ("rice").
  const generic = items.find((i) => i.generic && i.foodId === 'white_rice');
  if (generic) {
    return {
      id: `generic-${generic.key}`,
      text: 'Was the rice white, jollof or fried?',
      options: ['white_rice', 'jollof_rice', 'fried_rice'].map((id) => ({ label: FOOD_BY_ID[id].name, action: { type: 'food' as const, key: generic.key, foodId: id }, selected: id === generic.foodId })),
    };
  }
  return undefined;
}

const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

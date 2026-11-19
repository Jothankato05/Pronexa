import { FOOD_BY_ID } from '../data/foods';
import { PORTIONS } from '../data/portions';
import type { Activity, Food, FoodPortion, MealItem, PortionId, Profile, Range } from '../data/types';

/**
 * The calculation engine. Plain, explainable arithmetic:
 *   protein = proteinPer100g × portion grams × qty × fraction eaten ÷ 100
 * and an uncertainty band from the kind of portion. No AI touches these numbers.
 */

export const range = (min: number, max: number): Range => ({ min, max, mid: (min + max) / 2 });
export const ZERO: Range = range(0, 0);

export function addRanges(a: Range, b: Range): Range {
  return range(a.min + b.min, a.max + b.max);
}

export function portionOf(food: Food, portionId: PortionId): FoodPortion {
  return food.portions.find((p) => p.id === portionId) ?? food.portions.find((p) => p.id === food.defaultPortion) ?? food.portions[0];
}

export function itemProtein(item: MealItem): Range {
  const food = FOOD_BY_ID[item.foodId];
  if (!food) return ZERO;
  const portion = portionOf(food, item.portionId);
  const u = PORTIONS[portion.id]?.uncertainty ?? 0.25;
  const mid = (food.proteinPer100g * portion.grams * item.qty * item.eaten) / 100;
  return range(mid * (1 - u), mid * (1 + u));
}

export function itemsProtein(items: MealItem[]): Range {
  return items.reduce((acc, it) => addRanges(acc, itemProtein(it)), ZERO);
}

export function itemPrice(item: MealItem): [number, number] | null {
  const food = FOOD_BY_ID[item.foodId];
  if (!food) return null;
  const p = portionOf(food, item.portionId).price;
  if (!p) return null;
  return [p[0] * item.qty, p[1] * item.qty];
}

// ── Daily target ─────────────────────────────────────────────

export const ACTIVITY: Record<Activity, { label: string; detail: string; gPerKg: [number, number] }> = {
  light: { label: 'Mostly sitting', detail: 'Lectures, reading, not much walking', gPerKg: [0.8, 0.9] },
  moderate: { label: 'On my feet a lot', detail: 'Walking around campus most days', gPerKg: [0.9, 1.1] },
  active: { label: 'Active', detail: 'Exercise or sport 3+ times a week', gPerKg: [1.1, 1.4] },
  athlete: { label: 'Training hard', detail: 'Team sport, gym or heavy physical work', gPerKg: [1.4, 1.7] },
};

export const DEFAULT_WEIGHT_KG = 60;

export function proteinTarget(profile: Pick<Profile, 'weightKg' | 'activity'>): Range {
  const kg = profile.weightKg ?? DEFAULT_WEIGHT_KG;
  const [lo, hi] = ACTIVITY[profile.activity].gPerKg;
  return range(Math.round(kg * lo), Math.round(kg * hi));
}

/** What is left to eat. Clamped at zero so the gap never goes negative. */
export function proteinGap(target: Range, eaten: Range): Range {
  const min = Math.max(0, target.mid - eaten.max);
  const max = Math.max(0, target.mid - eaten.min);
  return { min, max, mid: Math.max(0, target.mid - eaten.mid) };
}

// ── Formatting ───────────────────────────────────────────────

/** "about 18–24 g" style ranges, with a tidy single value when the band is tiny. */
export function fmtRange(r: Range, unit = 'g'): string {
  const lo = Math.round(r.min);
  const hi = Math.round(r.max);
  if (hi <= 0) return `0 ${unit}`;
  if (hi - lo <= 1) return `${Math.round(r.mid)} ${unit}`;
  return `${lo}–${hi} ${unit}`;
}

export function fmtNaira(n: number): string {
  return '₦' + Math.round(n).toLocaleString('en-NG');
}

export function fmtNairaRange(p: [number, number]): string {
  return p[0] === p[1] ? fmtNaira(p[0]) : `${fmtNaira(p[0])}–${fmtNaira(p[1]).slice(1)}`;
}

const FRACTIONS: Record<string, string> = { '0.25': '¼', '0.5': '½', '0.75': '¾' };

export function fmtQty(qty: number): string {
  const whole = Math.floor(qty);
  const frac = +(qty - whole).toFixed(2);
  const f = FRACTIONS[String(frac)];
  if (!f) return String(+qty.toFixed(2));
  return whole ? `${whole}${f}` : f;
}

export function portionLabel(item: Pick<MealItem, 'foodId' | 'portionId' | 'qty'>): string {
  const food = FOOD_BY_ID[item.foodId];
  const meta = PORTIONS[item.portionId];
  const custom = food ? portionOf(food, item.portionId).label : undefined;
  const base = custom ?? (item.qty > 1 ? meta.many : meta.one);
  const noun = custom && item.qty > 1 ? pluralise(custom) : base;
  return `${fmtQty(item.qty)} ${noun}`;
}

const NOUN_PLURALS: Record<string, string> = { piece: 'pieces', slice: 'slices', wrap: 'wraps', sachet: 'sachets', spoon: 'spoons', tin: 'tins', bottle: 'bottles', pack: 'packs', egg: 'eggs', handful: 'handfuls', cup: 'cups', serving: 'servings', ball: 'balls' };

/** Pluralise the head noun only: "serving spoon of stew" → "serving spoons of stew", "piece (buka size)" → "pieces (buka size)". */
export function pluralise(label: string): string {
  const cut = label.search(/ \(| \/| of /);
  const head = cut === -1 ? label : label.slice(0, cut);
  const rest = cut === -1 ? '' : label.slice(cut);
  const words = head.split(' ');
  for (let i = words.length - 1; i >= 0; i--) {
    const w = words[i];
    if (NOUN_PLURALS[w]) { words[i] = NOUN_PLURALS[w]; return words.join(' ') + rest; }
  }
  return label;
}

export const EATEN_LABEL: Record<string, string> = { '1': 'all', '0.75': '¾ eaten', '0.5': 'half eaten', '0.25': '¼ eaten' };

export function describeItems(items: MealItem[]): string {
  const names = items.map((i) => FOOD_BY_ID[i.foodId]?.name.toLowerCase()).filter(Boolean) as string[];
  const tidy = names.map((n) => n.replace('white rice', 'rice').replace('tomato stew', 'stew').replace('boiled yam', 'yam').replace('fried plantain', 'dodo'));
  if (tidy.length <= 1) return tidy[0] ?? 'meal';
  return tidy.slice(0, -1).join(', ') + ' and ' + tidy[tidy.length - 1];
}

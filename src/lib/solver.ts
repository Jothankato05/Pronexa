import { FOOD_BY_ID, FOODS } from '../data/foods';
import type { Allergen, Diet, Food, Meal, MealItem, PortionId, Range } from '../data/types';
import { addRanges, describeItems, itemPrice, itemProtein, itemsProtein, ZERO } from './calc';
export { describeItems } from './calc';
import { isPlant, suggestionFit } from './diet';

/**
 * Protein Gap Solver. Deterministic ranking, so it works offline:
 *   score = 0.65 × value (protein per ₦, normalised) + 0.25 × how much of the gap it closes + 0.10 plant bonus
 * Plant-first mode puts every plant option above animal options.
 * The one-line reasons are templates; an LLM may rephrase them later, but never the numbers.
 */

export interface SolverInput {
  gap: Range;
  budget: number;
  diet: Diet;
  allergies: Allergen[];
  plantFirst: boolean;
  meals: Meal[];
}

export interface Suggestion {
  foodId: string;
  item: MealItem;
  protein: Range;
  price: [number, number];
  priceMid: number;
  /** grams of protein per ₦100 (mid estimates) */
  per100: number;
  plant: boolean;
  ready: boolean;
  reason: string;
  caveat?: string;
  /** 0..1 share of the remaining gap this closes */
  gapShare: number;
  score: number;
}

export interface Combo {
  id: string;
  title: string;
  subtitle: string;
  items: Suggestion[];
  protein: Range;
  cost: number;
  closesGap: boolean;
}

export interface Upgrade {
  id: string;
  mealId?: string;
  title: string;
  kind: 'add' | 'swap';
  suggestion: Suggestion;
  fromFoodId?: string;
  proteinChange: Range;
  costChange: number;
  reason: string;
}

export interface SolverResult {
  closed: boolean;
  ranked: Suggestion[];
  combos: Combo[];
  upgrades: Upgrade[];
  excludedCount: number;
}

/** How each food is suggested: a sensible unit a student would actually buy or cook. */
const SUGGEST_UNIT: Record<string, { portionId: PortionId; qty: number }> = {
  soybeans: { portionId: 'spoon', qty: 1 },
  soya_chunks: { portionId: 'handful', qty: 1 },
  groundnuts: { portionId: 'sachet', qty: 1 },
  beans: { portionId: 'spoon', qty: 2 },
  akara: { portionId: 'ball', qty: 4 },
  tofu: { portionId: 'piece', qty: 3 },
  moi_moi: { portionId: 'wrap', qty: 1 },
  okpa: { portionId: 'wrap', qty: 1 },
  lentils: { portionId: 'spoon', qty: 2 },
  soy_milk: { portionId: 'bottle', qty: 1 },
  egg: { portionId: 'piece', qty: 2 },
  beef: { portionId: 'piece', qty: 2 },
  fish: { portionId: 'piece', qty: 1 },
  chicken: { portionId: 'piece', qty: 1 },
  sardine: { portionId: 'tin', qty: 1 },
  milk: { portionId: 'sachet', qty: 1 },
};

/** Bought ready to eat from a vendor, no cooking needed. */
const READY = new Set(['moi_moi', 'akara', 'okpa', 'groundnuts', 'soy_milk', 'tofu', 'egg', 'beans', 'chicken', 'beef', 'fish', 'sardine', 'milk']);

/** Natural pairings for staple-heavy meals (Nigerian combos people already eat). */
const PAIRINGS: Record<string, string[]> = {
  white_rice: ['beans', 'moi_moi', 'soya_chunks', 'tofu', 'egg', 'fish', 'beef'],
  jollof_rice: ['moi_moi', 'beans', 'soya_chunks', 'egg', 'fish', 'beef'],
  fried_rice: ['moi_moi', 'soya_chunks', 'egg', 'beef'],
  yam: ['akara', 'beans', 'groundnuts', 'egg', 'fish'],
  plantain: ['beans', 'akara', 'egg'],
  bread: ['akara', 'groundnuts', 'soy_milk', 'egg', 'sardine'],
  garri_soaked: ['groundnuts', 'soy_milk', 'milk'],
  noodles: ['soya_chunks', 'egg', 'tofu'],
  spaghetti: ['soya_chunks', 'beans', 'egg', 'sardine'],
  eba: ['tofu', 'soya_chunks', 'fish', 'beef'],
  amala: ['tofu', 'beans', 'fish', 'beef'],
  pounded_yam: ['tofu', 'soya_chunks', 'fish', 'beef'],
  tuwo: ['beans', 'tofu', 'fish', 'beef'],
  abacha: ['groundnuts', 'fish'],
};

const PAIR_LINE: Record<string, string> = {
  beans: 'Rice and beans is a classic: a spoon or two on top makes a big difference.',
  moi_moi: 'A wrap of moi-moi on the side turns rice into a proper protein meal.',
  soya_chunks: 'Stir soaked soya chunks into the stew: same taste, far more protein.',
  tofu: 'Ask for awara in your stew. It soaks up the flavour.',
  akara: 'Akara with yam or bread is a breakfast favourite for a reason.',
  groundnuts: 'A handful of groundnuts on the side is the easiest upgrade there is.',
  soy_milk: 'A bottle of soy milk makes it a full breakfast.',
  milk: 'Two spoons of milk adds a little protein, no stress.',
  egg: 'One or two eggs on top adds solid protein.',
  fish: 'A piece of fish in your soup closes a good chunk of the gap.',
  beef: 'An extra piece of meat in your soup counts.',
  sardine: 'A tin of sardines with bread is a quick protein lunch.',
};

const SOUP_SWAPS: Record<string, string> = { okra: 'egusi', ewedu: 'egusi', efo_riro: 'egusi' };

export function makeSuggestion(food: Food, gap: Range, caveat?: string, override?: { portionId: PortionId; qty: number }): Suggestion | null {
  const unit = override ?? SUGGEST_UNIT[food.id] ?? { portionId: food.defaultPortion, qty: food.defaultQty ?? 1 };
  const item: MealItem = { foodId: food.id, portionId: unit.portionId, qty: unit.qty, eaten: 1 };
  const price = itemPrice(item);
  if (!price) return null;
  const protein = itemProtein(item);
  const priceMid = (price[0] + price[1]) / 2;
  const per100 = (protein.mid / priceMid) * 100;
  const gapShare = gap.mid > 0 ? Math.min(1, protein.mid / gap.mid) : 0;
  return {
    foodId: food.id,
    item,
    protein,
    price,
    priceMid,
    per100,
    plant: isPlant(food),
    ready: READY.has(food.id),
    reason: food.pitch ?? `${food.name} adds protein to your day.`,
    caveat,
    gapShare,
    score: 0,
  };
}

function rank(list: Suggestion[], plantFirst: boolean): Suggestion[] {
  const maxPer = Math.max(...list.map((s) => s.per100), 0.0001);
  for (const s of list) {
    s.score = 0.65 * (s.per100 / maxPer) + 0.25 * s.gapShare + (s.plant ? 0.1 : 0);
  }
  return [...list].sort((a, b) => {
    if (plantFirst && a.plant !== b.plant) return a.plant ? -1 : 1;
    return b.score - a.score;
  });
}

function buildCombo(id: string, title: string, subtitle: string, pool: Suggestion[], gap: Range, budget: number): Combo | null {
  if (gap.mid <= 0 || !pool.length) return null;
  const chosen: Suggestion[] = [];
  let protein = ZERO;
  let cost = 0;
  const counts: Record<string, number> = {};
  // Two passes: first variety (one of each), then allow a second unit of the best ones.
  for (let pass = 0; pass < 2 && protein.mid < gap.mid; pass++) {
    for (const s of pool) {
      if (protein.mid >= gap.mid) break;
      const distinct = Object.keys(counts).length;
      if (!counts[s.foodId] && distinct >= 3) continue;
      if ((counts[s.foodId] ?? 0) > pass) continue;
      if (cost + s.priceMid > budget) continue;
      chosen.push(s);
      counts[s.foodId] = (counts[s.foodId] ?? 0) + 1;
      protein = addRanges(protein, s.protein);
      cost += s.priceMid;
    }
  }
  if (!chosen.length) return null;
  // Merge repeated foods into one line with a higher qty.
  const merged: Suggestion[] = [];
  for (const s of chosen) {
    const existing = merged.find((m) => m.foodId === s.foodId);
    if (existing) {
      existing.item = { ...existing.item, qty: existing.item.qty + s.item.qty };
      existing.protein = addRanges(existing.protein, s.protein);
      existing.price = [existing.price[0] + s.price[0], existing.price[1] + s.price[1]];
      existing.priceMid += s.priceMid;
    } else merged.push({ ...s, item: { ...s.item } });
  }
  return { id, title, subtitle, items: merged, protein, cost, closesGap: protein.mid >= gap.mid };
}


const EXAMPLE_MEALS: { title: string; items: MealItem[] }[] = [
  { title: 'Rice and stew', items: [{ foodId: 'white_rice', portionId: 'md_pack', qty: 1, eaten: 1 }, { foodId: 'stew', portionId: 'spoon', qty: 2, eaten: 1 }] },
  { title: 'Yam and sauce', items: [{ foodId: 'yam', portionId: 'slice', qty: 2, eaten: 1 }, { foodId: 'stew', portionId: 'spoon', qty: 2, eaten: 1 }] },
  { title: 'Eba and okra soup', items: [{ foodId: 'eba', portionId: 'wrap', qty: 1, eaten: 1 }, { foodId: 'okra', portionId: 'serving', qty: 1, eaten: 1 }] },
];

function upgradesFor(input: SolverInput, fits: Map<string, string | undefined>): Upgrade[] {
  const { gap, budget, plantFirst } = input;
  const sources = input.meals.length
    ? [...input.meals].sort((a, b) => b.time - a.time).map((m) => ({ mealId: m.id, title: capitalise(describeItems(m.items)), items: m.items }))
    : EXAMPLE_MEALS.map((m) => ({ mealId: undefined as string | undefined, ...m }));

  const out: Upgrade[] = [];
  const usedAdds = new Set<string>();
  for (const meal of sources) {
    if (out.length >= 3) break;
    const p = itemsProtein(meal.items);
    if (p.mid >= 20) continue; // already a protein-rich meal, leave it alone
    const ids = meal.items.map((i) => i.foodId);

    // Soup swap first: same swallow, richer soup.
    const soup = ids.find((id) => SOUP_SWAPS[id]);
    if (soup && fits.has(SOUP_SWAPS[soup])) {
      const toFood = FOOD_BY_ID[SOUP_SWAPS[soup]];
      const fromItem = meal.items.find((i) => i.foodId === soup)!;
      const fromFood = FOOD_BY_ID[soup];
      const sug = makeSuggestion(toFood, gap, fits.get(toFood.id), { portionId: fromItem.portionId, qty: fromItem.qty });
      const fromPrice = itemPrice({ ...fromItem, eaten: 1 });
      if (sug && fromPrice) {
        const fromProt = itemProtein({ ...fromItem, eaten: 1 });
        out.push({
          id: `swap-${meal.mealId ?? meal.title}-${soup}`,
          mealId: meal.mealId,
          title: meal.title,
          kind: 'swap',
          suggestion: sug,
          fromFoodId: soup,
          proteinChange: { min: sug.protein.min - fromProt.max, max: sug.protein.max - fromProt.min, mid: sug.protein.mid - fromProt.mid },
          costChange: sug.priceMid - (fromPrice[0] + fromPrice[1]) / 2,
          reason: `Egusi's melon seeds carry more protein than ${fromFood.name.toLowerCase()}. Same swallow, more protein.`,
        });
        continue;
      }
    }

    const staple = ids.find((id) => PAIRINGS[id]);
    if (!staple) continue;
    const candidates = PAIRINGS[staple]
      .filter((id) => fits.has(id) && !ids.includes(id))
      .map((id) => makeSuggestion(FOOD_BY_ID[id], gap, fits.get(id)))
      .filter((s): s is Suggestion => !!s && s.price[0] <= budget);
    if (!candidates.length) continue;
    const ranked = rank(candidates, plantFirst);
    const pick = ranked.find((s) => !usedAdds.has(s.foodId)) ?? ranked[0];
    usedAdds.add(pick.foodId);
    out.push({
      id: `add-${meal.mealId ?? meal.title}-${pick.foodId}`,
      mealId: meal.mealId,
      title: meal.title,
      kind: 'add',
      suggestion: pick,
      proteinChange: pick.protein,
      costChange: pick.priceMid,
      reason: PAIR_LINE[pick.foodId] ?? pick.reason,
    });
  }
  return out;
}

export function solve(input: SolverInput): SolverResult {
  const fits = new Map<string, string | undefined>();
  let excludedCount = 0;
  for (const f of FOODS) {
    const fit = suggestionFit(f, input.diet, input.allergies);
    if (fit.ok) fits.set(f.id, fit.caveat);
    else if (SUGGEST_UNIT[f.id]) excludedCount++;
  }

  const pool = Object.keys(SUGGEST_UNIT)
    .filter((id) => fits.has(id))
    .map((id) => makeSuggestion(FOOD_BY_ID[id], input.gap, fits.get(id)))
    .filter((s): s is Suggestion => !!s && s.price[0] <= input.budget);

  const ranked = rank(pool, input.plantFirst);
  const byValue = [...ranked].sort((a, b) => (input.plantFirst && a.plant !== b.plant ? (a.plant ? -1 : 1) : b.per100 - a.per100));

  const combos: Combo[] = [];
  const best = buildCombo('value', `Best value for ${'₦' + input.budget.toLocaleString('en-NG')}`, 'Most protein for your money', byValue, input.gap, input.budget);
  if (best) combos.push(best);
  const ready = buildCombo('ready', 'No cooking needed', 'Buy it ready from a vendor', byValue.filter((s) => s.ready), input.gap, input.budget);
  if (ready && JSON.stringify(ready.items.map((i) => i.foodId)) !== JSON.stringify(best?.items.map((i) => i.foodId))) combos.push(ready);

  return {
    closed: input.gap.mid <= 0,
    ranked,
    combos,
    upgrades: upgradesFor(input, fits),
    excludedCount,
  };
}

function capitalise(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}


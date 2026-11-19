import { describe, expect, it } from 'vitest';
import { parseMeal } from '../src/ai/mockInterpreter';
import { validate } from '../src/ai/validate';
import { FOOD_BY_ID, FOODS } from '../src/data/foods';
import { fmtRange, itemProtein, pluralise, portionLabel, proteinGap, proteinTarget, range } from '../src/lib/calc';
import { suggestionFit } from '../src/lib/diet';
import { solve } from '../src/lib/solver';
import type { Diet } from '../src/data/types';

describe('food database', () => {
  it('has about 30 foods, each with a valid default portion', () => {
    expect(FOODS.length).toBeGreaterThanOrEqual(30);
    for (const f of FOODS) {
      expect(f.portions.some((p) => p.id === f.defaultPortion), f.id).toBe(true);
      expect(f.proteinPer100g, f.id).toBeGreaterThan(0);
      expect(f.source.length, f.id).toBeGreaterThan(5);
    }
  });
  it('has unique ids', () => {
    expect(new Set(FOODS.map((f) => f.id)).size).toBe(FOODS.length);
  });
});

describe('calculation engine', () => {
  it('computes a medium pack of rice and beans as a range', () => {
    const p = itemProtein({ foodId: 'rice_beans', portionId: 'md_pack', qty: 1, eaten: 1 });
    // 400 g × 4.8 g/100 g = 19.2 g ± 25%
    expect(p.mid).toBeCloseTo(19.2, 1);
    expect(p.min).toBeCloseTo(14.4, 1);
    expect(p.max).toBeCloseTo(24, 1);
    expect(fmtRange(p)).toBe('14–24 g');
  });
  it('scales by amount eaten', () => {
    const all = itemProtein({ foodId: 'beans', portionId: 'spoon', qty: 2, eaten: 1 });
    const half = itemProtein({ foodId: 'beans', portionId: 'spoon', qty: 2, eaten: 0.5 });
    expect(half.mid).toBeCloseTo(all.mid / 2);
  });
  it('estimates a target from weight and activity', () => {
    const t = proteinTarget({ weightKg: 60, activity: 'moderate' });
    expect(t.min).toBe(54);
    expect(t.max).toBe(66);
    expect(proteinTarget({ weightKg: null, activity: 'light' }).mid).toBeGreaterThan(40);
  });
  it('never returns a negative gap', () => {
    expect(proteinGap(range(50, 60), range(70, 80)).mid).toBe(0);
  });
});

describe('dietary safety', () => {
  const animalIds = FOODS.filter((f) => f.animal).map((f) => f.id);

  it('never suggests animal products to vegans, in any budget or mode', () => {
    for (const budget of [200, 500, 1000, 3000]) {
      for (const plantFirst of [true, false]) {
        const r = solve({ gap: range(30, 40), budget, diet: 'vegan', allergies: [], plantFirst, meals: [] });
        const ids = [...r.ranked.map((s) => s.foodId), ...r.combos.flatMap((c) => c.items.map((i) => i.foodId)), ...r.upgrades.map((u) => u.suggestion.foodId)];
        for (const id of ids) expect(animalIds, `${id} suggested to vegan`).not.toContain(id);
        // Soups that may contain crayfish/meat stock are not suggested either.
        expect(ids).not.toContain('egusi');
      }
    }
  });

  it('respects vegetarian, pescatarian, dairy-free and egg-free', () => {
    const cases: [Diet, string[]][] = [
      ['vegetarian', ['beef', 'chicken', 'fish', 'sardine']],
      ['pescatarian', ['beef', 'chicken']],
      ['dairy_free', ['milk']],
      ['egg_free', ['egg']],
    ];
    for (const [diet, banned] of cases) {
      const r = solve({ gap: range(30, 40), budget: 5000, diet, allergies: [], plantFirst: false, meals: [] });
      for (const id of banned) expect(r.ranked.map((s) => s.foodId)).not.toContain(id);
    }
  });

  it('excludes allergens, including "may contain"', () => {
    const r = solve({ gap: range(30, 40), budget: 5000, diet: 'none', allergies: ['peanut', 'soy', 'shellfish'], plantFirst: false, meals: [] });
    const ids = r.ranked.map((s) => s.foodId);
    for (const id of ['groundnuts', 'soybeans', 'soya_chunks', 'tofu', 'soy_milk', 'moi_moi']) expect(ids).not.toContain(id);
  });

  it('shows plain moi-moi to vegans with a caveat', () => {
    const fit = suggestionFit(FOOD_BY_ID.moi_moi, 'vegan', []);
    expect(fit.ok).toBe(true);
    if (fit.ok) expect(fit.caveat).toMatch(/plain/);
  });
});

describe('gap solver', () => {
  it('ranks plant proteins first in plant-first mode', () => {
    const r = solve({ gap: range(25, 30), budget: 3000, diet: 'none', allergies: [], plantFirst: true, meals: [] });
    const firstAnimal = r.ranked.findIndex((s) => !s.plant);
    const lastPlant = r.ranked.map((s) => s.plant).lastIndexOf(true);
    expect(firstAnimal).toBeGreaterThan(lastPlant);
  });

  it('builds a combo within budget that targets the gap', () => {
    const r = solve({ gap: range(25, 30), budget: 500, diet: 'vegan', allergies: [], plantFirst: true, meals: [] });
    expect(r.combos.length).toBeGreaterThan(0);
    for (const c of r.combos) expect(c.cost).toBeLessThanOrEqual(500);
  });

  it('upgrades a low-protein meal with a natural pairing', () => {
    const meal = { id: 'm1', date: '2026-11-19', time: 1, source: 'quick' as const, synced: false, updatedAt: 1, items: [{ foodId: 'white_rice', portionId: 'md_pack' as const, qty: 1, eaten: 1 }, { foodId: 'stew', portionId: 'spoon' as const, qty: 2, eaten: 1 }] };
    const r = solve({ gap: range(30, 40), budget: 1000, diet: 'none', allergies: [], plantFirst: true, meals: [meal] });
    expect(r.upgrades[0]?.mealId).toBe('m1');
    expect(['beans', 'moi_moi', 'soya_chunks', 'tofu']).toContain(r.upgrades[0].suggestion.foodId);
  });

  it('swaps okra soup for egusi when the diet allows', () => {
    const meal = { id: 'm2', date: '2026-11-19', time: 1, source: 'quick' as const, synced: false, updatedAt: 1, items: [{ foodId: 'eba', portionId: 'wrap' as const, qty: 1, eaten: 1 }, { foodId: 'okra', portionId: 'serving' as const, qty: 1, eaten: 1 }] };
    const r = solve({ gap: range(30, 40), budget: 1000, diet: 'none', allergies: [], plantFirst: false, meals: [meal] });
    const swap = r.upgrades.find((u) => u.kind === 'swap');
    expect(swap?.suggestion.foodId).toBe('egusi');
    expect(swap!.proteinChange.mid).toBeGreaterThan(0);
  });
});

describe('AI guard rails', () => {
  it('drops foods that are not in the database', () => {
    const v = validate({ items: [{ foodId: 'shawarma' }, { foodId: 'beans', portionId: 'spoon', qty: 2 }], unknown: [], skipped: [] }, 'test');
    expect(v.items.map((i) => i.foodId)).toEqual(['beans']);
    expect(v.rejected).toEqual(['shawarma']);
  });
  it('replaces invalid portions with the default and clamps quantities', () => {
    const v = validate({ items: [{ foodId: 'egg', portionId: 'lg_pack', qty: 999, eaten: 0.6 }], unknown: [], skipped: [] }, 'test');
    expect(v.items[0].portionId).toBe('piece');
    expect(v.items[0].qty).toBe(20);
    expect(v.items[0].eaten).toBe(0.5);
  });
  it('uses price only to suggest a size, and asks to confirm it', () => {
    const v = validate(parseMeal('rice and stew 700 naira'), 'test');
    const rice = v.items.find((i) => i.foodId === 'white_rice')!;
    expect(rice.portionSource).toBe('price');
    expect(v.confidence).not.toBe('high');
    expect(v.question?.text).toMatch(/how big/i);
  });
  it('is confident about the demo sentence', () => {
    const v = validate(parseMeal('₦1,000 rice and beans, medium takeaway'), 'test');
    expect(v.confidence).toBe('high');
    expect(v.question).toBeUndefined();
  });
  it('asks about words it does not know', () => {
    const v = validate(parseMeal('rice and shawarma'), 'test');
    expect(v.unknown).toContain('shawarma');
    expect(v.question?.options.some((o) => o.action.type === 'dismiss')).toBe(true);
  });
  it('skips no-protein items kindly', () => {
    const v = validate(parseMeal('bread and tea'), 'test');
    expect(v.notes.join(' ')).toMatch(/Skipped tea/);
  });
});

describe('labels', () => {
  it('pluralises the head noun only', () => {
    expect(pluralise('serving spoon of stew')).toBe('serving spoons of stew');
    expect(pluralise('piece (buka size)')).toBe('pieces (buka size)');
    expect(pluralise('sachet / 2 spoons')).toBe('sachets / 2 spoons');
    expect(pluralise('thick slice')).toBe('thick slices');
    expect(portionLabel({ foodId: 'stew', portionId: 'spoon', qty: 2 })).toBe('2 serving spoons of stew');
    expect(portionLabel({ foodId: 'beef', portionId: 'piece', qty: 1 })).toBe('1 piece (buka size)');
  });
  it('does not suggest unrelated foods for unknown words', () => {
    const v = validate(parseMeal('rice and shawarma'), 'test');
    expect(v.question?.options.map((o) => o.label)).toEqual(['Skip it']);
  });
});

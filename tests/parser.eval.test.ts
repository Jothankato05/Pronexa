import { describe, expect, it } from 'vitest';
import { parseMeal } from '../src/ai/mockInterpreter';
import { validate } from '../src/ai/validate';

/**
 * The Describe-it test set (brief, section 7): ~30 descriptions, including Pidgin and
 * price-based ones. Each case lists the foods we expect, and optionally a portion.
 * Run `npm run eval` to see per-case results and the accuracy summary.
 */
type Case = { text: string; foods: string[]; portions?: Record<string, string>; qty?: Record<string, number>; eaten?: number };

const CASES: Case[] = [
  { text: '₦1,000 rice and beans, medium takeaway', foods: ['rice_beans'], portions: { rice_beans: 'md_pack' } },
  { text: 'I chop 2 wraps of eba with egusi and one meat', foods: ['eba', 'egusi', 'beef'], qty: { eba: 2, beef: 1 } },
  { text: 'rice and stew 700 naira', foods: ['white_rice', 'stew'], portions: { white_rice: 'sm_pack' } },
  { text: 'jollof rice big pack with chicken', foods: ['jollof_rice', 'chicken'], portions: { jollof_rice: 'lg_pack' } },
  { text: '₦500 beans', foods: ['beans'] },
  { text: 'agege bread and 5 akara', foods: ['bread', 'akara'], qty: { akara: 5 } },
  { text: 'amala and ewedu with 2 meat', foods: ['amala', 'ewedu', 'beef'], qty: { beef: 2 } },
  { text: 'small indomie with egg', foods: ['noodles', 'egg'] },
  { text: 'soaked garri with groundnut and milk', foods: ['garri_soaked', 'groundnuts', 'milk'] },
  { text: 'I buy moi moi for 500', foods: ['moi_moi'] },
  { text: 'yam and egg sauce', foods: ['yam', 'egg', 'stew'] },
  { text: 'beans and dodo', foods: ['beans', 'plantain'] },
  { text: 'pounded yam with efo riro and fish', foods: ['pounded_yam', 'efo_riro', 'fish'] },
  { text: 'one okpa', foods: ['okpa'], qty: { okpa: 1 } },
  { text: 'jollof spaghetti medium pack', foods: ['spaghetti'], portions: { spaghetti: 'md_pack' } },
  { text: 'tuwo shinkafa and okra soup', foods: ['tuwo', 'okra'] },
  { text: 'abacha one plate', foods: ['abacha'], portions: { abacha: 'plate' } },
  { text: 'fried rice and chicken 2500', foods: ['fried_rice', 'chicken'] },
  { text: 'bread and sardine', foods: ['bread', 'sardine'] },
  { text: 'two boiled eggs and tea', foods: ['egg'], qty: { egg: 2 } },
  { text: 'soya chunks in my stew with white rice', foods: ['soya_chunks', 'stew', 'white_rice'] },
  { text: 'awara and pap', foods: ['tofu'] },
  { text: 'lentil porridge one bowl', foods: ['lentils'], portions: { lentils: 'bowl' } },
  { text: 'soy milk and akara', foods: ['soy_milk', 'akara'] },
  { text: 'ewa agoyin with agege, ₦800', foods: ['beans', 'bread'] },
  { text: 'I chop half plate of rice', foods: ['white_rice'], portions: { white_rice: 'plate' }, qty: { white_rice: 0.5 } },
  { text: 'eba 1 wrap and vegetable soup, I no finish am', foods: ['eba', 'efo_riro'], eaten: 0.75 },
  { text: 'groundnut 1 sachet', foods: ['groundnuts'], portions: { groundnuts: 'sachet' } },
  { text: 'jolof rice and moimoi', foods: ['jollof_rice', 'moi_moi'] },
  { text: '1k rice n beans plus 1 meat', foods: ['rice_beans', 'beef'] },
  { text: 'garri and egusi soup', foods: ['eba', 'egusi'] },
  { text: 'soybeans one spoon and boiled yam', foods: ['soybeans', 'yam'] },
];

function check(c: Case) {
  const raw = parseMeal(c.text);
  const got = raw.items.map((i) => i.foodId).sort();
  const foodsOk = JSON.stringify(got) === JSON.stringify([...c.foods].sort());
  const byFood = Object.fromEntries(raw.items.map((i) => [i.foodId, i]));
  let portionOk = true;
  for (const [f, p] of Object.entries(c.portions ?? {})) {
    // Price-inferred portions are decided in validate(), so check after validation.
    const v = validate(raw, 't').items.find((i) => i.foodId === f);
    if (v?.portionId !== p) portionOk = false;
  }
  for (const [f, q] of Object.entries(c.qty ?? {})) if (byFood[f]?.qty !== q) portionOk = false;
  if (c.eaten !== undefined && raw.items.some((i) => i.eaten !== c.eaten)) portionOk = false;
  return { foodsOk, portionOk, got, raw };
}

describe('Describe-it test set', () => {
  const results = CASES.map((c) => ({ c, ...check(c) }));

  for (const r of results) {
    it(r.c.text, () => {
      expect(r.got, `foods for "${r.c.text}"`).toEqual([...r.c.foods].sort());
      expect(r.portionOk, `portion for "${r.c.text}": ${JSON.stringify(r.raw.items)}`).toBe(true);
    });
  }

  it('reports accuracy', () => {
    const foods = results.filter((r) => r.foodsOk).length;
    const both = results.filter((r) => r.foodsOk && r.portionOk).length;
    console.log(`\nDescribe-it accuracy: foods ${foods}/${results.length}, foods+portion ${both}/${results.length}\n`);
    expect(foods / results.length).toBeGreaterThanOrEqual(0.9);
  });
});

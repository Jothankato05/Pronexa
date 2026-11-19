import type { Allergen, AnimalKind, Diet, Food } from '../data/types';

export const DIETS: { id: Diet; label: string; detail: string }[] = [
  { id: 'none', label: 'No restrictions', detail: 'I eat everything' },
  { id: 'vegetarian', label: 'Vegetarian', detail: 'No meat or fish' },
  { id: 'vegan', label: 'Vegan', detail: 'Plants only, no animal products' },
  { id: 'pescatarian', label: 'Pescatarian', detail: 'Fish, but no other meat' },
  { id: 'dairy_free', label: 'Dairy-free', detail: 'No milk products' },
  { id: 'egg_free', label: 'Egg-free', detail: 'No eggs' },
];

export const ALLERGENS: { id: Allergen; label: string }[] = [
  { id: 'peanut', label: 'Groundnut / peanut' },
  { id: 'soy', label: 'Soy' },
  { id: 'egg', label: 'Egg' },
  { id: 'milk', label: 'Milk' },
  { id: 'fish', label: 'Fish' },
  { id: 'shellfish', label: 'Shellfish / crayfish' },
  { id: 'gluten', label: 'Wheat / gluten' },
  { id: 'sesame', label: 'Sesame (beniseed)' },
];

const EXCLUDES: Record<Diet, AnimalKind[]> = {
  none: [],
  vegetarian: ['meat', 'fish'],
  vegan: ['meat', 'fish', 'egg', 'dairy'],
  pescatarian: ['meat'],
  dairy_free: ['dairy'],
  egg_free: ['egg'],
};

export function excludedAnimals(diet: Diet): AnimalKind[] {
  return EXCLUDES[diet];
}

export type Fit = { ok: true; caveat?: string } | { ok: false; why: string };

/**
 * Can Pronexa SUGGEST this food to this person? This is strict: a vegan is never
 * shown an animal product. Foods that may contain animal ingredients are shown only
 * if a plain version is easy to ask for, and then with a caveat.
 */
export function suggestionFit(food: Food, diet: Diet, allergies: Allergen[]): Fit {
  const excluded = EXCLUDES[diet];
  if (food.animal && excluded.includes(food.animal)) return { ok: false, why: 'diet' };
  const allergic = food.allergens.find((a) => allergies.includes(a));
  if (allergic) return { ok: false, why: 'allergy' };
  const mayAllergen = food.mayContainAllergens?.find((a) => allergies.includes(a));
  if (mayAllergen) return { ok: false, why: 'allergy' };
  const mayAnimal = food.mayContain?.filter((k) => excluded.includes(k)) ?? [];
  if (mayAnimal.length) {
    if (!food.plainAvailable) return { ok: false, why: 'diet' };
    return { ok: true, caveat: `Ask for plain ${food.name.toLowerCase()}. Some vendors add ${mayAnimal.map(animalWord).join(' or ')}.` };
  }
  return { ok: true };
}

function animalWord(k: AnimalKind): string {
  return { meat: 'meat', fish: 'fish or crayfish', egg: 'egg', dairy: 'milk' }[k];
}

export function isPlant(food: Food): boolean {
  return !food.animal;
}

export function dietLabel(diet: Diet): string {
  return DIETS.find((d) => d.id === diet)?.label ?? 'No restrictions';
}

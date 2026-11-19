export type Range = { min: number; max: number; mid: number };

export type FoodGroup = 'plant' | 'staple' | 'soup' | 'animal' | 'drink';
export type AnimalKind = 'meat' | 'fish' | 'egg' | 'dairy';
export type Allergen =
  | 'peanut'
  | 'soy'
  | 'egg'
  | 'milk'
  | 'fish'
  | 'shellfish'
  | 'gluten'
  | 'sesame';

export type PortionId =
  | 'sm_pack'
  | 'md_pack'
  | 'lg_pack'
  | 'plate'
  | 'bowl'
  | 'spoon'
  | 'wrap'
  | 'piece'
  | 'ball'
  | 'slice'
  | 'tin'
  | 'sachet'
  | 'handful'
  | 'cup'
  | 'bottle'
  | 'pack'
  | 'serving';

export type IconName = string;

export interface FoodPortion {
  id: PortionId;
  /** Typical grams of the food as eaten (or as stated in `basis`). */
  grams: number;
  /** Typical price range in naira for ONE of this portion. A clue, never a measure. */
  price?: [number, number];
  /** Override the generic portion label for this food, e.g. "1 wrap (leaf)". */
  label?: string;
}

export interface Food {
  id: string;
  name: string;
  /** Local / alternative names shown under the main name. */
  local?: string;
  /** Words the interpreter may match (lowercase, English + Pidgin + common spellings). */
  aliases: string[];
  group: FoodGroup;
  /** True for the alternative-protein foods Pronexa highlights. */
  altProtein?: boolean;
  /** Set when the food itself is an animal product. */
  animal?: AnimalKind;
  /** Animal ingredients a vendor may add (e.g. crayfish in soup, egg in moi-moi). */
  mayContain?: AnimalKind[];
  /** A plain/plant version is easy to ask for (so vegans can still be shown it, with a caveat). */
  plainAvailable?: boolean;
  allergens: Allergen[];
  mayContainAllergens?: Allergen[];
  /** Grams of protein per 100 g of the basis described in `basis`. */
  proteinPer100g: number;
  /** What the grams refer to when not "as eaten" (e.g. "dry weight"). */
  basis?: string;
  portions: FoodPortion[];
  defaultPortion: PortionId;
  defaultQty?: number;
  icon: IconName;
  /** One-line plain-language reason used by the Gap Solver. */
  pitch?: string;
  /** Source note for the nutrition value. */
  source: string;
}

export interface MealItem {
  foodId: string;
  portionId: PortionId;
  qty: number;
  /** Fraction actually eaten: 1, 0.75, 0.5, 0.25 */
  eaten: number;
}

export type LogSource = 'quick' | 'portion' | 'describe';

export interface Meal {
  id: string;
  date: string; // YYYY-MM-DD (local)
  time: number; // epoch ms
  items: MealItem[];
  source: LogSource;
  text?: string;
  price?: number;
  synced: boolean;
  updatedAt: number;
}

export type Diet =
  | 'none'
  | 'vegetarian'
  | 'vegan'
  | 'pescatarian'
  | 'dairy_free'
  | 'egg_free';

export type Activity = 'light' | 'moderate' | 'active' | 'athlete';

export interface Profile {
  diet: Diet;
  allergies: Allergen[];
  weightKg: number | null;
  activity: Activity;
  createdAt: number;
}

export interface Settings {
  lowData: boolean;
  syncEnabled: boolean;
  plantFirst: boolean;
  budget: number;
  simulateAiDown: boolean;
  lastCelebrated?: string;
}

import type { MealItem, PortionId } from '../data/types';

/**
 * What ANY interpreter (the offline mock, or a real LLM behind an endpoint) must return.
 * Interpreters only PICK from the food list. They never return protein numbers.
 */
export interface RawItem {
  foodId: string;
  portionId?: string;
  qty?: number;
  eaten?: number;
  /** Where the portion came from: said by the student, guessed from price, or a default. */
  portionSource?: 'stated' | 'size-default' | 'price' | 'default';
  /** The words that matched, for transparency. */
  matched?: string;
  /** A broad word was used ("rice", "meat") and a more specific food may be meant. */
  generic?: boolean;
}

export interface RawInterpretation {
  items: RawItem[];
  /** Food-like words that were not recognised. */
  unknown: string[];
  /** Things mentioned that carry no protein (water, tea...). */
  skipped: string[];
  /** Total naira mentioned, if any. A clue only. */
  price?: number | null;
}

export interface MealInterpreter {
  name: string;
  interpret(text: string, signal?: AbortSignal): Promise<RawInterpretation>;
}

export type Confidence = 'high' | 'medium' | 'low';

export interface DraftItem extends MealItem {
  key: string;
  portionSource?: RawItem['portionSource'];
  matched?: string;
  generic?: boolean;
}

export type QuestionAction =
  | { type: 'portion'; key: string; portionId: PortionId }
  | { type: 'food'; key: string; foodId: string }
  | { type: 'add'; foodId: string }
  | { type: 'dismiss' };

export interface QuestionOption {
  label: string;
  action: QuestionAction;
  selected?: boolean;
}

export interface Question {
  id: string;
  text: string;
  options: QuestionOption[];
}

export interface Interpretation {
  items: DraftItem[];
  confidence: Confidence;
  question?: Question;
  notes: string[];
  unknown: string[];
  price?: number | null;
  rejected: string[];
  interpreter: string;
}

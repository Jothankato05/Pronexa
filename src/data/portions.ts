import type { PortionId } from './types';

export interface PortionMeta {
  id: PortionId;
  one: string;
  many: string;
  icon: string;
  /** Relative uncertainty of the grams for this kind of portion. */
  uncertainty: number;
  /** Shown as a picture in Portion mode. */
  container?: boolean;
  hint?: string;
}

/**
 * Generic portion kinds. Grams live on each food, because a medium pack of
 * rice does not weigh the same as a medium pack of beans.
 */
export const PORTIONS: Record<PortionId, PortionMeta> = {
  sm_pack: { id: 'sm_pack', one: 'small takeaway', many: 'small takeaways', icon: 'pack-sm', uncertainty: 0.25, container: true, hint: 'Small plastic pack' },
  md_pack: { id: 'md_pack', one: 'medium takeaway', many: 'medium takeaways', icon: 'pack-md', uncertainty: 0.25, container: true, hint: 'The usual pack' },
  lg_pack: { id: 'lg_pack', one: 'large takeaway', many: 'large takeaways', icon: 'pack-lg', uncertainty: 0.25, container: true, hint: 'Big / jumbo pack' },
  plate: { id: 'plate', one: 'plate', many: 'plates', icon: 'plate', uncertainty: 0.25, container: true, hint: 'A regular dinner plate' },
  bowl: { id: 'bowl', one: 'bowl', many: 'bowls', icon: 'bowl', uncertainty: 0.25, container: true, hint: 'Soup or porridge bowl' },
  wrap: { id: 'wrap', one: 'wrap', many: 'wraps', icon: 'wrap', uncertainty: 0.2, container: true, hint: 'Swallow, moi-moi or okpa wrap' },
  spoon: { id: 'spoon', one: 'serving spoon', many: 'serving spoons', icon: 'spoon', uncertainty: 0.25, hint: 'Big cooking spoon' },
  serving: { id: 'serving', one: 'serving', many: 'servings', icon: 'bowl', uncertainty: 0.25, hint: 'What comes with your swallow' },
  piece: { id: 'piece', one: 'piece', many: 'pieces', icon: 'piece', uncertainty: 0.15 },
  ball: { id: 'ball', one: 'ball', many: 'balls', icon: 'akara', uncertainty: 0.15 },
  slice: { id: 'slice', one: 'slice', many: 'slices', icon: 'bread', uncertainty: 0.15 },
  tin: { id: 'tin', one: 'tin', many: 'tins', icon: 'tin', uncertainty: 0.1 },
  sachet: { id: 'sachet', one: 'sachet', many: 'sachets', icon: 'sachet', uncertainty: 0.15 },
  handful: { id: 'handful', one: 'handful', many: 'handfuls', icon: 'handful', uncertainty: 0.25 },
  cup: { id: 'cup', one: 'cup', many: 'cups', icon: 'cup', uncertainty: 0.2 },
  bottle: { id: 'bottle', one: 'bottle', many: 'bottles', icon: 'bottle', uncertainty: 0.2 },
  pack: { id: 'pack', one: 'pack', many: 'packs', icon: 'noodles', uncertainty: 0.1 },
};

/** The containers offered as pictures in Portion mode, in display order. */
export const CONTAINERS: PortionId[] = ['sm_pack', 'md_pack', 'lg_pack', 'plate', 'bowl', 'wrap'];

export const EATEN_OPTIONS = [
  { value: 1, label: 'All of it' },
  { value: 0.75, label: 'Most (¾)' },
  { value: 0.5, label: 'Half' },
  { value: 0.25, label: 'A quarter' },
] as const;

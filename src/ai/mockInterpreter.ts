import { FOOD_BY_ID, FOODS, NO_PROTEIN_WORDS } from '../data/foods';
import type { Food, PortionId } from '../data/types';
import type { MealInterpreter, RawInterpretation, RawItem } from './types';

/**
 * Offline, rule-based stand-in for the AI "Describe it" feature.
 * It understands everyday English and Pidgin meal descriptions well enough for a demo,
 * and follows the same contract as a real LLM: it may only pick foods from the database.
 */

// ── Text normalisation ───────────────────────────────────────

export function normalise(text: string): string {
  let s = ` ${text.toLowerCase()} `;
  s = s.replace(/[‘’']/g, '');
  s = s.replace(/(\d),(\d{3})/g, '$1$2').replace(/(\d),(\d{3})/g, '$1$2');
  s = s.replace(/(\d+(?:\.\d+)?)\s?k\b/g, (_, n) => String(Math.round(parseFloat(n) * 1000)));
  s = s.replace(/\bn(?=\d)/g, '₦').replace(/\bngn\s?(?=\d)/g, '₦');
  s = s.replace(/₦\s+/g, '₦');
  s = s.replace(/&|\+/g, ' and ');
  s = s.replace(/(\d)\s*x\b/g, '$1 ');
  s = s.replace(/(\d)([a-z])/g, '$1 $2');
  s = s.replace(/[^\p{L}\p{N}₦.\s]/gu, ' ');
  s = s.replace(/\.(?!\d)/g, ' ').replace(/(?<!\d)\./g, ' ');
  return s.replace(/\s+/g, ' ').trim();
}

const tokensOf = (s: string) => normalise(s).split(' ').filter(Boolean);

// ── Vocabulary ───────────────────────────────────────────────

const NUMBER_WORDS: Record<string, number> = {
  a: 1, an: 1, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10,
  couple: 2, half: 0.5, quarter: 0.25,
};

const SIZE_WORDS: Record<string, 'sm' | 'md' | 'lg'> = {
  small: 'sm', smallie: 'sm', mini: 'sm', little: 'sm', tiny: 'sm',
  medium: 'md', mid: 'md', normal: 'md', regular: 'md', average: 'md', moderate: 'md',
  big: 'lg', large: 'lg', jumbo: 'lg', huge: 'lg', plenty: 'lg', full: 'lg', extra: 'lg',
};

type ContainerWord = 'pack' | PortionId | 'loaf';
const CONTAINER_WORDS: Record<string, ContainerWord> = {
  pack: 'pack', packs: 'pack', takeaway: 'pack', takeaways: 'pack', takeout: 'pack', container: 'pack', plastic: 'pack', styrofoam: 'pack', box: 'pack',
  plate: 'plate', plates: 'plate',
  bowl: 'bowl', bowls: 'bowl',
  spoon: 'spoon', spoons: 'spoon', spoonful: 'spoon', spoonfuls: 'spoon', scoop: 'spoon', scoops: 'spoon',
  wrap: 'wrap', wraps: 'wrap', wrapper: 'wrap',
  ball: 'ball', balls: 'ball',
  piece: 'piece', pieces: 'piece', pcs: 'piece', pc: 'piece',
  slice: 'slice', slices: 'slice',
  tin: 'tin', tins: 'tin', can: 'tin', cans: 'tin',
  sachet: 'sachet', sachets: 'sachet',
  handful: 'handful', handfuls: 'handful',
  cup: 'cup', cups: 'cup', mudu: 'cup',
  bottle: 'bottle', bottles: 'bottle',
  loaf: 'loaf', loaves: 'loaf',
  serving: 'serving', servings: 'serving', portion: 'serving', portions: 'serving',
};

const CONNECTORS = new Set(['and', 'with', 'plus', 'then', 'n', 'also', 'add', 'added']);

const STOPWORDS = new Set(
  `i me my we you u im ive id a an the of for from at in on to it its is was were be been am are na dey de don go come wey e o oh ah abeg sha oya jare like about around roughly approx just only really very too so that this these those today yesterday morning afternoon evening night tonight breakfast lunch dinner supper snack brunch ate eat eating eaten had have has having chop chopped chopping chopam buy bought buying got get took take away order ordered cost costs paid pay worth price naira ngn mama put mamaput buka canteen cafeteria caf joint spot vendor hostel school campus side inside top each per total all everything whole finish finished left fried boiled roasted grilled hot cold sweet nice local fresh homemade self made cooked rest nothing else not no did didnt dont couldnt could eh some small-small something thing things kind type sort which what how much many ehn sef sha said`.split(' '),
);

const SOUP_IDS = new Set(FOODS.filter((f) => f.group === 'soup').map((f) => f.id));
const PACK_IDS: PortionId[] = ['sm_pack', 'md_pack', 'lg_pack'];

interface AliasEntry { foodId: string; tokens: string[]; alias: string }
const ALIASES: AliasEntry[] = FOODS.flatMap((f) => f.aliases.map((a) => ({ foodId: f.id, tokens: tokensOf(a), alias: a })))
  .sort((a, b) => b.tokens.length - a.tokens.length || b.alias.length - a.alias.length);

const NO_PROTEIN = NO_PROTEIN_WORDS.map((w) => tokensOf(w)).sort((a, b) => b.length - a.length);

/** Broad words that probably need a follow-up. */
const GENERIC: Record<string, true> = { rice: true, meat: true, garri: true, gari: true, sauce: true };

// ── Fuzzy matching (typos like "jolof", "moimio", "groudnut") ─

export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  const dp = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = dp[0];
    dp[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const tmp = dp[j];
      dp[j] = Math.min(dp[j] + 1, dp[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
      prev = tmp;
    }
  }
  return dp[b.length];
}

function tokenEq(word: string, target: string): boolean {
  if (word === target) return true;
  if (word === target + 's' || word + 's' === target || word === target + 'es') return true;
  if (target.length >= 5 && word.length >= 4 && Math.abs(word.length - target.length) <= 1) {
    return levenshtein(word, target) <= 1;
  }
  return false;
}

/** Closest foods to an unknown word, for the "did you mean" question. */
export function closestFoods(word: string, limit = 3): Food[] {
  const scored = new Map<string, number>();
  for (const a of ALIASES) {
    const d = levenshtein(word, a.alias) / Math.max(word.length, a.alias.length);
    const prev = scored.get(a.foodId);
    if (prev === undefined || d < prev) scored.set(a.foodId, d);
  }
  return [...scored.entries()].filter(([, d]) => d <= 0.3).sort((a, b) => a[1] - b[1]).slice(0, limit).map(([id]) => FOOD_BY_ID[id]);
}

// ── Parsing ──────────────────────────────────────────────────

interface Span { start: number; end: number; foodId: string; matched: string }
type Mod =
  | { kind: 'num'; value: number; pos: number }
  | { kind: 'size'; value: 'sm' | 'md' | 'lg'; pos: number }
  | { kind: 'container'; value: ContainerWord; pos: number }
  | { kind: 'of'; pos: number }
  | { kind: 'connector'; pos: number };

function detectMealEaten(s: string): { text: string; eaten?: number } {
  const rules: [RegExp, number][] = [
    [/\b(?:i\s+)?(?:only\s+)?(?:ate|chop|chopped|finished|finish|eat)\s+(?:only\s+)?half(?!\s+(?:a\s+|of\s+(?:a\s+|the\s+)?)?(?:plate|pack|bowl|wrap|spoon|takeaway|loaf|tin|sachet|cup|bottle|portion|serving))(?:\s+of\s+it)?\b/, 0.5],
    [/\bhalf\s+of\s+it\b/, 0.5],
    [/\b(?:i\s+)?(?:ate|chop|chopped|finished|eat)\s+(?:a\s+)?quarter(?:\s+of\s+it)?\b/, 0.25],
    [/\b(?:i\s+)?(?:no\s+finish|didnt\s+finish|did\s+not\s+finish|couldnt\s+finish|could\s+not\s+finish|cant\s+finish|left\s+some|no\s+fit\s+finish)(?:\s+(?:am|it))?\b/, 0.75],
    [/\b(?:i\s+)?(?:finish|finished|cleared|chop\s+finish)\s+(?:everything|all|am|it)\b/, 1],
  ];
  for (const [re, v] of rules) {
    if (re.test(s)) return { text: s.replace(re, ' ').replace(/\s+/g, ' ').trim(), eaten: v };
  }
  return { text: s };
}

export function parseMeal(input: string): RawInterpretation {
  const { text, eaten: mealEaten } = detectMealEaten(normalise(input));
  const toks = text.split(' ').filter(Boolean);
  const used = new Array(toks.length).fill(false);

  // 1. Food spans (longest alias first).
  const spans: Span[] = [];
  // Longest aliases first; within each length, exact matches before typo-tolerant ones,
  // so "jolof rice" beats "rice" and "awara" never becomes "akara".
  const lengths = [...new Set(ALIASES.map((a) => a.tokens.length))].sort((a, b) => b - a);
  for (const len of lengths) for (const fuzzy of [false, true]) for (const a of ALIASES) {
    if (a.tokens.length !== len) continue;
    for (let i = 0; i + a.tokens.length <= toks.length; i++) {
      if (used.slice(i, i + a.tokens.length).some(Boolean)) continue;
      const ok = a.tokens.every((t, k) => (fuzzy ? tokenEq(toks[i + k], t) : toks[i + k] === t || toks[i + k] === t + 's'));
      if (!ok) continue;
      spans.push({ start: i, end: i + a.tokens.length, foodId: a.foodId, matched: toks.slice(i, i + a.tokens.length).join(' ') });
      for (let k = i; k < i + a.tokens.length; k++) used[k] = true;
    }
  }
  spans.sort((a, b) => a.start - b.start);

  // 2. Things with no protein.
  const skipped: string[] = [];
  for (const w of NO_PROTEIN) {
    for (let i = 0; i + w.length <= toks.length; i++) {
      if (used.slice(i, i + w.length).some(Boolean)) continue;
      if (w.every((t, k) => toks[i + k] === t)) {
        skipped.push(w.join(' '));
        for (let k = i; k < i + w.length; k++) used[k] = true;
      }
    }
  }

  // 3. Modifiers and price.
  const mods: Mod[] = [];
  let price = 0;
  const unknownRuns: string[][] = [];
  let run: string[] = [];
  const flush = () => { if (run.length) unknownRuns.push(run); run = []; };
  for (let i = 0; i < toks.length; i++) {
    if (used[i]) { flush(); continue; }
    const t = toks[i];
    const next = toks[i + 1];
    if (t.startsWith('₦')) {
      const n = parseFloat(t.slice(1));
      if (!isNaN(n)) price += n;
      used[i] = true; flush(); continue;
    }
    if (/^\d+(\.\d+)?$/.test(t)) {
      const n = parseFloat(t);
      used[i] = true; flush();
      if (next === 'naira' || next === 'ngn' || n >= 50) { price += n; continue; }
      if (next === 'g' || next === 'grams' || next === 'ml') { i++; continue; }
      mods.push({ kind: 'num', value: n, pos: i });
      continue;
    }
    if (t in NUMBER_WORDS && !(t === 'a' || t === 'an') ) { mods.push({ kind: 'num', value: NUMBER_WORDS[t], pos: i }); used[i] = true; flush(); continue; }
    if ((t === 'a' || t === 'an') && next && (next in CONTAINER_WORDS || next in SIZE_WORDS)) { mods.push({ kind: 'num', value: 1, pos: i }); used[i] = true; flush(); continue; }
    if (t in SIZE_WORDS) { mods.push({ kind: 'size', value: SIZE_WORDS[t], pos: i }); used[i] = true; flush(); continue; }
    if (t === 'take' && next === 'away') { mods.push({ kind: 'container', value: 'pack', pos: i }); used[i] = used[i + 1] = true; i++; flush(); continue; }
    if (t in CONTAINER_WORDS) { mods.push({ kind: 'container', value: CONTAINER_WORDS[t], pos: i }); used[i] = true; flush(); continue; }
    if (t === 'of') { mods.push({ kind: 'of', pos: i }); used[i] = true; flush(); continue; }
    if (CONNECTORS.has(t)) { mods.push({ kind: 'connector', pos: i }); used[i] = true; flush(); continue; }
    if (STOPWORDS.has(t) || t.length < 3) { used[i] = true; flush(); continue; }
    run.push(t);
  }
  flush();
  const unknown = unknownRuns.map((r) => r.join(' '));

  if (!spans.length) return { items: [], unknown, skipped, price: price || null };

  // 4. Assign each modifier to a food span.
  const owned: Mod[][] = spans.map(() => []);
  for (const m of mods) {
    if (m.kind === 'connector' || m.kind === 'of') continue;
    owned[ownerOf(m.pos, spans, mods)].push(m);
  }

  // 5. Containers that do not fit their food move to the first food that supports them.
  for (let s = 0; s < spans.length; s++) {
    const food = FOOD_BY_ID[spans[s].foodId];
    for (const m of [...owned[s]]) {
      if (m.kind !== 'container' || supports(food, m.value)) continue;
      const target = spans.findIndex((sp) => supports(FOOD_BY_ID[sp.foodId], m.value));
      if (target >= 0 && target !== s) {
        owned[s] = owned[s].filter((x) => x !== m);
        // Bring along a size word that sat next to the container.
        const size = owned[s].find((x) => x.kind === 'size' && Math.abs(x.pos - m.pos) <= 2);
        if (size) { owned[s] = owned[s].filter((x) => x !== size); owned[target].push(size); }
        owned[target].push(m);
      }
    }
  }

  // 6. Resolve each food into an item.
  const hasSoup = spans.some((s) => SOUP_IDS.has(s.foodId));
  const items: RawItem[] = spans.map((sp, idx) => {
    let foodId = sp.foodId;
    // "garri" with soup is eba, not soaked garri.
    if (foodId === 'garri_soaked' && hasSoup && /^(garri|gari)$/.test(sp.matched)) foodId = 'eba';
    const food = FOOD_BY_ID[foodId];
    const r = resolvePortion(food, owned[idx]);
    return {
      foodId,
      portionId: r.portionId,
      qty: r.qty,
      eaten: mealEaten ?? 1,
      portionSource: r.source,
      matched: sp.matched,
      generic: !!GENERIC[sp.matched] && foodId !== 'eba',
    };
  });

  // Merge duplicates ("egg ... egg") into one line.
  const merged: RawItem[] = [];
  for (const it of items) {
    const ex = merged.find((m) => m.foodId === it.foodId && m.portionId === it.portionId);
    if (ex) ex.qty = (ex.qty ?? 1) + (it.qty ?? 1);
    else merged.push(it);
  }

  return { items: merged, unknown, skipped, price: price || null };
}

function ownerOf(pos: number, spans: Span[], mods: Mod[]): number {
  const after = spans.findIndex((s) => s.start > pos);
  if (after === -1) return spans.length - 1; // trailing words belong to the last food
  if (after === 0) return 0; // leading words belong to the first food
  const prev = after - 1;
  const between = mods.filter((m) => m.pos > spans[prev].end - 1 && m.pos < spans[after].start);
  const lastConnector = [...between].reverse().find((m) => m.kind === 'connector');
  if (lastConnector) return pos > lastConnector.pos ? after : prev;
  const hasOf = between.some((m) => m.kind === 'of');
  if (hasOf) return after;
  // No connector: a number or size directly before the next food belongs to it.
  const lastMod = between[between.length - 1];
  if (lastMod && lastMod.pos === spans[after].start - 1 && (lastMod.kind === 'num' || lastMod.kind === 'size')) {
    return pos >= lastMod.pos ? after : prev;
  }
  return prev;
}

function supports(food: Food, c: ContainerWord): boolean {
  if (c === 'pack') return food.portions.some((p) => PACK_IDS.includes(p.id) || p.id === 'pack');
  if (c === 'loaf') return food.portions.some((p) => p.id === 'slice');
  if (c === 'piece' || c === 'serving') return true; // "piece"/"serving" fit almost anything
  return food.portions.some((p) => p.id === c);
}

function nearestPack(food: Food, size: 'sm' | 'md' | 'lg'): PortionId | undefined {
  const order: PortionId[] = size === 'sm' ? ['sm_pack', 'md_pack', 'lg_pack'] : size === 'lg' ? ['lg_pack', 'md_pack', 'sm_pack'] : ['md_pack', 'sm_pack', 'lg_pack'];
  return order.find((id) => food.portions.some((p) => p.id === id));
}

function resolvePortion(food: Food, mods: Mod[]): { portionId: PortionId; qty: number; source: RawItem['portionSource'] } {
  const nums = mods.filter((m): m is Extract<Mod, { kind: 'num' }> => m.kind === 'num');
  const size = mods.find((m): m is Extract<Mod, { kind: 'size' }> => m.kind === 'size')?.value;
  const container = mods.find((m): m is Extract<Mod, { kind: 'container' }> => m.kind === 'container')?.value;
  const half = nums.find((n) => n.value < 1);
  const whole = nums.find((n) => n.value >= 1);
  const qtyFrom = (fallback: number) => (whole?.value ?? 1) * (half ? half.value : 1) * (whole || half ? 1 : fallback);
  const has = (id: PortionId) => food.portions.some((p) => p.id === id);

  if (container === 'pack') {
    if (food.portions.some((p) => p.id === 'pack')) return { portionId: 'pack', qty: qtyFrom(1), source: 'stated' };
    const id = nearestPack(food, size ?? 'md');
    if (id) return { portionId: id, qty: qtyFrom(1), source: size ? 'stated' : 'size-default' };
  }
  if (container === 'loaf' && has('slice')) {
    return { portionId: 'slice', qty: Math.round(10 * (half ? half.value : 1) * (whole?.value ?? 1)), source: 'stated' };
  }
  if (container && container !== 'pack' && container !== 'loaf') {
    if (has(container)) {
      const sizeFactor = container === 'plate' || container === 'bowl' ? (size === 'sm' ? 0.75 : size === 'lg' ? 1.3 : 1) : 1;
      return { portionId: container, qty: +(qtyFrom(1) * sizeFactor).toFixed(2), source: 'stated' };
    }
    if (container === 'piece' || container === 'serving') {
      return { portionId: food.defaultPortion, qty: qtyFrom(food.defaultQty ?? 1), source: whole ? 'stated' : 'default' };
    }
  }
  // Size word without a container, e.g. "big jollof".
  if (size) {
    const id = nearestPack(food, size);
    if (id) return { portionId: id, qty: qtyFrom(1), source: 'stated' };
  }
  // Only a number: "2 akara", "3 eggs", "2 meat".
  if (whole || half) {
    return { portionId: food.defaultPortion, qty: qtyFrom(1), source: 'stated' };
  }
  return { portionId: food.defaultPortion, qty: food.defaultQty ?? 1, source: 'default' };
}

export const mockInterpreter: MealInterpreter = {
  name: 'offline-demo',
  async interpret(text, signal) {
    // Simulate a short network round-trip so the skeleton/loading state is real.
    await new Promise<void>((resolve, reject) => {
      const t = setTimeout(resolve, 650 + Math.random() * 350);
      signal?.addEventListener('abort', () => { clearTimeout(t); reject(new DOMException('Aborted', 'AbortError')); });
    });
    return parseMeal(text);
  },
};

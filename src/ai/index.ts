import { DB_VERSION } from '../data/foods';
import { createLlmInterpreter } from './llmInterpreter';
import { mockInterpreter, normalise } from './mockInterpreter';
import type { Interpretation, MealInterpreter, RawInterpretation } from './types';
import { validate } from './validate';

export type InterpretResult =
  | { ok: true; result: Interpretation; cached: boolean }
  | { ok: false; reason: 'offline' | 'unavailable' | 'empty' | 'nothing-found'; unknown?: string[] };

const endpoint = import.meta.env.VITE_AI_ENDPOINT as string | undefined;
export const interpreter: MealInterpreter = endpoint ? createLlmInterpreter(endpoint) : mockInterpreter;

/** Repeat descriptions ("my usual rice and beans") never cost a second AI call. */
const memo = new Map<string, RawInterpretation>();
export type RawCache = { get(k: string): Promise<RawInterpretation | undefined>; set(k: string, v: RawInterpretation): Promise<void> };
let persistent: RawCache | null = null;
export function setInterpretCache(c: RawCache) { persistent = c; }

export async function interpretMeal(
  text: string,
  opts: { online: boolean; simulateDown?: boolean; signal?: AbortSignal; timeoutMs?: number },
): Promise<InterpretResult> {
  const clean = text.trim();
  if (!clean) return { ok: false, reason: 'empty' };
  const key = `${DB_VERSION}:${normalise(clean)}`;

  let raw = memo.get(key) ?? (await persistent?.get(key).catch(() => undefined));
  const cached = !!raw;
  if (!raw) {
    if (!opts.online) return { ok: false, reason: 'offline' };
    if (opts.simulateDown) return { ok: false, reason: 'unavailable' };
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), opts.timeoutMs ?? 8000);
    opts.signal?.addEventListener('abort', () => ctrl.abort());
    try {
      raw = await interpreter.interpret(clean, ctrl.signal);
    } catch {
      return { ok: false, reason: opts.signal?.aborted ? 'empty' : 'unavailable' };
    } finally {
      clearTimeout(timer);
    }
    memo.set(key, raw);
    void persistent?.set(key, raw).catch(() => {});
  }
  const result = validate(raw, interpreter.name);
  if (!result.items.length) return { ok: false, reason: 'nothing-found', unknown: result.unknown };
  return { ok: true, result, cached };
}

export type { Interpretation } from './types';

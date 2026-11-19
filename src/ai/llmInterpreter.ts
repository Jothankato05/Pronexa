import { DB_VERSION, FOODS } from '../data/foods';
import type { MealInterpreter, RawInterpretation } from './types';

/**
 * Drop-in adapter for a real language model.
 *
 * The phone never holds an API key. It POSTs the student's words to a small server
 * endpoint (VITE_AI_ENDPOINT) that calls the LLM with SYSTEM_PROMPT + RESPONSE_SCHEMA
 * (as a tool / structured output) and returns the JSON unchanged. Whatever comes back is
 * still passed through `validate()`, so the model can only ever pick foods from the list.
 */

export function foodListForPrompt(): string {
  return FOODS.map((f) => `${f.id} | ${f.name} | ${f.aliases.slice(0, 6).join(', ')} | portions: ${f.portions.map((p) => p.id).join(', ')} (default ${f.defaultPortion})`).join('\n');
}

export const SYSTEM_PROMPT = `You read Nigerian students' meal descriptions (English or Nigerian Pidgin) and map them to a fixed food list.
Rules:
- Only use foodId values from the FOOD LIST. Never invent foods. Put anything you cannot map in "unknown".
- Never estimate grams or protein. Choose a portionId from that food's portions, a qty, and the fraction eaten (1, 0.75, 0.5, 0.25).
- portionSource: "stated" if the student said the size/count, "size-default" if they said a container but not its size, "default" if they said nothing.
- Naira amounts go in "price" as the meal total. Price is a clue only: do not change sizes based on price.
- Drinks or items with no protein (water, tea, zobo, soft drinks) go in "skipped".
- Set generic=true when a broad word was used (e.g. "rice" without white/jollof/fried, "meat").
FOOD LIST (id | name | aliases | portions):
${foodListForPrompt()}`;

export const RESPONSE_SCHEMA = {
  type: 'object',
  required: ['items', 'unknown', 'skipped'],
  properties: {
    items: {
      type: 'array',
      items: {
        type: 'object',
        required: ['foodId'],
        properties: {
          foodId: { type: 'string', enum: FOODS.map((f) => f.id) },
          portionId: { type: 'string' },
          qty: { type: 'number' },
          eaten: { type: 'number', enum: [1, 0.75, 0.5, 0.25] },
          portionSource: { type: 'string', enum: ['stated', 'size-default', 'default'] },
          matched: { type: 'string' },
          generic: { type: 'boolean' },
        },
      },
    },
    unknown: { type: 'array', items: { type: 'string' } },
    skipped: { type: 'array', items: { type: 'string' } },
    price: { type: ['number', 'null'] },
  },
} as const;

export function createLlmInterpreter(endpoint: string): MealInterpreter {
  return {
    name: 'llm',
    async interpret(text, signal) {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, dbVersion: DB_VERSION }),
        signal,
      });
      if (!res.ok) throw new Error(`AI endpoint ${res.status}`);
      return (await res.json()) as RawInterpretation;
    },
  };
}

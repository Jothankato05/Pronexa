import assert from "node:assert/strict";
import { test } from "node:test";
import { cleanReading, FOODS, ReadingSchema, SYSTEM_PROMPT } from "./schema.js";

test("the prompt lists every food id from the app database", () => {
  for (const f of FOODS) assert.ok(SYSTEM_PROMPT.includes(`${f.id} | `), f.id);
});

test("the schema rejects foods that are not in the database", () => {
  const r = ReadingSchema.safeParse({
    items: [{ foodId: "sushi", portionId: "plate", qty: 1, eaten: 1, portionSource: "stated", matched: "sushi", generic: false }],
    unknown: [],
    skipped: [],
    price: null,
  });
  assert.equal(r.success, false);
});

test("portions that don't belong to the food fall back to its default", () => {
  const out = cleanReading({
    items: [{ foodId: "egg", portionId: "lg_pack", qty: 999, eaten: 0.6, portionSource: "stated", matched: "egg", generic: false }],
    unknown: [],
    skipped: [],
    price: -5,
  });
  assert.equal(out.items[0]?.portionId, "piece");
  assert.equal(out.items[0]?.portionSource, "default");
  assert.equal(out.items[0]?.qty, 20);
  assert.equal(out.items[0]?.eaten, 1);
  assert.equal(out.price, null);
});

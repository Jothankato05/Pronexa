import { z } from "zod";
import foodsJson from "./foods.json" with { type: "json" };

/** The food list exported from the app's database (tool/export_foods.dart). */
export const FOODS = foodsJson.foods;
export const DB_VERSION = foodsJson.dbVersion;

const foodIds = FOODS.map((f) => f.id) as [string, ...string[]];
const portionIds = [...new Set(FOODS.flatMap((f) => f.portions))] as [string, ...string[]];

/**
 * What the model must return. The model only picks food and portion ids from
 * the list; it never estimates grams or protein. The app validates this again.
 */
export const ReadingSchema = z.object({
  items: z
    .array(
      z.object({
        foodId: z.enum(foodIds),
        portionId: z.enum(portionIds),
        qty: z.number(),
        eaten: z.number(),
        portionSource: z.enum(["stated", "size-default", "default"]),
        matched: z.string(),
        generic: z.boolean(),
      }),
    )
    .max(12),
  unknown: z.array(z.string()).max(10),
  skipped: z.array(z.string()).max(10),
  price: z.number().nullable(),
});

export type Reading = z.infer<typeof ReadingSchema>;

/** Extra checks the schema can't express: portions must belong to their food. */
export function cleanReading(r: Reading): Reading {
  const byId = new Map(FOODS.map((f) => [f.id, f]));
  return {
    items: r.items
      .filter((i) => byId.has(i.foodId))
      .map((i) => {
        const food = byId.get(i.foodId)!;
        const portionOk = food.portions.includes(i.portionId);
        return {
          ...i,
          portionId: portionOk ? i.portionId : food.defaultPortion,
          portionSource: portionOk ? i.portionSource : ("default" as const),
          qty: Number.isFinite(i.qty) ? Math.min(20, Math.max(0.25, i.qty)) : 1,
          eaten: [1, 0.75, 0.5, 0.25].includes(i.eaten) ? i.eaten : 1,
          matched: i.matched.slice(0, 60),
        };
      }),
    unknown: r.unknown.map((s) => s.slice(0, 60)),
    skipped: r.skipped.map((s) => s.slice(0, 60)),
    price: r.price !== null && r.price > 0 && r.price < 1_000_000 ? Math.round(r.price) : null,
  };
}

export const SYSTEM_PROMPT = `You read what Nigerian university students ate and map it to a fixed food list.
The input is either their own words (English or Nigerian Pidgin) or a photo of the meal.

Rules:
- Use only foodId and portionId values from the FOOD LIST. A food that is not on the list goes in "unknown" as the student's word for it.
- Choose a portionId from that food's own portions. Never estimate grams or protein.
- qty is how many of that portion (for example 2 wraps, 4 akara balls, 0.5 for half a plate).
- eaten is the fraction eaten: 1, 0.75, 0.5 or 0.25. Use 1 unless they said otherwise.
- portionSource: "stated" if the size or count was said or clearly visible, "size-default" if a container was named without its size, "default" if nothing was said or visible.
- Naira amounts go in "price" as the meal total (a number), otherwise null. Do not change sizes because of the price.
- Drinks and items without protein (water, tea, zobo, soft drinks, pap) go in "skipped".
- generic is true when a broad word was used, such as "rice" without white, jollof or fried, or "meat".
- matched is the student's words for that food, or a short visual description for photos.
- For photos: list only foods you can actually see. If the photo is unclear, return fewer items rather than guessing.

FOOD LIST (id | name | words students use | portions):
${FOODS.map((f) => `${f.id} | ${f.name} | ${f.aliases.join(", ")} | ${f.portions.join(", ")}`).join("\n")}`;

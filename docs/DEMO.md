# Pronexa: 3-minute demo

Phone in airplane mode the whole time; that is the point.

## 0:00 The problem (20 s)

"Most students in Nigerian universities eat rice, garri and swallow every day. They fill up, but many don't get enough protein, and they don't know how far off they are or what to buy to fix it with ₦500."

## 0:20 Set up (20 s)

Open Pronexa. **Start** → Vegan → no allergies → 60 kg → On my feet a lot.

"Four taps, no name, no email, no account. Pronexa gives a daily target as a range: about 60 g."

## 0:40 Log a meal the way you buy it (50 s)

1. Tap **Describe**, type: `₦1,000 rice and beans medium takeaway and 2 akara`.
   - "That's read on the phone, offline, in English or Pidgin. It understands packs, wraps, spoons and naira."
2. On **Check your meal**: point at the range, the "Looks clear" pill, and tap a food to show it can be changed.
   - "Nothing is counted until the student confirms. Price is only a clue to the size."
3. **Add to today.** The number counts up; the gap shrinks.

Then **Photo**: snap a plate of eba and egusi (or jollof). Still in airplane mode, Pronexa shows "Looks like: Egusi · Eba". Tap them, add.
- "The food recogniser runs on the phone. No internet, and the photo never leaves the phone."

## 1:30 Close the gap for less (40 s)

Tap the **lightbulb**.

- "What's left today, and the cheapest ways to close it within a budget. Plant protein first: soya chunks, beans, groundnuts, kuli-kuli. A vegan never sees an animal product."
- Switch the budget to ₦300, then ₦1k.
- Tap **I ate this** on a combo.

## 2:10 Learn and plan (30 s)

Learn tab → **Meal planner**: "A whole day of normal campus meals that reaches 60 g for ₦2,500." Tap **Another plan**.
Then **₦500 challenge** and one lesson.

## 2:40 Why it's credible (20 s)

- "78 Nigerian foods with sources (West African Food Composition Table, USDA), every number shown as a range."
- "243 test descriptions, read correctly on the phone without internet."
- "Data stays on the phone. Estimates only, not medical advice."

Close: "Pronexa: check your protein, close the gap for less."

## Likely questions

- **How accurate is it?** Values are starter estimates from WAFCT 2019 and USDA, shown as ranges; a nutritionist review sheet is ready (`docs/food_review.csv`). The offline reader passes 243 descriptions, including 60 written after it was built (58/60 first time).
- **What about photos?** An open Nigerian food model (41 foods) runs on the phone. On 96 independent photos the right food was among its suggestions 95% of the time. It only suggests; the student taps and confirms, and protein comes from the database.
- **Privacy?** No account, nothing uploaded unless the student taps "Read the photo". Cloud backup is off.
- **Next?** A campus pilot to collect real descriptions (`docs/PILOT.md`) and a vendor map.

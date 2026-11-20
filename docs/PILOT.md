# Running a pilot

Goal: learn how students really describe meals, and get the protein values checked, before a wider release.

## 1. Before you start

- **Nutrition review.** Send `docs/food_review.csv` to a nutritionist or dietitian. It lists every food with its protein value, portion sizes, prices and source, and has empty columns for their corrections. Regenerate it after any change to the food list: `dart run tool/export_review_sheet.dart`.
- **Consent.** Tell students what the pilot is for, that the app stores everything on their phone, and that sharing descriptions is optional. Pronexa collects no name, email or phone number.
- **Install.** Give students the APK from the latest GitHub Release (or the small APK in person).

## 2. During the pilot (1–2 weeks, 10–20 students)

Ask students to log every meal for a week, using **Describe** at least once a day in their own words (English, Pidgin, any mix).

## 3. Collecting descriptions

Each student opens **Profile → Share meal descriptions**. This copies only the sentences they typed and the foods they confirmed, never their profile, weight, dates or other meals. They paste it into a message to you (WhatsApp is fine) and you save each one as a `.json` file.

Then add them to the test data:

```bash
dart run tool/add_pilot_cases.dart shared/*.json
flutter test test/reader_eval_test.dart     # prints "Pilot set: N/M read correctly"
```

Cases with unknown foods or duplicate text are skipped. Pilot cases are scored but never fail the build.

## 4. Improving the reader

For each miss printed by the test:

1. Add the missing name to the food's `aliases` in `lib/data/foods.dart` or `lib/data/foods_more.dart`, or a missing word to `lib/ai/rule_reader.dart`.
2. If the food itself is missing, add it with a source, portions and prices, then run `dart run tool/export_foods.dart` so the AI server knows it too.
3. Once it reads correctly, move the case from `describe_pilot.json` to `describe_set.json`, so it is protected from then on.

## 5. What to measure

- Reader accuracy on the pilot set, before and after fixes.
- How often students edit foods or portions on the Confirm screen (ask them).
- Whether the suggestions were things they could actually buy near campus, and at those prices.

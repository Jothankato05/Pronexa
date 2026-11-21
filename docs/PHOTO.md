# Photo mode: the on-phone food recogniser

Photo mode recognises Nigerian foods **on the phone, with no internet**. The student takes a photo, Pronexa shows what it thinks is on the plate ("Looks like: Egusi · Eba · Dried fish"), and those foods appear first on the Pick screen. Nothing is selected for the student: they tap what is really there, then check portions on the Confirm screen. Protein still comes only from the food database.

## The model

- **Nigerian Food Lens** by yusasif, https://huggingface.co/yusasif/Nigerian-food-recognision, Apache-2.0, pinned to commit `36a13b5`.
- EfficientNetV2-S, multi-label: it reports every food it sees on the plate, from 41 foods (swallows, soups, proteins, rice dishes, snacks).
- `tool/food_model/convert.py` checks the download's SHA-256, loads only the weights (no code from the file runs), adds the resizing/normalisation step, and exports `assets/models/pronexa-food-v1.onnx` (81 MB, full precision, same answers as the original to 1e-6). It runs on the phone with ONNX Runtime 1.28 (`android/app/src/main/java/ng/pronexa/app/LensEngine.java`), on a background thread started by `MainActivity` (the `pronexa/lens` channel). The model starts loading when Photo mode opens. If recognition fails or takes more than 60 seconds, Photo mode falls back to picking by hand.

Never run the model on Android's main thread: loading it takes seconds, and Android kills an app that freezes that long (this was the 0.7.0 crash). `tool/food_model/LensEngineCheck.java` runs the same engine class on a desktop JVM against the real model.
- The 41 labels map to Pronexa foods in `lib/ai/food_lens.dart` (`lensLabels`). Labels with no protein (ogi, onion, tomato) or no database food (shrimp) are ignored.
- Suggestions: up to four foods scoring 0.2 or more. The model card suggests 0.3 for automatic use; Pronexa only suggests, so it prefers missing fewer foods.

## How well it works

On 96 independent photos of 12 Nigerian dishes (a different public dataset, `cicerothoma/nigeria_food`, MIT):

| | |
|---|---|
| The right food was among the suggestions | 91 / 96 (95%) |
| The right food was the first suggestion | 67 / 96 (70%) |

Strong: egusi, akara, jollof, ogbono, okra soup, nkwobi. Weaker as first guess: banga, amala, pounded yam, ewedu (mixed up with similar soups and swallows). Some of those internet photos may resemble the model's training data, so expect lower numbers on real campus photos.

**It does not know foods outside its 41**, for example chips, shawarma, suya, puff-puff or meat pie. For those it may suggest something similar-looking (chips can come up as plantain), and the student picks the right food themselves. The phone then learns them (below).

## The dish head: a sharper first guess, and 6 more dishes

A small classifier trained on the recogniser's photo fingerprints (`tool/food_model/train_head.py`, shipped as `assets/models/pronexa-food-head.json`, 172 KB). It names the main dish; the recogniser still adds the other foods on the plate. Trained on all 1,542 labelled photos of 18 dishes in `cicerothoma/nigeria_food` (MIT), including six the recogniser never learned: chin chin, puff-puff, suya, pepper soup, yam porridge and ofada rice. It runs in Dart on the phone, offline (`DishHead` in `lib/ai/food_lens.dart`).

Measured with 5-fold cross-validation: every photo is scored by a head trained without it.

| 1,542 photos, 18 dishes | Recogniser alone | Recogniser + dish head |
|---|---|---|
| Right food is the first suggestion | 660 (42.8%) | **1,278 (82.9%)** |
| Right food among the suggestions | 983 (63.7%) | **1,423 (92.3%)** |
| First suggestion, 12 dishes it already knew | 58.8% | **80.7%** |
| First suggestion, 6 new dishes | 0% | **88.6%** |

Biggest gains: banga 9% → 77%, pounded yam 12% → 68%, efo riro 38% → 90%, puff-puff 0% → 96%, suya 0% → 92%. Akara dropped slightly (91% → 87%).

These photos come from one public set, so the folds share its style. Expect lower numbers on real campus photos; the pilot should collect confirmed photos to measure that. The 96-photo check above is part of this set, so it is not an independent test of the head.

To retrain: `python tool/food_model/train_head.py --data nigeria_food.parquet --model assets/models/pronexa-food-v1.onnx` (needs `numpy pillow pyarrow onnxruntime`). It prints the report above and writes the head.

## Learning new foods on the phone

Pronexa adapts to each student's food without retraining or the internet (`lib/ai/photo_memory.dart`):

1. When a meal logged from a photo is added, the photo's fingerprint is kept with the foods the student confirmed. The fingerprint is the model's 1280 image features, stored as 8-bit numbers (1.3 KB). The photo itself is never kept.
2. For each new photo, Pronexa finds the most similar remembered photo. If it is close enough (cosine similarity at least 0.65), that meal's foods come first, ticked, before the model's own guesses.
3. Up to 200 photos are kept (about 260 KB); the oldest are forgotten first, and near-copies of the same meal are not stored twice. Profile → Photo memory shows how much has been learned and can clear it. Deleting all data clears it too.

This covers foods the model was never trained on (chips, suya, shawarma) and a student's usual plates (their buka's jollof and chicken).

Measured on 164 public photos of 6 dishes the model does not know (chin chin, puff-puff, suya, pepper soup, ofada rice, yam porridge), over 30 to 40 random trials each:

| Photos already confirmed of that dish | Next photo of it gets the right food first |
|---|---|
| 1 | 54% |
| 3 | 69% |
| 5 | 75% |

About 12 to 14% of other photos picked up one wrong learned suggestion. Suggestions are only taps: the student still checks every food, and protein still comes only from the food database.

## Privacy

The photo never leaves the phone for recognition or learning, and learned fingerprints stay on the phone. If the optional AI server is set up (`docs/AI_SERVER.md`), "Read the photo" can still send it there, only when tapped and never in low-data mode.

## Building it

```bash
pip install -r tool/food_model/requirements.txt
python tool/food_model/convert.py --out assets/models
```

The Release workflow does this automatically before building the APKs. A build without the file still works; Photo mode then asks the student to pick the foods.

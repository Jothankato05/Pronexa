# Photo mode: the on-phone food recogniser

Photo mode recognises Nigerian foods **on the phone, with no internet**. The student takes a photo, Pronexa shows what it thinks is on the plate ("Looks like: Egusi · Eba · Dried fish"), and those foods appear first on the Pick screen. Nothing is selected for the student: they tap what is really there, then check portions on the Confirm screen. Protein still comes only from the food database.

## The model

- **Nigerian Food Lens** by yusasif, https://huggingface.co/yusasif/Nigerian-food-recognision, Apache-2.0, pinned to commit `36a13b5`.
- EfficientNetV2-S, multi-label: it reports every food it sees on the plate, from 41 foods (swallows, soups, proteins, rice dishes, snacks).
- `tool/food_model/convert.py` checks the download's SHA-256, loads only the weights (no code from the file runs), adds the resizing/normalisation step, and exports `assets/models/pronexa-food-v1.onnx` (81 MB, full precision, same answers as the original to 1e-6). It runs on the phone with ONNX Runtime (`flutter_onnxruntime`).
- The 41 labels map to Pronexa foods in `lib/ai/food_lens.dart` (`lensLabels`). Labels with no protein (ogi, onion, tomato) or no database food (shrimp) are ignored.
- Suggestions: up to four foods scoring 0.2 or more. The model card suggests 0.3 for automatic use; Pronexa only suggests, so it prefers missing fewer foods.

## How well it works

On 96 independent photos of 12 Nigerian dishes (a different public dataset, `cicerothoma/nigeria_food`, MIT):

| | |
|---|---|
| The right food was among the suggestions | 91 / 96 (95%) |
| The right food was the first suggestion | 67 / 96 (70%) |

Strong: egusi, akara, jollof, ogbono, okra soup, nkwobi. Weaker as first guess: banga, amala, pounded yam, ewedu (mixed up with similar soups and swallows). Some of those internet photos may resemble the model's training data, so expect lower numbers on real campus photos.

**It does not know foods outside its 41**, for example chips, shawarma, suya, puff-puff or meat pie. For those it may suggest something similar-looking (chips can come up as plantain), and the student picks the right food themselves.

## Privacy

The photo never leaves the phone for recognition. If the optional AI server is set up (`docs/AI_SERVER.md`), "Read the photo" can still send it there, only when tapped and never in low-data mode.

## Building it

```bash
pip install -r tool/food_model/requirements.txt
python tool/food_model/convert.py --out assets/models
```

The Release workflow does this automatically before building the APKs. A build without the file still works; Photo mode then asks the student to pick the foods.

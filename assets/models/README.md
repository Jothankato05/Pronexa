The on-phone food recogniser (`pronexa-food-v1.onnx`, about 81 MB) is built
into this folder, not committed:

    pip install -r tool/food_model/requirements.txt
    python tool/food_model/convert.py --out assets/models

The Release workflow does this before building the APKs. Without the file the
app still works; Photo mode then asks the student to pick the foods.

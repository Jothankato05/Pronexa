"""Trains Pronexa's dish head: a small classifier on the recogniser's photo
fingerprints that sharpens its first guess and adds dishes it never learned.

The 81 MB recogniser (convert.py) is not changed. It already outputs each
photo's fingerprint (1280 numbers, unit length); this trains one softmax layer
(18 x 1280 weights) on those fingerprints, using the labelled photos of
cicerothoma/nigeria_food (MIT, 1,542 photos, 18 dishes). The app applies the
layer in Dart (lib/ai/food_lens.dart, DishHead) and merges it with the
recogniser's own multi-food suggestions.

Accuracy is measured with 5-fold cross-validation: every photo is scored by a
head trained without it, and compared with the recogniser alone.

Run: pip install numpy pillow pyarrow onnxruntime
     python tool/food_model/train_head.py --data nigeria_food.parquet --model assets/models/pronexa-food-v1.onnx
Writes assets/models/pronexa-food-head.json and prints the report.
"""

import argparse
import io
import json
import pathlib
import re

import numpy as np
import onnxruntime as ort
import pyarrow.parquet as pq
from PIL import Image

SIZE = 384
DATASET = "https://huggingface.co/datasets/cicerothoma/nigeria_food (MIT)"

# Dataset dish -> Pronexa database foods (the first is the dish itself).
DISHES = {
    "akara": ["akara"],
    "amala": ["amala"],
    "banga_soup": ["banga"],
    "chin_chin": ["chin_chin"],
    "efo_riro": ["efo_riro"],
    "egusi_soup": ["egusi"],
    "ewedu_soup": ["ewedu"],
    "jollof_rice": ["jollof_rice"],
    "moi_moi": ["moi_moi"],
    "nkwobi": ["assorted"],
    "ofada_rice": ["white_rice"],
    "ogbono_soup": ["ogbono"],
    "okra_soup": ["okra"],
    "pepper_soup": ["pepper_soup"],
    "pounded_yam": ["pounded_yam"],
    "puff_puff": ["puff_puff"],
    "suya": ["suya"],
    "yam_porridge": ["yam_porridge"],
}

ROOT = pathlib.Path(__file__).resolve().parents[2]


def lens_labels() -> list[list[str]]:
    """The recogniser's 41 labels -> database foods, read from the app's own table."""
    src = (ROOT / "lib/ai/food_lens.dart").read_text(encoding="utf8")
    table = src[src.index("const lensLabels") : src.index("];", src.index("const lensLabels"))]
    rows = re.findall(r"\('[^']*', \[([^\]]*)\]\)", table)
    return [re.findall(r"'([^']+)'", r) for r in rows]


def photo_input(data: bytes) -> np.ndarray:
    """Same as the app's lensInput: centre square, 384x384, RGB 0..1, NHWC."""
    im = Image.open(io.BytesIO(data)).convert("RGB")
    side = min(im.size)
    left, top = (im.width - side) // 2, (im.height - side) // 2
    im = im.crop((left, top, left + side, top + side)).resize((SIZE, SIZE), Image.BILINEAR)
    return (np.asarray(im, dtype=np.float32) / 255)[None]


def fingerprints(data_path: str, model_path: str, cache: pathlib.Path):
    if cache.exists():
        z = np.load(cache)
        return z["scores"], z["features"], z["labels"], [str(n) for n in z["names"]]
    table = pq.read_table(data_path)
    names = json.loads(table.schema.metadata[b"huggingface"])["info"]["features"]["label"]["names"]
    assert set(names) == set(DISHES), names
    images = table.column("image").to_pylist()
    labels = np.array(table.column("label").to_pylist())
    session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
    scores, feats = [], []
    for i, img in enumerate(images):
        s, f = session.run(None, {"image": photo_input(img["bytes"])})
        scores.append(s[0])
        feats.append(f[0])
        if i % 100 == 0:
            print(f"  fingerprinted {i}/{len(images)}", flush=True)
    scores, feats = np.array(scores), np.array(feats)
    np.savez(cache, scores=scores, features=feats, labels=labels, names=np.array(names))
    return scores, feats, labels, names


def lens_guesses(scores: np.ndarray, labels41: list[list[str]], threshold=0.2, top=4) -> list[tuple[str, float]]:
    """Python copy of guessesFromScores in lib/ai/food_lens.dart."""
    best: dict[str, float] = {}
    for i, s in enumerate(scores):
        if s < threshold:
            continue
        for food in labels41[i]:
            if s > best.get(food, 0):
                best[food] = float(s)
    return sorted(best.items(), key=lambda kv: -kv[1])[:top]


def train(x: np.ndarray, y: np.ndarray, k: int, l2: float, steps=600, lr=0.5, scale=20.0):
    """Softmax regression on unit-length fingerprints, logits = scale * (W x) + b."""
    w = np.zeros((k, x.shape[1]), dtype=np.float64)
    b = np.zeros(k)
    onehot = np.eye(k)[y]
    for _ in range(steps):
        z = scale * x @ w.T + b
        z -= z.max(1, keepdims=True)
        p = np.exp(z)
        p /= p.sum(1, keepdims=True)
        g = (p - onehot) / len(x)
        w -= lr * (scale * g.T @ x + l2 * w)
        b -= lr * g.sum(0)
    return w, b


def head_probs(x, w, b, scale=20.0):
    z = scale * x @ w.T + b
    z -= z.max(1, keepdims=True)
    p = np.exp(z)
    return p / p.sum(1, keepdims=True)


def merged(lens: list[tuple[str, float]], probs: np.ndarray, names: list[str], min_head: float, top=4):
    """Python copy of DishHead.merge in lib/ai/food_lens.dart: the head's dishes
    at or above [min_head] and the recogniser's foods, ranked together by each
    one's own confidence. (Putting the head's dish always first scores higher on
    this set, 82.9%, but buries foods outside its 18 dishes: on 200 Food-101
    photos of chips, fried rice, omelette, chicken wings and spaghetti the right
    food came first 3.5% of the time instead of 21.5%. This rule: 18.0%.)"""
    best: dict[str, float] = {}
    for i in np.argsort(-probs):
        if probs[i] < min_head:
            break
        for food in DISHES[names[i]]:
            best[food] = max(best.get(food, 0.0), float(probs[i]))
    for food, s in lens:
        best[food] = max(best.get(food, 0.0), s)
    return [f for f, _ in sorted(best.items(), key=lambda kv: -kv[1])][:top]


def report(title, hits1, hitsk, mask):
    n = int(mask.sum())
    return f"{title:<34} first {hits1[mask].sum():>4}/{n} ({100 * hits1[mask].mean():5.1f}%)   in suggestions {hitsk[mask].sum():>4}/{n} ({100 * hitsk[mask].mean():5.1f}%)"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--model", default=str(ROOT / "assets/models/pronexa-food-v1.onnx"))
    ap.add_argument("--out", default=str(ROOT / "assets/models/pronexa-food-head.json"))
    ap.add_argument("--cache", default="fingerprints.npz")
    ap.add_argument("--l2", type=float, default=1e-3)
    ap.add_argument("--min-head", type=float, default=0.35)
    args = ap.parse_args()

    labels41 = lens_labels()
    assert len(labels41) == 41, len(labels41)
    scores, x, y, names = fingerprints(args.data, args.model, pathlib.Path(args.cache))
    k = len(names)
    want = np.array([DISHES[names[c]][0] for c in y])
    lens = [lens_guesses(s, labels41) for s in scores]
    known = {f for row in labels41 for f in row}
    new = np.array([w not in known for w in want])

    # Recogniser alone.
    base1 = np.array([bool(g) and g[0][0] == w for g, w in zip(lens, want)])
    basek = np.array([w in [f for f, _ in g] for g, w in zip(lens, want)])

    # 5-fold cross-validation, stratified by dish, fixed seed.
    rng = np.random.default_rng(7)
    fold = np.empty(len(y), dtype=int)
    for c in range(k):
        idx = rng.permutation(np.flatnonzero(y == c))
        fold[idx] = np.arange(len(idx)) % 5
    new1, newk = np.zeros(len(y), bool), np.zeros(len(y), bool)
    for f in range(5):
        tr, te = fold != f, fold == f
        w, b = train(x[tr], y[tr], k, args.l2)
        p = head_probs(x[te], w, b)
        for j, i in enumerate(np.flatnonzero(te)):
            out = merged(lens[i], p[j], names, args.min_head)
            new1[i] = bool(out) and out[0] == want[i]
            newk[i] = want[i] in out

    every = np.ones(len(y), bool)
    print(f"\n{len(y)} photos, {k} dishes, 5-fold cross-validation (each photo scored by a head that never saw it)\n")
    for tag, a1, ak in (("Recogniser alone", base1, basek), ("Recogniser + dish head", new1, newk)):
        print(tag)
        print("  " + report("all 18 dishes", a1, ak, every))
        print("  " + report("12 dishes it already knew", a1, ak, ~new))
        print("  " + report("dishes it never learned", a1, ak, new))
    print("\nPer dish (first guess: before -> after)")
    for c in range(k):
        m = y == c
        print(f"  {names[c]:<14} {int(m.sum()):>4} photos  {100 * base1[m].mean():5.1f}% -> {100 * new1[m].mean():5.1f}%")

    # Final head on every photo, rounded as shipped.
    w, b = train(x, y, k, args.l2)
    w, b = np.round(w, 4), np.round(b, 4)
    pathlib.Path(args.out).write_text(
        json.dumps(
            {
                "source": DATASET,
                "trainedOn": int(len(y)),
                "scale": 20.0,
                "minScore": args.min_head,
                "dishes": [{"name": n, "foods": DISHES[n]} for n in names],
                "bias": b.tolist(),
                "weights": w.tolist(),
            },
            separators=(",", ":"),
        )
        + "\n"
    )
    print(f"\n{args.out} written ({pathlib.Path(args.out).stat().st_size / 1e3:.0f} KB)")


if __name__ == "__main__":
    main()

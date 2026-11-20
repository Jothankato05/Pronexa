"""Builds Pronexa's on-phone food recogniser.

Source: "Nigerian Food Lens" by yusasif on Hugging Face (Apache-2.0), an
EfficientNetV2-S multi-label classifier for 41 Nigerian foods, pinned to one
commit and checked against a known SHA-256.

Output (in --out, normally assets/models): pronexa-food-v1.onnx (float32,
exactly the original model's answers) and pronexa-food-v1.labels.json. The
app bundles both.

Model input: "image", float32 [1, 384, 384, 3], RGB in 0..1 (centre-cropped
square). Normalisation and sigmoid are inside the graph. Output: "scores",
float32 [1, 41], one probability per label.

Run: pip install -r tool/food_model/requirements.txt
     python tool/food_model/convert.py --out assets/models
"""

import argparse
import hashlib
import json
import pathlib
import urllib.request

import numpy as np
import onnx
import onnxruntime as ort
import torch
from torch import nn
from torchvision import models

REPO = "yusasif/Nigerian-food-recognision"
REVISION = "36a13b5de1ecc61162f7d1ee21e28b11420cdb29"
WEIGHTS_SHA256 = "7857709a114ea3c868d0e7a6abf42d9031e8704964b6be26437d8a289c70372f"
SIZE = 384


def fetch(name: str, dest: pathlib.Path) -> pathlib.Path:
    url = f"https://huggingface.co/{REPO}/resolve/{REVISION}/{name}"
    path = dest / name
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return path


def sha256(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def load_state_dict(path: pathlib.Path) -> dict:
    # Weights only: never run code from the checkpoint. Allow the two numpy
    # data types the file stores its metrics in.
    from numpy._core.multiarray import scalar

    safe = [(scalar, "numpy.core.multiarray.scalar"), np.dtype, type(np.dtype("float64"))]
    with torch.serialization.safe_globals(safe):
        ck = torch.load(path, map_location="cpu", weights_only=True)
    return ck["model_state_dict"]


class Wrapped(nn.Module):
    """NHWC 0..1 RGB in, sigmoid scores out."""

    def __init__(self, net: nn.Module):
        super().__init__()
        self.net = net
        self.register_buffer("mean", torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1))

    def forward(self, x):
        x = (x.permute(0, 3, 1, 2) - self.mean) / self.std
        return torch.sigmoid(self.net(x))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/models")
    ap.add_argument("--cache", default=".cache")
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    cache = pathlib.Path(args.cache)
    out.mkdir(parents=True, exist_ok=True)
    cache.mkdir(parents=True, exist_ok=True)

    weights = fetch("best_model.pth", cache)
    if sha256(weights) != WEIGHTS_SHA256:
        raise SystemExit("best_model.pth does not match the pinned SHA-256")
    labels = json.loads(fetch("label_vocab.json", cache).read_text())["labels"]

    net = models.efficientnet_v2_s(weights=None)
    net.classifier = nn.Sequential(nn.Dropout(p=0.3, inplace=True), nn.Linear(net.classifier[1].in_features, len(labels)))
    net.load_state_dict(load_state_dict(weights))
    model = Wrapped(net).eval()

    final = out / "pronexa-food-v1.onnx"
    x = torch.rand(1, SIZE, SIZE, 3)
    torch.onnx.export(model, (x,), final, input_names=["image"], output_names=["scores"], opset_version=17, dynamo=False)
    onnx.checker.check_model(str(final))

    # The exported model must give PyTorch's answers.
    session = ort.InferenceSession(str(final), providers=["CPUExecutionProvider"])
    rng = np.random.default_rng(0)
    worst = 0.0
    for _ in range(3):
        r = rng.random((1, SIZE, SIZE, 3), dtype=np.float32)
        with torch.no_grad():
            want = model(torch.from_numpy(r)).numpy()
        worst = max(worst, float(np.abs(session.run(None, {"image": r})[0] - want).max()))
    if worst > 1e-4:
        raise SystemExit(f"ONNX export differs from PyTorch ({worst:.6f})")

    (out / "pronexa-food-v1.labels.json").write_text(
        json.dumps({"source": f"https://huggingface.co/{REPO}/tree/{REVISION}", "license": "Apache-2.0", "input": [1, SIZE, SIZE, 3], "labels": labels}, indent=2) + "\n"
    )
    print(f"{final} written ({final.stat().st_size / 1e6:.1f} MB, sha256 {sha256(final)}, max difference from PyTorch {worst:.2e})")


if __name__ == "__main__":
    main()

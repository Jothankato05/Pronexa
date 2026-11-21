"""Finishes the PWA after flutter build web: versions the service worker,
records the recogniser's download size, and lists the files to keep offline."""

import hashlib
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")

# Large files are stored only when the student downloads photo recognition.
LARGE = ("assets/assets/models/pronexa-food-v1.onnx", "ort/ort-wasm-simd-threaded.wasm", "ort/ort-wasm-simd-threaded.mjs")
SKIP_DIRS = ("canvaskit/",)  # the page reports the engine it uses (web/index.html)
SKIP = {"sw.js", "precache.json", ".last_build_id", "flutter_service_worker.js"}

files = []
digest = hashlib.sha256()
for p in sorted(out.rglob("*")):
    if not p.is_file():
        continue
    rel = p.relative_to(out).as_posix()
    if rel in SKIP or rel.endswith((".map", ".symbols")) or rel in LARGE or rel.startswith(SKIP_DIRS) or rel == "ort/NOTICE.txt":
        continue
    files.append(rel)
    digest.update(rel.encode())
    digest.update(p.read_bytes())
files.insert(0, "index.html") if "index.html" not in files else None
(out / "precache.json").write_text(json.dumps(files, indent=0) + "\n")

version = digest.hexdigest()[:12]
sw = out / "sw.js"
sw.write_text(sw.read_text().replace("__PRONEXA_VERSION__", version))

model = out / LARGE[0]
engine = sum((out / f).stat().st_size for f in LARGE[1:] if (out / f).exists())
lens = out / "lens.js"
text = lens.read_text()
if model.exists():
    text = text.replace("__MODEL_BYTES__", str(model.stat().st_size))
text = text.replace("__ENGINE_BYTES__", str(engine))
lens.write_text(text)

size = sum((out / f).stat().st_size for f in files)
print(f"PWA ready: version {version}, {len(files)} files kept offline ({size / 1e6:.1f} MB)"
      + (f", photo recognition {(model.stat().st_size + engine) / 1e6:.0f} MB on request" if model.exists() else ", no photo model in this build"))

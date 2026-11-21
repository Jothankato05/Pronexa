#!/usr/bin/env bash
# Builds the Pronexa PWA into build/web.
#   tool/web/build.sh [base-href]     e.g. tool/web/build.sh /Pronexa/
# Photo recognition needs the model in assets/models first
# (python tool/food_model/convert.py --out assets/models); without it the
# web app still works and students pick foods by hand.
set -euo pipefail
cd "$(dirname "$0")/../.."
BASE_HREF="${1:-/}"

# ONNX Runtime Web (MIT), pinned and checked against the npm registry's hash.
ORT_VERSION=1.31.1
ORT_SHA512=5GeH+bWQ+HxM10z7erGlsWqryrwMbSvm/1tkIsKTT48g0fI19VXVVC435t4t7VsPdSQeS7NmuZPXrQ73k82URw==
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/ort.tgz" "https://registry.npmjs.org/onnxruntime-web/-/onnxruntime-web-$ORT_VERSION.tgz"
got="$(openssl dgst -sha512 -binary "$tmp/ort.tgz" | base64 -w0)"
if [ "$got" != "$ORT_SHA512" ]; then echo "ONNX Runtime Web download does not match its hash" >&2; exit 1; fi
tar -xzf "$tmp/ort.tgz" -C "$tmp" package/dist/ort.wasm.min.js package/dist/ort-wasm-simd-threaded.mjs package/dist/ort-wasm-simd-threaded.wasm
rm -rf web/ort && mkdir -p web/ort
cp "$tmp"/package/dist/ort.wasm.min.js "$tmp"/package/dist/ort-wasm-simd-threaded.mjs "$tmp"/package/dist/ort-wasm-simd-threaded.wasm web/ort/
echo "onnxruntime-web $ORT_VERSION (MIT licence, Microsoft), https://github.com/microsoft/onnxruntime" > web/ort/NOTICE.txt

DEFINE=()
if [ -n "${PRONEXA_AI_URL:-}" ]; then DEFINE=(--dart-define=PRONEXA_AI_URL="$PRONEXA_AI_URL"); fi
flutter build web --release --no-web-resources-cdn --base-href "$BASE_HREF" "${DEFINE[@]}"
python3 tool/web/finalize.py build/web

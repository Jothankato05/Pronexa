"""Deploys the Pronexa website to Vercel with the REST API (no Vercel CLI needed).

  VERCEL_TOKEN=... python3 tool/web/deploy_vercel.py --team <team id> [--apk build/Pronexa.apk] [--apk-url URL] [--ipa-url URL]

Layout of the deployment:
  /            the website (site/)
  /app/        the PWA (build/web, built with tool/web/build.sh /app/)
  /download/   the Android app, when --apk is given and the plan accepts the file size

Without --apk, the download buttons point to --apk-url (for example the latest GitHub Release).
"""

import argparse
import hashlib
import json
import os
import pathlib
import sys
import tempfile
import time
import urllib.error
import urllib.request

API = "https://api.vercel.com"
ROOT = pathlib.Path(__file__).resolve().parents[2]


def call(method, path, token, body=None, headers=None, team=None):
    url = f"{API}{path}{'&' if '?' in path else '?'}teamId={team}" if team else f"{API}{path}"
    h = {"Authorization": f"Bearer {token}"}
    h.update(headers or {})
    data = body
    if isinstance(body, (dict, list)):
        data = json.dumps(body).encode()
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=900) as r:
            text = r.read().decode() or "{}"
            return r.status, json.loads(text)
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def collect(site: pathlib.Path, app: pathlib.Path, apk: pathlib.Path | None, apk_url: str, ipa_url: str, pitch_pdf: str, pitch_pptx: str):
    files = {}
    for p in site.rglob("*"):
        if p.is_file():
            files[p.relative_to(site).as_posix()] = p
    for p in app.rglob("*"):
        if p.is_file() and not p.name.endswith((".map", ".symbols")) and p.name != "flutter_service_worker.js":
            files["app/" + p.relative_to(app).as_posix()] = p
    link = "/download/Pronexa.apk" if apk else apk_url
    page = (site / "index.html").read_text().replace("__APK_URL__", link).replace("__IPA_URL__", ipa_url).replace("__PITCH_PPTX_URL__", pitch_pptx)
    tmp = pathlib.Path(tempfile.mkdtemp()) / "index.html"
    tmp.write_text(page)
    files["index.html"] = tmp
    if apk:
        files["download/Pronexa.apk"] = apk
    config = {
        "redirects": [{"source": "/pitch", "destination": pitch_pdf, "permanent": False}],
        "headers": [
            {"source": "/app/sw.js", "headers": [{"key": "Cache-Control", "value": "no-cache"}]},
            {"source": "/app/(index.html|precache.json|lens.js|flutter_bootstrap.js|main.dart.js)", "headers": [{"key": "Cache-Control", "value": "no-cache"}]},
            {"source": "/download/(.*)", "headers": [{"key": "Content-Disposition", "value": "attachment; filename=Pronexa.apk"}, {"key": "Content-Type", "value": "application/vnd.android.package-archive"}]},
        ],
    }
    cfg = tmp.parent / "vercel.json"
    cfg.write_text(json.dumps(config, indent=2))
    files["vercel.json"] = cfg
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--team", required=True)
    ap.add_argument("--project", default="pronexa")
    ap.add_argument("--site", default=str(ROOT / "site"))
    ap.add_argument("--app", default=str(ROOT / "build/web"))
    ap.add_argument("--apk")
    ap.add_argument("--apk-url", default="https://github.com/Jothankato05/Pronexa/releases/latest/download/Pronexa.apk")
    ap.add_argument("--ipa-url", default="https://github.com/Jothankato05/Pronexa/releases/latest")
    ap.add_argument("--pitch-pdf", default="https://github.com/Jothankato05/Pronexa")
    ap.add_argument("--pitch-pptx", default="https://github.com/Jothankato05/Pronexa")
    args = ap.parse_args()
    token = os.environ.get("VERCEL_TOKEN") or sys.exit("Set VERCEL_TOKEN")

    files = collect(pathlib.Path(args.site), pathlib.Path(args.app), pathlib.Path(args.apk) if args.apk else None, args.apk_url, args.ipa_url, args.pitch_pdf, args.pitch_pptx)
    listing = []
    for name, path in sorted(files.items()):
        data = path.read_bytes()
        sha = hashlib.sha1(data).hexdigest()
        status, body = call("POST", "/v2/files", token, data, {"x-vercel-digest": sha, "Content-Type": "application/octet-stream"}, args.team)
        if status != 200:
            print(f"upload failed for {name} ({len(data) / 1e6:.1f} MB): {status} {body}")
            sys.exit(2)
        listing.append({"file": name, "sha": sha, "size": len(data)})
    print(f"uploaded {len(listing)} files ({sum(f['size'] for f in listing) / 1e6:.1f} MB)")

    status, dep = call("POST", "/v13/deployments?skipAutoDetectionConfirmation=1", token, {
        "name": args.project,
        "project": args.project,
        "target": "production",
        "files": listing,
        "projectSettings": {"framework": None, "buildCommand": None, "installCommand": None, "outputDirectory": None},
    }, team=args.team)
    if status >= 300:
        print("deployment failed:", status, dep)
        sys.exit(3)
    dep_id = dep["id"]
    print("deployment", dep_id, dep.get("url"))
    for _ in range(120):
        status, d = call("GET", f"/v13/deployments/{dep_id}", token, team=args.team)
        state = d.get("readyState")
        if state in ("READY", "ERROR", "CANCELED"):
            print("state", state, "https://" + d.get("url", ""))
            sys.exit(0 if state == "READY" else 4)
        time.sleep(5)
    print("still building")


if __name__ == "__main__":
    main()

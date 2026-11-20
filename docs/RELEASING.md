# Releasing Pronexa

## The signing key

Release APKs are signed with Pronexa's upload key, `android/pronexa-upload.jks`, whose passwords are in `android/key.properties`. Both files are gitignored and must never be committed.

**Back them up somewhere safe (two places).** Android only installs an update over an app signed with the same key. If the key is lost, every student would have to uninstall Pronexa (losing their meal log) to get a new version.

Local signed build (both files present):

```bash
python tool/food_model/convert.py --out assets/models   # once; see docs/PHOTO.md
flutter build apk --release -P force-version-code-ignoring-abi=true
```

Without the key files, release builds fall back to the debug key (fine for testing, not for students).

## Publishing a release on GitHub

APKs are not stored in the repository; they go on GitHub Releases.

One-time setup, in the repository **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|--------|-------|
| `PRONEXA_KEYSTORE_BASE64` | the keystore as base64: `base64 -w0 android/pronexa-upload.jks` (macOS: `base64 -i android/pronexa-upload.jks`) |
| `PRONEXA_STORE_PASSWORD` | `storePassword` from `android/key.properties` |
| `PRONEXA_KEY_ALIAS` | `pronexa` |
| `PRONEXA_KEY_PASSWORD` | `keyPassword` from `android/key.properties` |

Optional variable: `PRONEXA_AI_URL` (see `docs/AI_SERVER.md`).

Then for each version:

1. Bump `version:` in `pubspec.yaml` (for example `0.6.0+7`; the number after `+` must always go up).
2. Commit and merge to `main`.
3. Tag it: `git tag v0.6.0 && git push origin v0.6.0`, or open **Actions → Release → Run workflow** and type the tag.

The workflow builds the food recogniser into the app, runs the tests, builds one APK signed with the key, and publishes it with a checksum at `https://github.com/<owner>/Pronexa/releases`.

## Play Store (later)

Use the same key as the upload key when you enrol in Play App Signing. Build an app bundle with `flutter build appbundle --release`.

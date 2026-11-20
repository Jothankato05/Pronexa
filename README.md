# Pronexa

Check your protein. Close the gap for less.

An Android app (built with Flutter) for Nigerian university students. Log meals the way you buy them, in naira, packs, wraps and spoons, see an estimate of how much protein you've had, and get cheap ways to close the gap. Beans, moi-moi, akara, soya, awara, groundnuts, okpa and lentils come first.

> Estimates only. Not medical advice.

## Install

Android 7.0 or newer. On the phone, allow "Install unknown apps" for your browser or file manager, then open the file. Each file updates the same file from an earlier build.

| File | Size | Use |
|------|------|-----|
| `release/Pronexa-0.3.0-small.apk` | 17 MB | Most Android phones, including budget Tecno, Infinix and itel phones. Try this first to save data |
| `release/Pronexa-0.3.0.apk` | 55 MB | Works on every phone. Use it if the small one says "App not installed" |

Checksums are in `release/SHA256SUMS.txt`. Screens are in `docs/screens/`.

## What it does

1. **Set up:** diet (no restrictions, vegetarian, vegan, pescatarian, dairy-free, egg-free), allergies asked separately, weight and activity. This gives a daily target as a range.
2. **Log a meal, four ways:**
   - **Pick:** tap foods from the list. Works offline.
   - **Portion:** choose the pack, plate, bowl or wrap, what was in it, extras, and how much you ate. Works offline.
   - **Photo:** take a photo or choose one from the gallery. With the AI server set up, Pronexa reads the photo; otherwise you pick the foods while looking at it.
   - **Describe:** type it in English or Pidgin, for example "₦1,000 rice and beans, medium takeaway". Read by the AI server when one is set up and online, otherwise by the phone's own reader.
3. **Confirm:** check and fix the foods, portions and how much you ate. Nothing counts until you confirm.
4. **Today:** target, eaten and gap, as ranges.
5. **Close the gap:** combos within your budget, additions to the meals you ate, and foods ranked by protein per ₦100. Plant protein first, and vegans never see animal products.

## How it is built

| Part | Language | Where |
|------|----------|-------|
| App | Dart (Flutter 3.47) | `lib/` |
| Android shell | Kotlin, Gradle | `android/` |
| Optional AI meal reader | TypeScript (Node 22, Anthropic SDK) | `server/` |
| Food-list export, icon tool | Dart, JavaScript | `tool/` |

```
lib/
  data/      food database (36 foods), portions, models
  logic/     protein calculation, diet rules, gap solver
  ai/        on-phone reader, validator (guard rail), remote reader client
  state/     app state and on-phone storage
  ui/        theme, widgets, screens
test/        unit, regression and end-to-end widget tests
server/      AI meal reader (text and photos)
docs/        DESIGN.md, GUARDRAILS.md, screens/
```

**The AI reads; the database counts.** Any reader (the phone's rules or the AI server) may only pick food ids from the database. `lib/ai/validator.dart` drops anything else, fixes portions, and decides how sure it is and what to ask. Protein numbers come only from `lib/data/foods.dart`.

## Develop

```bash
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test                       # 60 tests
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter test test_screens --update-goldens   # re-render docs/screens
```

### Turn on the AI reader (optional)

The app works without it. To read photos and handle unusual descriptions, deploy `server/` and build the app with its address:

```bash
cd server
npm ci && npm run build
ANTHROPIC_API_KEY=... npm start      # or: docker build -t pronexa-reader . && docker run -e ANTHROPIC_API_KEY=... -p 8080:8080 pronexa-reader

# then build the app pointing at it (HTTPS only):
flutter build apk --release --dart-define=PRONEXA_AI_URL=https://your-reader.example.com
```

The key stays on the server. The server uses Claude Opus 5.5 at low effort with structured output limited to the food list, and turns on Anthropic's server-side refusal fallback, so a wrongly declined request is retried on another model. After any change to `lib/data/foods.dart`, run `dart run tool/export_foods.dart`; a test fails if the server's list is out of date.

### Release signing

`release/` holds an APK signed with a debug key for testing. Before publishing to the Play Store, create your own upload key (never commit it), add a `signingConfig` to `android/app/build.gradle.kts`, and rebuild.

## Guardrails

See `docs/GUARDRAILS.md`: strict analysis, tests, pinned dependencies, no secrets in the app, input validation, a privacy-first photo flow, minimal permissions, and accessibility. CI runs the checks on every push.

## Limits

- Protein values and portion weights are starter estimates (WAFCT 2019, USDA). A nutrition professional and real vendor measurements should check them before a pilot.
- The 32-description test set was written with the phone's reader, so 32/32 is a regression check, not an accuracy score.
- The AI server code is tested without a live key. Measure its accuracy on fresh descriptions and photos before relying on it.
- The APK has been built and checked but not yet run on a physical phone in this environment.

## Credits

Navy look and layout based on the Asteria app design and the Assistant Pill by HorizonX, used under the project owner's licence. Fonts: Poppins and Nunito (SIL OFL).

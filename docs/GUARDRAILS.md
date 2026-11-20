# Engineering guardrails

Rules this codebase follows so that fast, AI-assisted ("vibe") coding stays safe. Each rule says how it is applied here and how it is checked. CI (`.github/workflows/ci.yml`) enforces the checkable ones on every push.

## 1. Code quality

| Rule | How it's applied | Checked by |
|------|------------------|------------|
| No warnings, no lint noise | Strict analyzer (`strict-casts`, `strict-inference`, `strict-raw-types`) plus extra lints in `analysis_options.yaml` | `flutter analyze --fatal-infos --fatal-warnings` in CI |
| One code style | `dart format` with a 160-column page width | `dart format --set-exit-if-changed` in CI |
| Typed code only | No `dynamic` calls (`avoid_dynamic_calls`); the server is strict TypeScript (`strict`, `noUncheckedIndexedAccess`) | Analyzer and `tsc` |
| Small, focused files | Data, logic, AI, state and UI are separate folders; no file mixes storage with UI | Review |
| No dead or fake code | No demo-only fake behaviour presented as real, and no decorative status badges (no fake "synced" or "saved" states) | Review |

## 2. Tests

| Rule | How it's applied | Checked by |
|------|------------------|------------|
| Logic is tested | Calculation, diet safety, solver and AI guard rails: `test/logic_test.dart` | `flutter test` |
| AI behaviour has a regression set | 32 English, Pidgin and price-based descriptions: `test/reader_eval_test.dart`. It was written with the rules, so it is a regression check, not an accuracy claim | `flutter test` |
| Real user flows are tested | Onboarding, Pick, Describe, Photo (with a fake camera) and vegan suggestions: `test/app_flow_test.dart` | `flutter test` |
| Safety rules have explicit tests | "A vegan never sees an animal product" runs at every budget and in both modes | `flutter test` |
| Server checks are tested | Schema rejects unknown foods; portions and quantities are clamped: `server/src/validate.test.ts` | `npm test` |

## 3. Security and secrets

| Rule | How it's applied |
|------|------------------|
| No secrets in the app or the repo | The app holds no API key. The AI key lives only on the server, as the `ANTHROPIC_API_KEY` environment variable. `.env`, keystores and `key.properties` are gitignored |
| HTTPS only | The app only calls an AI endpoint that starts with `https://`; Android cleartext traffic is off |
| Validate every input at the boundary | App: text capped at 280 characters, photos at 1.5 MB, AI JSON parsed defensively (`RawReading.fromJson`) and re-validated against the database (`validator.dart`). Server: content type, body size (2.2 MB), text length, base64 format, image type, and a per-IP rate limit |
| AI output is never trusted | The model may only return food ids from the list (schema enum). Portions, quantities and fractions are clamped on the server and again in the app. Protein numbers come only from the database |
| Fail safe | AI errors, timeouts, refusals or bad JSON fall back to the on-phone reader, or to Pick |
| Pinned dependencies | Every package is pinned to an exact version (`pubspec.yaml`, `server/package.json`), with lockfiles committed. New releases were held back until about two weeks old |
| Few dependencies | App: 5 runtime packages. Server: 2 (Anthropic SDK, zod) and `node:http` |
| Vulnerability scan | `npm audit --audit-level=high` in CI |

## 4. Privacy

| Rule | How it's applied |
|------|------------------|
| Minimal data | No name, email, phone number or account. Only diet, allergies, weight, activity and meals |
| Data stays on the phone | Stored with `shared_preferences`. Android cloud backup is turned off (`allowBackup="false"`) so health data doesn't leave without consent |
| Photos aren't kept | Photo mode reads the image into memory, deletes the temporary file at once, and never saves it. A photo is sent only when the student taps "Read the photo", only to the configured AI server, and never in low-data mode. Location metadata is stripped (`requestFullMetadata: false`) |
| Minimal permissions | Internet and network state only. No camera permission: Photo mode uses the phone's own camera app |
| No user content in logs | The server logs only method, path, status and duration |
| User control | Copy my data, and Delete all my data (with confirmation) in Profile |
| Old data expires | Meals older than 120 days are dropped |

## 5. Product honesty

| Rule | How it's applied |
|------|------------------|
| Estimates are labelled | Every number is a range, and key screens carry "Estimates only. Not medical advice." |
| Price is a clue, not a measure | Price only suggests which portion to confirm, and the student is asked |
| Nothing is counted without confirmation | Every logging route ends on the Confirm screen |
| Data sources are stated | Each food carries its source, and Profile → About the numbers says the values need professional review |

## 6. Accessibility and low-end phones

| Rule | How it's applied |
|------|------------------|
| Tap targets of 44–48 px or more | Pills, steppers, tiles and nav buttons |
| Screen-reader labels | `Semantics` on the nav, actions, tiles and ring |
| Text scaling | Rows use `Flexible` or `Expanded`; widget tests run with a wide test font to catch overflow |
| Reduced motion | Every transition, count-up and rotating example is skipped when the system asks for less motion |
| Contrast | Every text and background pair meets WCAG AA (see `docs/DESIGN.md`) |
| Light on old phones | Release build is AOT-compiled; ripple effect instead of shader-based sparkle; no gradients or blur; photos downscaled to 1280 px |

## 7. If you have your own guardrail list

The vibecoding guardrails document shared in chat was private and couldn't be read, so this list follows widely used practice. Share the document (set to "Anyone with the link") or attach it, and any extra rules can be added here and enforced in CI.

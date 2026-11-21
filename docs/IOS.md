# Pronexa on iPhone

The same Flutter app runs on iPhone (iOS 15.1 or newer), with every feature, including Photo mode's on-phone food recogniser and photo memory.

## How it's built

- `ios/`: the iPhone app (bundle id `ng.pronexa.app`, iPhone only, portrait, navy launch screen and icon from `tool/make_icons.mjs`).
- `packages/pronexa_lens/`: the iOS side of the food recogniser. It runs the same model file as Android with ONNX Runtime 1.28.0 (CocoaPods `onnxruntime-objc`, pinned), on a background queue, through the same `pronexa/lens` channel. The model is read straight from the app bundle, and released if iOS runs low on memory.
- `integration_test/lens_test.dart`: runs the recogniser on an iPhone simulator and checks its numbers against the same model on a desktop.

iOS apps can only be built on a Mac. The **iOS** workflow (`.github/workflows/ios.yml`) does it on GitHub's Macs on every push that touches the app: it converts the model, runs the simulator test, builds the app and uploads `Pronexa-unsigned.ipa` (Actions → iOS → the run → Artifacts). The **Release** workflow attaches the same file to each release, next to the APK.

## Installing it on an iPhone

Apple only lets signed apps onto an iPhone. Two ways:

**Free, for testing (your own Apple ID)**
1. On a Windows PC or Mac, install [Sideloadly](https://sideloadly.io) (or AltStore).
2. Connect the iPhone, drag in the `.ipa`, sign in with your Apple ID and press Start.
3. On the iPhone: Settings → General → VPN & Device Management → trust your Apple ID. On iOS 16 or newer also turn on Settings → Privacy & Security → Developer Mode.

A free Apple ID signature lasts 7 days (then sign it again) and covers up to 3 apps per phone.

**TestFlight and the App Store (Apple Developer Program, $99 a year)**
1. Join the Apple Developer Program and create the app `ng.pronexa.app` in App Store Connect.
2. On a Mac with Xcode, open `ios/Runner.xcworkspace`, choose your team under Signing & Capabilities, then `flutter build ipa` and upload with Transporter. Or add signing to the workflow with an App Store Connect API key.
3. Invite testers in TestFlight (up to 10,000, no 7-day limit), then submit for review.

## Differences from Android

- iOS asks once for camera or photo access when Photo mode opens the camera or the photo library (Android needs no permission). The prompts say the photo stays on the phone.
- The app is large on iPhone too, because it carries the 81 MB model and ONNX Runtime.

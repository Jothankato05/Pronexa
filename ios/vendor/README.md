# ONNX Runtime for iOS

The iPhone food recogniser (`packages/pronexa_lens`) uses ONNX Runtime 1.28.0. Its official CocoaPods
download host, download.onnxruntime.ai, started serving a certificate for a different name in November 2026,
so `pod install` failed. The Podfile now takes the same release from Microsoft's own sources:

- `onnxruntime-c.podspec.json`: the official podspec with its source switched to the NuGet package
  `Microsoft.ML.OnnxRuntime` 1.28.0, which contains the same `onnxruntime.xcframework` and headers. CocoaPods
  checks it against a SHA-256 before use.
- `onnxruntime-objc/`: the Objective-C API (about 90 KB of source), unchanged from Microsoft's
  `pod-archive-onnxruntime-objc-1.28.0.zip`, MIT licence in `LICENSE`.

When the official host works again, these two lines can be removed from `ios/Podfile`.

import Flutter
import UIKit
import onnxruntime_objc

/// Pronexa's on-phone food recogniser on iOS: the same model and the same
/// "pronexa/lens" channel as Android (MainActivity.kt and LensEngine.java).
///
/// The model ships inside the app bundle and is read from there directly. All
/// loading and inference happen on one background queue, never the main thread.
public final class PronexaLensPlugin: NSObject, FlutterPlugin {
  static let size = 384
  static let labels = 41
  static let features = 1280

  private let modelKey: String
  private let queue = DispatchQueue(label: "ng.pronexa.lens", qos: .userInitiated)
  private var env: ORTEnv?
  private var session: ORTSession?

  init(modelKey: String) {
    self.modelKey = modelKey
    super.init()
    // Give the memory back if iOS runs short; the model reloads on the next photo.
    NotificationCenter.default.addObserver(
      self, selector: #selector(memoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pronexa/lens", binaryMessenger: registrar.messenger())
    let instance = PronexaLensPlugin(modelKey: registrar.lookupKey(forAsset: "assets/models/pronexa-food-v1.onnx"))
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepare":
      // Load the model while the student takes the photo.
      queue.async { [weak self] in
        do { _ = try self?.loadedSession() } catch { self?.close() }
      }
      result(nil)
    case "recognise":
      guard let args = call.arguments as? [String: Any],
        let image = args["image"] as? FlutterStandardTypedData,
        image.type == .float32,
        image.data.count == Self.size * Self.size * 3 * MemoryLayout<Float32>.size
      else {
        result(FlutterError(code: "BAD_INPUT", message: "Expected a 384 x 384 RGB image", details: nil))
        return
      }
      queue.async { [weak self] in
        guard let self = self else { return }
        do {
          let (scores, features) = try self.run(image.data)
          DispatchQueue.main.async {
            result(["scores": FlutterStandardTypedData(float32: scores), "features": FlutterStandardTypedData(float32: features)])
          }
        } catch {
          self.close()
          DispatchQueue.main.async {
            result(FlutterError(code: "LENS_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Call only on `queue`.
  private func loadedSession() throws -> ORTSession {
    if let session = session { return session }
    guard let path = Bundle.main.path(forResource: modelKey, ofType: nil) else {
      throw LensError.missingModel
    }
    let env = try ORTEnv(loggingLevel: .warning)
    let options = try ORTSessionOptions()
    // A few threads is enough for one photo and keeps the phone responsive.
    try options.setIntraOpNumThreads(Int32(max(1, min(4, ProcessInfo.processInfo.activeProcessorCount))))
    try options.setGraphOptimizationLevel(.all)
    let session = try ORTSession(env: env, modelPath: path, sessionOptions: options)
    self.env = env
    self.session = session
    return session
  }

  /// Call only on `queue`. Returns the 41 label scores and the unit-length
  /// 1280-number fingerprint used by the app's photo memory.
  private func run(_ image: Data) throws -> (Data, Data) {
    let session = try loadedSession()
    let input = NSMutableData(data: image)
    let shape: [NSNumber] = [1, NSNumber(value: Self.size), NSNumber(value: Self.size), 3]
    let tensor = try ORTValue(tensorData: input, elementType: .float, shape: shape)
    let out = try session.run(withInputs: ["image": tensor], outputNames: ["scores", "features"], runOptions: nil)
    guard let scores = try out["scores"]?.tensorData(), let features = try out["features"]?.tensorData(),
      scores.length == Self.labels * MemoryLayout<Float32>.size,
      features.length == Self.features * MemoryLayout<Float32>.size
    else {
      throw LensError.unexpectedOutput
    }
    // Copy out: the outputs' memory belongs to ORT and goes when `out` does.
    return (Data(bytes: scores.bytes, count: scores.length), Data(bytes: features.bytes, count: features.length))
  }

  private func close() {
    session = nil
    env = nil
  }

  @objc private func memoryWarning() {
    queue.async { [weak self] in self?.close() }
  }

  enum LensError: LocalizedError {
    case missingModel
    case unexpectedOutput

    var errorDescription: String? {
      switch self {
      case .missingModel: return "The recogniser is not in this build"
      case .unexpectedOutput: return "Unexpected model output"
      }
    }
  }
}

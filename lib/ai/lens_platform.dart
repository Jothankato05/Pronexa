/// The food recogniser for this platform: ONNX Runtime through the native
/// apps' "pronexa/lens" channel on Android and iPhone, ONNX Runtime Web in the
/// browser (web/lens.js).
library;

export 'lens_native.dart' if (dart.library.js_interop) 'lens_web.dart';

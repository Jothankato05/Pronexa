import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'food_lens.dart';

FoodLens createLens() => WebLens();

@JS('pronexaLens')
external _LensJs? get _js;

extension type _LensJs(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> isDownloaded(JSString modelUrl);
  external JSPromise<JSAny?> download(JSString modelUrl, JSFunction onProgress);
  external JSPromise<JSAny?> prepare(JSString modelUrl);
  external JSPromise<_Out> recognise(JSString modelUrl, JSFloat32Array image);
  external JSNumber get downloadBytes;
}

extension type _Out(JSObject _) implements JSObject {
  external JSFloat32Array get scores;
  external JSFloat32Array get features;
}

/// The same model in the browser, with ONNX Runtime Web (web/lens.js). The
/// model is not downloaded until the student asks for it (about 96 MB once),
/// then it is kept in the browser's storage and works offline.
class WebLens implements DownloadableLens {
  bool? _available;

  String get _url => ui_web.assetManager.getAssetUrl(lensAsset);

  @override
  Future<bool> isAvailable() async => _available ??= _js != null && await lensBundled();

  @override
  int get downloadBytes => _js?.downloadBytes.toDartInt ?? 0;

  @override
  Future<bool> isDownloaded() async {
    try {
      return (await _js!.isDownloaded(_url.toJS).toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> download(void Function(double progress) onProgress) async {
    await _js!.download(_url.toJS, ((JSNumber p) => onProgress(p.toDartDouble)).toJS).toDart;
  }

  @override
  Future<void> prepare() async {
    try {
      await _js!.prepare(_url.toJS).toDart;
    } catch (_) {
      // recognise() reports it.
    }
  }

  @override
  Future<LensResult> recognise(Uint8List photo) async {
    try {
      final input = await lensInput(photo);
      final out = await _js!.recognise(_url.toJS, input.toJS).toDart;
      return await lensResultFrom(out.scores.toDart, out.features.toDart);
    } catch (_) {
      return LensResult.empty; // The student picks the foods by hand.
    }
  }
}

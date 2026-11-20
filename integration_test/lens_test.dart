// Runs the real on-phone food recogniser on a device or simulator:
//   flutter test integration_test -d <device>
// CI runs it on an iOS simulator (.github/workflows/ios.yml). Needs the model
// in assets/models (tool/food_model/convert.py).
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pronexa/ai/food_lens.dart';
import 'package:pronexa/ai/photo_memory.dart';

/// Scores from the same model with ONNX Runtime on a desktop, for [_fixedInput].
const _expectedScores = <double>[
  0.7038, 0.5777, 0.6897, 0.5003, 0.4263, 0.3371, 0.4877, 0.4575, 0.3377, 0.6766, 0.4755, 0.557, 0.506, 0.5801, //
  0.6418, 0.5563, 0.7215, 0.6338, 0.4749, 0.6217, 0.6686, 0.5301, 0.4507, 0.8173, 0.611, 0.5702, 0.6331, 0.4192, //
  0.6618, 0.5841, 0.4812, 0.6694, 0.3326, 0.5306, 0.5175, 0.5004, 0.6026, 0.5837, 0.4575, 0.5866, 0.5341,
];
const _expectedFeatures = <double>[0.01429, -0.01479, 0.03559, -0.0182, 0.01244, -0.01764, 0.03618, 0.01554];

Float32List _fixedInput() {
  final x = Float32List(lensSize * lensSize * 3);
  for (var i = 0; i < x.length; i++) {
    x[i] = (i * 37) % 251 / 250;
  }
  return x;
}

Future<Uint8List> _photo() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..drawColor(const ui.Color(0xFFF4E3C1), ui.BlendMode.src);
  canvas.drawCircle(const ui.Offset(320, 240), 150, ui.Paint()..color = const ui.Color(0xFFE0542B));
  canvas.drawCircle(const ui.Offset(300, 220), 40, ui.Paint()..color = const ui.Color(0xFF6B8E23));
  final image = await recorder.endRecording().toImage(640, 480);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native engine gives the same numbers as the reference', (t) async {
    final out = await const MethodChannel('pronexa/lens').invokeMapMethod<String, Object?>('recognise', {'image': _fixedInput()});
    final scores = out!['scores'] as Float32List;
    final features = out['features'] as Float32List;
    expect(scores.length, lensLabels.length);
    for (var i = 0; i < scores.length; i++) {
      expect(scores[i], closeTo(_expectedScores[i], 0.002), reason: 'score ${lensLabels[i].$1}');
    }
    for (var i = 0; i < _expectedFeatures.length; i++) {
      expect(features[i], closeTo(_expectedFeatures[i], 0.002), reason: 'feature $i');
    }
  });

  testWidgets('a photo goes through the whole pipeline and can be learned', (t) async {
    final lens = OnDeviceLens();
    expect(await lens.isAvailable(), isTrue, reason: 'the model must be bundled');
    await lens.prepare();
    final result = await lens.recognise(await _photo());
    final f = result.features;
    expect(f, isNotNull);
    expect(f!.length, lensFeatures);
    expect(math.sqrt(f.fold<double>(0, (s, v) => s + v * v)), closeTo(1, 0.001));

    final memory = PhotoMemory()..learn(['chips'], f, '2026-11-20');
    expect(memory.recall(f).single.foodId, 'chips');
  });
}

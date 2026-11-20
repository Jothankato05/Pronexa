import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter/services.dart';

import '../data/foods.dart';

/// On-phone food recogniser for Photo mode.
///
/// The model ("Nigerian Food Lens", Apache-2.0, converted by
/// tool/food_model/convert.py) ships inside the app and runs offline. It only suggests foods: the student picks
/// and confirms, and protein still comes only from the food database.

/// One suggestion: a database food and how sure the model is (0..1).
class LensGuess {
  const LensGuess(this.foodId, this.score);

  final String foodId;
  final double score;
}

abstract class FoodLens {
  /// Whether this build includes the recogniser.
  Future<bool> isAvailable();

  Future<List<LensGuess>> recognise(Uint8List photo);
}

/// The model's 41 labels, in output order, and the database foods each one
/// means. Labels with no protein (ogi, onion, tomato) or no database food
/// (shrimp) map to nothing.
const lensLabels = <(String, List<String>)>[
  ('Akara', ['akara']),
  ('Akara And Bread', ['akara', 'bread']),
  ('Amala', ['amala']),
  ('Banga soup', ['banga']),
  ('Beans', ['beans']),
  ('Beef', ['beef']),
  ('Bitterleaf soup', ['bitterleaf']),
  ('Bread', ['bread']),
  ('Chicken', ['chicken']),
  ('Cow foot', ['assorted']),
  ('Cow skin', ['ponmo']),
  ('Eba', ['eba']),
  ('Edikaikong', ['efo_riro']),
  ('Efo Riro', ['efo_riro']),
  ('Egg', ['egg']),
  ('Egusi soup', ['egusi']),
  ('Ewedu', ['ewedu']),
  ('Fish', ['fish']),
  ('Fufu', ['fufu']),
  ('Garri and Groundnut', ['garri_soaked', 'groundnuts']),
  ('Gbegiri', ['gbegiri']),
  ('Iyan', ['pounded_yam']),
  ('Jollof rice', ['jollof_rice']),
  ('Moi Moi', ['moi_moi']),
  ('Nkwobi', ['assorted']),
  ('Ofe Oha', ['bitterleaf']),
  ('Ofe Owerri', ['efo_riro']),
  ('Ogbono soup', ['ogbono']),
  ('Ogi', []),
  ('Ogi and Akara', ['akara']),
  ('Okra soup', ['okra']),
  ('Onion', []),
  ('Plantain', ['plantain']),
  ('Rice', ['white_rice']),
  ('Shrimp', []),
  ('Snail', ['snail']),
  ('Spaghetti', ['spaghetti']),
  ('Stew', ['stew']),
  ('Stockfish', ['dry_fish']),
  ('Tomato', []),
  ('Tripe', ['assorted']),
];

/// Turns model scores into at most [max] database foods scoring at least
/// [threshold], best first. The model card suggests 0.3 for automatic use;
/// Pronexa only shows suggestions the student taps, so it uses 0.2 to miss
/// fewer foods (a wrong suggestion costs nothing).
List<LensGuess> guessesFromScores(List<double> scores, {double threshold = 0.2, int max = 4}) {
  final best = <String, double>{};
  for (var i = 0; i < scores.length && i < lensLabels.length; i++) {
    if (scores[i] < threshold) continue;
    for (final id in lensLabels[i].$2) {
      if (foodById.containsKey(id) && scores[i] > (best[id] ?? 0)) best[id] = scores[i];
    }
  }
  final list = best.entries.map((e) => LensGuess(e.key, e.value)).toList()..sort((a, b) => b.score.compareTo(a.score));
  return list.take(max).toList();
}

/// Bundled with the app (built by tool/food_model/convert.py), so Photo mode
/// recognises foods offline from the first launch.
const lensAsset = 'assets/models/pronexa-food-v1.onnx';
const lensSize = 384;

/// Runs the bundled model with ONNX Runtime on the phone.
class OnDeviceLens implements FoodLens {
  OrtSession? _session;
  bool? _available;

  @override
  Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return _available = manifest.listAssets().contains(lensAsset);
    } on Exception {
      return _available = false;
    }
  }

  @override
  Future<List<LensGuess>> recognise(Uint8List photo) async {
    final session = _session ??= await OnnxRuntime().createSessionFromAsset(lensAsset);
    final input = await OrtValue.fromList(await lensInput(photo), [1, lensSize, lensSize, 3]);
    try {
      final out = await session.run({'image': input});
      final scores = (await out['scores']!.asFlattenedList()).map((v) => (v as num).toDouble()).toList();
      for (final v in out.values) {
        await v.dispose();
      }
      return guessesFromScores(scores);
    } finally {
      await input.dispose();
    }
  }
}

/// The model's input: the photo's centre square, scaled to 384×384, as RGB
/// floats in 0..1, row by row (NHWC). Uses the engine's own decoder.
Future<Float32List> lensInput(Uint8List photo) async {
  final codec = await ui.instantiateImageCodec(photo);
  final image = (await codec.getNextFrame()).image;
  final side = math.min(image.width, image.height).toDouble();
  final src = ui.Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2, side, side);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
      .drawImageRect(image, src, ui.Rect.fromLTWH(0, 0, lensSize.toDouble(), lensSize.toDouble()), ui.Paint()..filterQuality = ui.FilterQuality.medium);
  final scaled = await recorder.endRecording().toImage(lensSize, lensSize);
  final rgba = (await scaled.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  image.dispose();
  scaled.dispose();
  final out = Float32List(lensSize * lensSize * 3);
  for (var p = 0, o = 0; p < rgba.length; p += 4, o += 3) {
    out[o] = rgba[p] / 255;
    out[o + 1] = rgba[p + 1] / 255;
    out[o + 2] = rgba[p + 2] / 255;
  }
  return out;
}

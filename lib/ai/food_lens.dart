import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../data/foods.dart';

/// On-phone food recogniser for Photo mode.
///
/// The model ("Nigerian Food Lens", Apache-2.0, converted by
/// tool/food_model/convert.py) ships inside the app and runs offline with
/// ONNX Runtime (android/app/src/main/java/ng/pronexa/app/LensEngine.java). It only suggests foods: the student picks
/// and confirms, and protein still comes only from the food database.

/// One suggestion: a database food and how sure it is (0..1). [learned]
/// suggestions come from the student's own confirmed photos (PhotoMemory).
class LensGuess {
  const LensGuess(this.foodId, this.score, {this.learned = false});

  final String foodId;
  final double score;
  final bool learned;
}

/// What the recogniser saw: its own suggestions, and the photo's fingerprint
/// (1280 numbers, unit length) for the on-phone photo memory.
class LensResult {
  const LensResult(this.guesses, [this.features]);

  final List<LensGuess> guesses;
  final Float32List? features;

  static const empty = LensResult([]);
}

abstract class FoodLens {
  /// Whether this build includes the recogniser.
  Future<bool> isAvailable();

  /// Starts loading the model in the background, ahead of the first photo.
  Future<void> prepare();

  Future<LensResult> recognise(Uint8List photo);
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

/// A small classifier trained on the recogniser's photo fingerprints
/// (tool/food_model/train_head.py), for 18 Nigerian dishes. It sharpens the
/// first guess and knows dishes the recogniser never learned (suya, puff-puff,
/// chin chin, pepper soup, yam porridge, ofada rice). One softmax layer:
/// probabilities = softmax(scale × weights · fingerprint + bias).
class DishHead {
  DishHead({required this.scale, required this.minScore, required this.foods, required this.bias, required this.weights})
    : assert(weights.length == bias.length * lensFeatures);

  factory DishHead.fromJson(Map<String, Object?> j) {
    final dishes = (j['dishes']! as List).cast<Map<String, Object?>>();
    final rows = (j['weights']! as List).cast<List<Object?>>();
    return DishHead(
      scale: (j['scale']! as num).toDouble(),
      minScore: (j['minScore']! as num).toDouble(),
      foods: [for (final d in dishes) (d['foods']! as List).cast<String>()],
      bias: Float64List.fromList([for (final v in j['bias']! as List) (v as num).toDouble()]),
      weights: Float32List.fromList([
        for (final r in rows)
          for (final v in r) (v as num).toDouble(),
      ]),
    );
  }

  final double scale;

  /// Dishes below this probability are left to the recogniser.
  final double minScore;
  final List<List<String>> foods;
  final Float64List bias;
  final Float32List weights;

  List<double> probabilities(Float32List f) {
    final z = List<double>.generate(bias.length, (k) {
      var s = 0.0;
      for (var i = 0, o = k * lensFeatures; i < lensFeatures; i++) {
        s += weights[o + i] * f[i];
      }
      return scale * s + bias[k];
    });
    final top = z.reduce(math.max);
    final e = [for (final v in z) math.exp(v - top)];
    final sum = e.fold(0.0, (a, b) => a + b);
    return [for (final v in e) v / sum];
  }

  /// The head's dishes scoring at least [minScore] and the recogniser's own
  /// foods, ranked together by each one's confidence, at most [max]. The head
  /// only knows 18 dishes and always picks one of them, so a photo of egg,
  /// chicken or spaghetti still gets a dish; ranking by confidence keeps a
  /// food the recogniser is sure of first. Same rule as merged() in
  /// train_head.py, which measured it (docs/PHOTO.md).
  List<LensGuess> merge(Float32List f, List<LensGuess> lens, {int max = 4}) {
    final p = probabilities(f);
    final best = <String, LensGuess>{};
    void offer(LensGuess g) {
      if (!foodById.containsKey(g.foodId)) return;
      final had = best[g.foodId];
      if (had == null || g.score > had.score) best[g.foodId] = g;
    }

    for (var k = 0; k < p.length; k++) {
      if (p[k] < minScore) continue;
      for (final id in foods[k]) {
        offer(LensGuess(id, p[k]));
      }
    }
    lens.forEach(offer);
    final list = best.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    return list.take(max).toList();
  }
}

const dishHeadAsset = 'assets/models/pronexa-food-head.json';

/// Bundled with the app (built by tool/food_model/convert.py), so Photo mode
/// recognises foods offline from the first launch.
const lensAsset = 'assets/models/pronexa-food-v1.onnx';
const lensSize = 384;
const lensFeatures = 1280;

/// Runs the bundled model with ONNX Runtime on the phone, through
/// MainActivity's "pronexa/lens" channel. The native side does the work on a
/// background thread (loading and running the model take seconds; doing that
/// on Android's main thread gets the app killed as not responding).
class OnDeviceLens implements FoodLens {
  static const _channel = MethodChannel('pronexa/lens');
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
  Future<void> prepare() async {
    try {
      await _channel.invokeMethod<void>('prepare');
    } on Exception {
      // Not on Android, or no engine: recognise() will report it.
    }
  }

  @override
  Future<LensResult> recognise(Uint8List photo) async {
    final input = await lensInput(photo);
    final out = await _channel.invokeMapMethod<String, Object?>('recognise', {'image': input});
    final scores = out?['scores'];
    final features = out?['features'];
    if (scores is! Float32List || scores.length != lensLabels.length) return LensResult.empty;
    final f = features is Float32List && features.length == lensFeatures ? features : null;
    final guesses = guessesFromScores([for (final v in scores) v.toDouble()]);
    final head = f == null ? null : await _dishHead();
    return LensResult(head == null ? guesses : head.merge(f!, guesses), f);
  }

  DishHead? _head;
  bool _headLoaded = false;

  Future<DishHead?> _dishHead() async {
    if (_headLoaded) return _head;
    _headLoaded = true;
    try {
      _head = DishHead.fromJson(jsonDecode(await rootBundle.loadString(dishHeadAsset)) as Map<String, Object?>);
    } catch (_) {
      _head = null; // Missing or unreadable: the recogniser's own guesses are used.
    }
    return _head;
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

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../data/foods.dart';
import 'food_lens.dart';

/// On-phone photo memory: how Pronexa learns new foods without retraining.
///
/// When a student confirms a meal logged from a photo, the photo's fingerprint
/// (the recogniser's 1280 image features) is kept on the phone with the foods
/// they confirmed. A later photo that looks close enough to a remembered one
/// gets that meal's foods as suggestions, including foods the recogniser was
/// never trained on (chips, suya, shawarma) and the student's usual plates.
///
/// Fingerprints are stored as 8-bit numbers (1.3 KB each), never the photo, and
/// cannot be turned back into it. Nothing leaves the phone. Profile can clear it.
///
/// Measured on public photos of 6 dishes the recogniser does not know: after 3
/// confirmed photos of a dish, the nearest-match suggestion was right 69% of the
/// time; after 5, 75%. See docs/PHOTO.md.
class PhotoMemory {
  PhotoMemory([List<MemoryExample>? examples]) : examples = examples ?? [];

  /// Cosine similarity a photo must reach to recall a remembered meal.
  static const threshold = 0.65;

  /// Closer than this to a remembered photo with the same foods: not stored again.
  static const duplicate = 0.97;

  /// The oldest are forgotten first. 200 × 1.3 KB ≈ 260 KB.
  static const maxExamples = 200;

  final List<MemoryExample> examples;

  int get length => examples.length;

  /// The remembered meal most like this photo, if close enough: its foods,
  /// scored by the similarity.
  List<LensGuess> recall(Float32List features) {
    final best = _nearest(features);
    if (best == null || best.$2 < threshold) return const [];
    return [for (final id in best.$1.foods) LensGuess(id, best.$2, learned: true)];
  }

  /// Remembers a confirmed photo. Returns false when nothing new was learned.
  bool learn(List<String> foods, Float32List features, String date) {
    final ids = [
      for (final id in foods.toSet())
        if (foodById.containsKey(id)) id,
    ]..sort();
    if (ids.isEmpty || features.length != lensFeatures) return false;
    final near = _nearest(features);
    if (near != null && near.$2 >= duplicate && _sameFoods(near.$1.foods, ids)) return false;
    examples.add(MemoryExample.fromFeatures(ids, features, date));
    if (examples.length > maxExamples) examples.removeRange(0, examples.length - maxExamples);
    return true;
  }

  /// Distinct foods learned, for the Profile row.
  int get foodsKnown => examples.expand((e) => e.foods).toSet().length;

  (MemoryExample, double)? _nearest(Float32List q) {
    (MemoryExample, double)? best;
    for (final e in examples) {
      final s = e.similarity(q);
      if (best == null || s > best.$2) best = (e, s);
    }
    return best;
  }

  static bool _sameFoods(List<String> a, List<String> b) => a.length == b.length && a.every(b.contains);

  List<Object?> toJson() => [for (final e in examples) e.toJson()];

  static PhotoMemory fromJson(Object? json) {
    if (json is! List) return PhotoMemory();
    return PhotoMemory([for (final j in json) ?MemoryExample.fromJson(j)]);
  }
}

class MemoryExample {
  MemoryExample(this.foods, this.vector, this.date) : _norm = _length(vector);

  factory MemoryExample.fromFeatures(List<String> foods, Float32List f, String date) {
    var peak = 0.0;
    for (final v in f) {
      peak = math.max(peak, v.abs());
    }
    final scale = peak == 0 ? 0.0 : 127 / peak;
    return MemoryExample(foods, Int8List.fromList([for (final v in f) (v * scale).round().clamp(-127, 127)]), date);
  }

  /// Food ids confirmed for this photo, sorted.
  final List<String> foods;

  /// The fingerprint, scaled so its largest value is 127 and rounded to 8
  /// bits. Cosine similarity ignores the scale, so it need not be stored;
  /// rounding changes similarities by about 0.002.
  final Int8List vector;
  final String date;
  final double _norm;

  static double _length(Int8List v) {
    var s = 0;
    for (final x in v) {
      s += x * x;
    }
    return math.sqrt(s.toDouble());
  }

  /// Cosine similarity with a fingerprint (which has unit length).
  double similarity(Float32List q) {
    if (q.length != vector.length || _norm == 0) return 0;
    var dot = 0.0;
    for (var i = 0; i < q.length; i++) {
      dot += q[i] * vector[i];
    }
    return dot / _norm;
  }

  Map<String, Object?> toJson() => {'foods': foods, 'v': base64Encode(Uint8List.view(vector.buffer)), 'date': date};

  static MemoryExample? fromJson(Object? json) {
    if (json is! Map) return null;
    final foods = json['foods'];
    final v = json['v'];
    if (foods is! List || v is! String) return null;
    try {
      final bytes = base64Decode(v);
      if (bytes.length != lensFeatures) return null;
      final ids = [
        for (final f in foods)
          if (f is String && foodById.containsKey(f)) f,
      ];
      if (ids.isEmpty) return null;
      return MemoryExample(ids, Int8List.view(bytes.buffer, bytes.offsetInBytes, bytes.length), json['date'] is String ? json['date'] as String : '');
    } on FormatException {
      return null;
    }
  }
}

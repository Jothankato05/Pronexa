import 'dart:typed_data';

import '../ai/types.dart';
import '../ai/validator.dart';
import '../data/foods.dart';
import '../data/models.dart';

/// A meal being checked on the Confirm screen. Nothing is counted until it is saved.
class Draft {
  Draft({
    required this.source,
    required this.items,
    this.text,
    this.price,
    this.confidence,
    this.question,
    this.notes = const [],
    this.unknown = const [],
    this.editingId,
    this.photo,
    this.photoFeatures,
  });

  factory Draft.fromReading(Reading r, {required LogSource source, String? text, Uint8List? photo}) => Draft(
    source: source,
    items: r.items,
    text: text,
    price: r.price,
    confidence: r.confidence,
    question: r.question,
    notes: r.notes,
    unknown: r.unknown,
    photo: photo,
  );

  factory Draft.fromFoods(Iterable<String> foodIds, {required LogSource source, Uint8List? photo, Float32List? photoFeatures}) => Draft(
    source: source,
    photo: photo,
    photoFeatures: photoFeatures,
    items: [
      for (final id in foodIds)
        DraftItem(
          key: newKey(),
          item: MealItem(foodId: id, portionId: foodById[id]!.defaultPortion, qty: foodById[id]!.defaultQty),
          source: PortionSource.defaulted,
        ),
    ],
  );

  factory Draft.fromMeal(Meal m) => Draft(
    source: m.source,
    text: m.text,
    price: m.price,
    editingId: m.id,
    items: [for (final i in m.items) DraftItem(key: newKey(), item: i)],
  );

  final LogSource source;
  List<DraftItem> items;
  final String? text;
  final int? price;
  Confidence? confidence;
  Question? question;
  final List<String> notes;
  List<String> unknown;
  final String? editingId;

  /// Kept in memory only, never saved.
  final Uint8List? photo;

  /// The photo's fingerprint from the on-phone recogniser. When the meal is
  /// added, the phone remembers it with the confirmed foods (PhotoMemory).
  final Float32List? photoFeatures;
}

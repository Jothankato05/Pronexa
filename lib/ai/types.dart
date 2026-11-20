import '../data/models.dart';

/// Where a portion came from.
enum PortionSource { stated, sizeDefault, price, defaulted }

/// What any reader (the offline rules, or a remote AI) must return.
/// Readers only pick foods from the database. They never return protein numbers.
class RawItem {
  const RawItem({required this.foodId, this.portionKey, this.qty, this.eaten, this.source = PortionSource.stated, this.matched, this.generic = false});

  final String foodId;
  final String? portionKey;
  final double? qty;
  final double? eaten;
  final PortionSource source;
  final String? matched;
  final bool generic;

  static RawItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['foodId'];
    if (id is! String || id.length > 40) return null;
    double? n(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    final src = switch (json['portionSource']) {
      'size-default' => PortionSource.sizeDefault,
      'default' => PortionSource.defaulted,
      'price' => PortionSource.price,
      _ => PortionSource.stated,
    };
    final portion = json['portionId'];
    final matched = json['matched'];
    return RawItem(
      foodId: id,
      portionKey: portion is String ? portion : null,
      qty: n(json['qty']),
      eaten: n(json['eaten']),
      source: src,
      matched: matched is String && matched.length <= 60 ? matched : null,
      generic: json['generic'] == true,
    );
  }
}

class RawReading {
  const RawReading({required this.items, this.unknown = const [], this.skipped = const [], this.price});

  final List<RawItem> items;

  /// Food-like words that were not recognised.
  final List<String> unknown;

  /// Things mentioned with no protein (water, tea...).
  final List<String> skipped;

  /// Total naira mentioned. A clue only.
  final int? price;

  static RawReading fromJson(Object? json) {
    if (json is! Map) return const RawReading(items: []);
    List<String> strings(Object? v) => v is List ? v.whereType<String>().where((s) => s.length <= 60).take(10).toList() : const <String>[];
    final items = json['items'] is List ? (json['items'] as List).take(20).map(RawItem.fromJson).whereType<RawItem>().toList() : <RawItem>[];
    final price = json['price'];
    return RawReading(
      items: items,
      unknown: strings(json['unknown']),
      skipped: strings(json['skipped']),
      price: price is num && price > 0 && price < 1000000 ? price.round() : null,
    );
  }
}

enum Confidence { high, medium, low }

/// An item on the confirm screen.
class DraftItem {
  const DraftItem({required this.key, required this.item, this.source = PortionSource.stated, this.generic = false, this.matched});

  final String key;
  final MealItem item;
  final PortionSource source;
  final bool generic;
  final String? matched;

  bool get isGuess => source != PortionSource.stated;

  DraftItem copyWith({MealItem? item, PortionSource? source, bool? generic}) =>
      DraftItem(key: key, item: item ?? this.item, source: source ?? this.source, generic: generic ?? this.generic, matched: matched);
}

sealed class QuestionAction {
  const QuestionAction();
}

class SetPortion extends QuestionAction {
  const SetPortion(this.key, this.portion);
  final String key;
  final PortionId portion;
}

class SetFood extends QuestionAction {
  const SetFood(this.key, this.foodId);
  final String key;
  final String foodId;
}

class AddFood extends QuestionAction {
  const AddFood(this.foodId);
  final String foodId;
}

class Dismiss extends QuestionAction {
  const Dismiss();
}

class QuestionOption {
  const QuestionOption(this.label, this.action, {this.selected = false});
  final String label;
  final QuestionAction action;
  final bool selected;
}

class Question {
  const Question(this.id, this.text, this.options);
  final String id;
  final String text;
  final List<QuestionOption> options;
}

class Reading {
  const Reading({required this.items, required this.confidence, required this.notes, required this.unknown, required this.rejected, this.question, this.price});

  final List<DraftItem> items;
  final Confidence confidence;
  final Question? question;
  final List<String> notes;
  final List<String> unknown;
  final List<String> rejected;
  final int? price;
}

import '../data/foods.dart';
import '../data/models.dart';
import '../data/portions.dart';

/// The calculation engine. Plain, explainable arithmetic:
///   protein = proteinPer100g × portion grams × qty × fraction eaten ÷ 100
/// with an uncertainty band from the kind of portion. No AI touches these numbers.

Range itemProtein(MealItem item) {
  final food = foodById[item.foodId];
  if (food == null) return Range.zero;
  final portion = food.portion(item.portionId);
  final u = portionMeta[portion.id]?.uncertainty ?? 0.25;
  final mid = food.proteinPer100g * portion.grams * item.qty * item.eaten / 100;
  return Range(mid * (1 - u), mid * (1 + u));
}

Range itemsProtein(Iterable<MealItem> items) => items.fold(Range.zero, (acc, it) => acc + itemProtein(it));

/// Price for the whole item (all of it, regardless of how much was eaten).
Price? itemPrice(MealItem item) {
  final price = foodById[item.foodId]?.portion(item.portionId).price;
  return price == null ? null : price * item.qty;
}

class ActivityInfo {
  const ActivityInfo(this.label, this.detail, this.low, this.high);

  final String label;
  final String detail;
  final double low;
  final double high;
}

const activityInfo = {
  Activity.light: ActivityInfo('Mostly sitting', 'Lectures, reading, little walking', 0.8, 0.9),
  Activity.moderate: ActivityInfo('On my feet a lot', 'Walking around campus most days', 0.9, 1.1),
  Activity.active: ActivityInfo('Active', 'Exercise or sport 3+ times a week', 1.1, 1.4),
  Activity.athlete: ActivityInfo('Training hard', 'Team sport, gym or heavy work', 1.4, 1.7),
};

const defaultWeightKg = 60;

Range proteinTarget(Profile profile) {
  final kg = profile.weightKg ?? defaultWeightKg;
  final a = activityInfo[profile.activity]!;
  return Range((kg * a.low).roundToDouble(), (kg * a.high).roundToDouble());
}

/// What is left to eat. Never negative.
Range proteinGap(Range target, Range eaten) {
  final lo = (target.mid - eaten.max).clamp(0, double.infinity).toDouble();
  final hi = (target.mid - eaten.min).clamp(0, double.infinity).toDouble();
  return Range(lo, hi);
}

// ── Formatting ─────────────────────────────────────────────

String fmtRange(Range r, {String unit = 'g'}) {
  final lo = r.min.round();
  final hi = r.max.round();
  if (hi <= 0) return '0 $unit';
  if (hi - lo <= 1) return '${r.mid.round()} $unit';
  return '$lo–$hi $unit';
}

String fmtNaira(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '₦$buf';
}

String fmtPrice(Price p) => p.min == p.max ? fmtNaira(p.min) : '${fmtNaira(p.min)}–${fmtNaira(p.max).substring(1)}';

String fmtQty(double qty) {
  final whole = qty.floor();
  final quarters = (qty - whole) * 4;
  final f = (quarters - quarters.round()).abs() < 0.01
      ? switch (quarters.round()) {
          1 => '¼',
          2 => '½',
          3 => '¾',
          _ => null,
        }
      : null;
  if (f == null) return qty == qty.roundToDouble() ? qty.round().toString() : qty.toStringAsFixed(2);
  return whole > 0 ? '$whole$f' : f;
}

const _nounPlurals = {
  'piece': 'pieces',
  'slice': 'slices',
  'wrap': 'wraps',
  'sachet': 'sachets',
  'spoon': 'spoons',
  'tin': 'tins',
  'bottle': 'bottles',
  'pack': 'packs',
  'egg': 'eggs',
  'handful': 'handfuls',
  'cup': 'cups',
  'serving': 'servings',
  'ball': 'balls',
};

/// Pluralise the head noun only: "serving spoon of stew" → "serving spoons of stew".
String pluralise(String label) {
  final cut = RegExp(r' \(| /| of ').firstMatch(label)?.start ?? -1;
  final head = cut == -1 ? label : label.substring(0, cut);
  final rest = cut == -1 ? '' : label.substring(cut);
  final words = head.split(' ');
  for (var i = words.length - 1; i >= 0; i--) {
    final plural = _nounPlurals[words[i]];
    if (plural != null) {
      words[i] = plural;
      return words.join(' ') + rest;
    }
  }
  return label;
}

String portionLabel(String foodId, PortionId portionId, double qty) {
  final food = foodById[foodId];
  final meta = portionMeta[portionId]!;
  final custom = food?.portion(portionId).label;
  final noun = custom != null ? (qty > 1 ? pluralise(custom) : custom) : (qty > 1 ? meta.many : meta.one);
  return '${fmtQty(qty)} $noun';
}

String eatenLabel(double eaten) => switch (eaten) {
  1 => 'Ate all',
  0.75 => '¾ eaten',
  0.5 => 'Half eaten',
  0.25 => '¼ eaten',
  _ => 'Ate all',
};

/// "rice, beans and stew"
String describeItems(Iterable<MealItem> items) {
  const tidy = {'white rice': 'rice', 'tomato stew': 'stew', 'boiled yam': 'yam', 'fried plantain': 'dodo'};
  final names = items.map((i) => foodById[i.foodId]?.name.toLowerCase()).whereType<String>().map((n) => tidy[n] ?? n).toList();
  if (names.isEmpty) return 'meal';
  if (names.length == 1) return names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

String capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

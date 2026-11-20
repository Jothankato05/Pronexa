import '../data/foods.dart';
import '../data/models.dart';
import '../data/portions.dart';
import '../logic/calc.dart';
import 'rule_reader.dart';
import 'types.dart';

/// The guard rail between "AI reads" and "the database counts". Whatever a reader
/// returns, only foods and portions in the checked database survive. Price only
/// suggests which portion to confirm.

const _eatenSteps = [1.0, 0.75, 0.5, 0.25];
const _sizePortions = [PortionId.smPack, PortionId.mdPack, PortionId.lgPack, PortionId.plate, PortionId.spoon, PortionId.bowl];
const _packs = [PortionId.smPack, PortionId.mdPack, PortionId.lgPack];
var _seq = 0;

String newKey() => 'k${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

double _snapEaten(double? v) {
  final n = v ?? 1;
  return _eatenSteps.reduce((best, s) => (s - n).abs() < (best - n).abs() ? s : best);
}

double _clampQty(double? v, double fallback) => ((v ?? fallback) * 4).round().clamp(1, 80) / 4;

PortionId? _sizeFromPrice(Food food, double money) {
  final sized = food.portions.where((p) => p.price != null && [..._packs, PortionId.plate].contains(p.id)).toList();
  if (sized.isEmpty) return null;
  for (final p in sized) {
    if (money >= p.price!.min && money <= p.price!.max) return p.id;
  }
  sized.sort((a, b) => (a.price!.mid - money).abs().compareTo((b.price!.mid - money).abs()));
  return sized.first.id;
}

Reading validate(RawReading raw) {
  final notes = <String>[];
  final rejected = <String>[];
  var items = <DraftItem>[];

  for (final r in raw.items) {
    final food = foodById[r.foodId];
    if (food == null) {
      rejected.add(r.foodId);
      continue;
    }
    final portion = PortionId.fromKey(r.portionKey);
    final valid = portion != null && food.hasPortion(portion);
    items.add(
      DraftItem(
        key: newKey(),
        item: MealItem(foodId: food.id, portionId: valid ? portion : food.defaultPortion, qty: _clampQty(r.qty, food.defaultQty), eaten: _snapEaten(r.eaten)),
        source: valid ? r.source : PortionSource.defaulted,
        generic: r.generic,
        matched: r.matched,
      ),
    );
  }

  final price = raw.price;
  var priceMismatch = false;
  if (price != null) {
    // Soups and stews usually come with the main food, so leave them out.
    final priced = items.where((i) => foodById[i.item.foodId]!.group != FoodGroup.soup).toList();
    final uncertain = priced
        .where(
          (i) =>
              i.source != PortionSource.stated &&
              _sizePortions.contains(i.item.portionId) &&
              foodById[i.item.foodId]!.portions.any((p) => _packs.contains(p.id)),
        )
        .toList();
    if (uncertain.length == 1) {
      final target = uncertain.single;
      final others = priced.where((i) => i != target).fold<double>(0, (sum, i) => sum + (itemPrice(i.item)?.mid ?? 0));
      final money = (price - others) > price * 0.4 ? price - others : price * 0.4;
      final food = foodById[target.item.foodId]!;
      final size = _sizeFromPrice(food, money);
      if (size != null) {
        items = items
            .map(
              (i) => i == target
                  ? i.copyWith(
                      item: i.item.copyWith(portionId: size, qty: 1),
                      source: PortionSource.price,
                    )
                  : i,
            )
            .toList();
        notes.add('${fmtNaira(price)} usually buys a ${portionMeta[size]!.one} of ${food.name.toLowerCase()} ($pricesAsOf prices). Check the size.');
      }
    } else if (priced.isNotEmpty) {
      var lo = 0, hi = 0;
      for (final i in priced) {
        final p = itemPrice(i.item);
        if (p != null) {
          lo += p.min;
          hi += p.max;
        }
      }
      if (hi > 0) {
        if (price > hi * 1.4 || price < lo * 0.6) {
          priceMismatch = true;
          notes.add('${fmtNaira(price)} is ${price > hi ? 'more' : 'less'} than this usually costs (${fmtPrice(Price(lo, hi))}). Check the portions.');
        } else {
          notes.add('${fmtNaira(price)} matches these portions at $pricesAsOf prices.');
        }
      }
    }
  }

  if (raw.skipped.isNotEmpty) notes.add('Not counted (no protein): ${raw.skipped.join(', ')}.');
  if (items.any((i) => i.matched == 'meat' && i.item.foodId == 'beef')) notes.add('"Meat" counted as one buka piece of beef.');

  final unknown = raw.unknown.where((u) => u.length >= 3).toList();
  var score = items.isEmpty ? 0.0 : 1.0;
  score -= unknown.length * 0.3;
  for (final i in items) {
    final soup = foodById[i.item.foodId]!.group == FoodGroup.soup;
    score -= switch (i.source) {
      PortionSource.price => 0.15,
      PortionSource.sizeDefault => 0.2,
      PortionSource.defaulted => soup ? 0.05 : (_sizePortions.contains(i.item.portionId) ? 0.3 : 0.1),
      PortionSource.stated => 0,
    };
    if (i.generic) score -= 0.1;
  }
  if (priceMismatch) score -= 0.2;
  if (rejected.isNotEmpty) score -= 0.2;
  final confidence = score >= 0.8
      ? Confidence.high
      : score >= 0.5
      ? Confidence.medium
      : Confidence.low;

  return Reading(
    items: items,
    confidence: confidence,
    question: pickQuestion(items, unknown),
    notes: notes,
    unknown: unknown,
    rejected: rejected,
    price: price,
  );
}

/// One simple question, only when it matters.
Question? pickQuestion(List<DraftItem> items, List<String> unknown) {
  if (items.isEmpty) return null;

  if (unknown.isNotEmpty) {
    final word = unknown.first;
    if (word == 'soup' || word.endsWith(' soup')) {
      return Question('unknown-$word', 'Which soup?', [
        for (final id in ['egusi', 'efo_riro', 'okra', 'ewedu']) QuestionOption(foodById[id]!.name, AddFood(id)),
        const QuestionOption('Skip', Dismiss()),
      ]);
    }
    final close = closestFoods(word.split(' ').first);
    return Question('unknown-$word', close.isEmpty ? '"$word" is not in the food list yet.' : 'What is "$word"?', [
      for (final f in close) QuestionOption(f.name, AddFood(f.id)),
      const QuestionOption('Skip', Dismiss()),
    ]);
  }

  final guessed = items
      .where((i) => i.source != PortionSource.stated && _sizePortions.contains(i.item.portionId) && foodById[i.item.foodId]!.group != FoodGroup.soup)
      .firstOrNull;
  if (guessed != null) {
    final food = foodById[guessed.item.foodId]!;
    final options = food.portions.where((p) => _sizePortions.contains(p.id)).take(4);
    return Question('size-${guessed.key}', 'How big was the ${food.name.toLowerCase()}?', [
      for (final p in options) QuestionOption(capitalise(portionMeta[p.id]!.one), SetPortion(guessed.key, p.id), selected: p.id == guessed.item.portionId),
    ]);
  }

  final generic = items.where((i) => i.generic && i.item.foodId == 'white_rice').firstOrNull;
  if (generic != null) {
    return Question('generic-${generic.key}', 'Which rice?', [
      for (final id in ['white_rice', 'jollof_rice', 'fried_rice'])
        QuestionOption(foodById[id]!.name, SetFood(generic.key, id), selected: id == generic.item.foodId),
    ]);
  }
  return null;
}

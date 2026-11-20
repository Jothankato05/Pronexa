import '../data/foods.dart';
import '../data/models.dart';
import 'calc.dart';
import 'diet.dart';

/// Protein Gap Solver. Deterministic, so it works offline:
///   score = 0.65 × value (protein per ₦, normalised) + 0.25 × share of the gap closed + 0.10 plant bonus
/// Plant-first puts every plant option above animal options.

class Suggestion {
  Suggestion({
    required this.food,
    required this.item,
    required this.protein,
    required this.price,
    required this.per100,
    required this.ready,
    required this.gapShare,
    this.caveat,
  });

  final Food food;
  final MealItem item;
  final Range protein;
  final Price price;

  /// Grams of protein per ₦100 (mid estimates).
  final double per100;
  final bool ready;
  final double gapShare;
  final String? caveat;
  double score = 0;

  bool get plant => food.isPlant;
}

class Combo {
  const Combo({required this.title, required this.items, required this.protein, required this.cost, required this.closesGap});

  final String title;
  final List<Suggestion> items;
  final Range protein;
  final double cost;
  final bool closesGap;
}

class Upgrade {
  const Upgrade({required this.title, required this.suggestion, required this.proteinChange, required this.costChange, required this.reason, this.swapFrom});

  final String title;
  final Suggestion suggestion;
  final Food? swapFrom;
  final Range proteinChange;
  final double costChange;
  final String reason;
}

class SolverResult {
  const SolverResult({required this.ranked, required this.combos, required this.upgrades, required this.hiddenCount});

  final List<Suggestion> ranked;
  final List<Combo> combos;
  final List<Upgrade> upgrades;
  final int hiddenCount;
}

/// A unit a student would actually buy or cook.
const _unit = <String, (PortionId, double)>{
  'soybeans': (PortionId.spoon, 1),
  'soya_chunks': (PortionId.handful, 1),
  'groundnuts': (PortionId.sachet, 1),
  'beans': (PortionId.spoon, 2),
  'akara': (PortionId.ball, 4),
  'tofu': (PortionId.piece, 3),
  'moi_moi': (PortionId.wrap, 1),
  'okpa': (PortionId.wrap, 1),
  'lentils': (PortionId.spoon, 2),
  'soy_milk': (PortionId.bottle, 1),
  'egg': (PortionId.piece, 2),
  'beef': (PortionId.piece, 2),
  'fish': (PortionId.piece, 1),
  'chicken': (PortionId.piece, 1),
  'sardine': (PortionId.tin, 1),
  'milk': (PortionId.sachet, 1),
};

/// Bought ready to eat from a vendor.
const _ready = {'moi_moi', 'akara', 'okpa', 'groundnuts', 'soy_milk', 'tofu', 'egg', 'beans', 'chicken', 'beef', 'fish', 'sardine', 'milk'};

/// Pairings people already eat.
const _pairings = <String, List<String>>{
  'white_rice': ['beans', 'moi_moi', 'soya_chunks', 'tofu', 'egg', 'fish', 'beef'],
  'jollof_rice': ['moi_moi', 'beans', 'soya_chunks', 'egg', 'fish', 'beef'],
  'fried_rice': ['moi_moi', 'soya_chunks', 'egg', 'beef'],
  'yam': ['akara', 'beans', 'groundnuts', 'egg', 'fish'],
  'plantain': ['beans', 'akara', 'egg'],
  'bread': ['akara', 'groundnuts', 'soy_milk', 'egg', 'sardine'],
  'garri_soaked': ['groundnuts', 'soy_milk', 'milk'],
  'noodles': ['soya_chunks', 'egg', 'tofu'],
  'spaghetti': ['soya_chunks', 'beans', 'egg', 'sardine'],
  'eba': ['tofu', 'soya_chunks', 'fish', 'beef'],
  'amala': ['tofu', 'beans', 'fish', 'beef'],
  'pounded_yam': ['tofu', 'soya_chunks', 'fish', 'beef'],
  'tuwo': ['beans', 'tofu', 'fish', 'beef'],
  'abacha': ['groundnuts', 'fish'],
};

const _pairLine = {
  'beans': 'Add a spoon or two of beans to the rice.',
  'moi_moi': 'Add a wrap of moi-moi on the side.',
  'soya_chunks': 'Stir soaked soya chunks into the stew.',
  'tofu': 'Ask for awara in the stew.',
  'akara': 'Add akara.',
  'groundnuts': 'Add a handful of groundnuts.',
  'soy_milk': 'Add a bottle of soy milk.',
  'milk': 'Add two spoons of milk.',
  'egg': 'Add one or two eggs.',
  'fish': 'Add a piece of fish to the soup.',
  'beef': 'Add a piece of meat to the soup.',
  'sardine': 'Add a tin of sardines.',
};

const _soupSwaps = {'okra': 'egusi', 'ewedu': 'egusi', 'efo_riro': 'egusi'};

Suggestion? makeSuggestion(Food food, Range gap, {String? caveat, (PortionId, double)? unit}) {
  final u = unit ?? _unit[food.id] ?? (food.defaultPortion, food.defaultQty);
  final item = MealItem(foodId: food.id, portionId: u.$1, qty: u.$2);
  final price = itemPrice(item);
  if (price == null) return null;
  final protein = itemProtein(item);
  return Suggestion(
    food: food,
    item: item,
    protein: protein,
    price: price,
    per100: protein.mid / price.mid * 100,
    ready: _ready.contains(food.id),
    gapShare: gap.mid > 0 ? (protein.mid / gap.mid).clamp(0, 1).toDouble() : 0,
    caveat: caveat,
  );
}

List<Suggestion> _rank(List<Suggestion> list, bool plantFirst) {
  if (list.isEmpty) return list;
  final maxPer = list.map((s) => s.per100).reduce((a, b) => a > b ? a : b);
  for (final s in list) {
    s.score = 0.65 * (s.per100 / maxPer) + 0.25 * s.gapShare + (s.plant ? 0.1 : 0);
  }
  return [...list]..sort((a, b) {
    if (plantFirst && a.plant != b.plant) return a.plant ? -1 : 1;
    return b.score.compareTo(a.score);
  });
}

Combo? _combo(String title, List<Suggestion> pool, Range gap, int budget) {
  if (gap.mid <= 0 || pool.isEmpty) return null;
  final chosen = <Suggestion>[];
  final counts = <String, int>{};
  var protein = Range.zero;
  var cost = 0.0;
  // Two passes: variety first, then a second unit of the best value.
  for (var pass = 0; pass < 2 && protein.mid < gap.mid; pass++) {
    for (final s in pool) {
      if (protein.mid >= gap.mid) break;
      final have = counts[s.food.id] ?? 0;
      if (have == 0 && counts.length >= 3) continue;
      if (have > pass) continue;
      if (cost + s.price.mid > budget) continue;
      chosen.add(s);
      counts[s.food.id] = have + 1;
      protein = protein + s.protein;
      cost += s.price.mid;
    }
  }
  if (chosen.isEmpty) return null;
  final merged = <String, Suggestion>{};
  for (final s in chosen) {
    final ex = merged[s.food.id];
    merged[s.food.id] = ex == null
        ? s
        : Suggestion(
            food: s.food,
            item: ex.item.copyWith(qty: ex.item.qty + s.item.qty),
            protein: ex.protein + s.protein,
            price: Price(ex.price.min + s.price.min, ex.price.max + s.price.max),
            per100: s.per100,
            ready: s.ready,
            gapShare: s.gapShare,
            caveat: s.caveat,
          );
  }
  return Combo(title: title, items: merged.values.toList(), protein: protein, cost: cost, closesGap: protein.mid >= gap.mid);
}

const _exampleMeals = <(String, List<MealItem>)>[
  ('Rice and stew', [MealItem(foodId: 'white_rice', portionId: PortionId.mdPack, qty: 1), MealItem(foodId: 'stew', portionId: PortionId.spoon, qty: 2)]),
  ('Yam and sauce', [MealItem(foodId: 'yam', portionId: PortionId.slice, qty: 2), MealItem(foodId: 'stew', portionId: PortionId.spoon, qty: 2)]),
  ('Eba and okra soup', [MealItem(foodId: 'eba', portionId: PortionId.wrap, qty: 1), MealItem(foodId: 'okra', portionId: PortionId.serving, qty: 1)]),
];

List<Upgrade> _upgrades(List<Meal> meals, Range gap, int budget, bool plantFirst, Map<String, String?> fits) {
  final sources = meals.isNotEmpty
      ? ([...meals]..sort((a, b) => b.time.compareTo(a.time))).map((m) => (capitalise(describeItems(m.items)), m.items))
      : _exampleMeals;
  final out = <Upgrade>[];
  final used = <String>{};
  for (final (title, items) in sources) {
    if (out.length >= 3) break;
    if (itemsProtein(items).mid >= 20) continue;
    final ids = items.map((i) => i.foodId).toList();

    final soup = ids.where(_soupSwaps.containsKey).firstOrNull;
    if (soup != null && fits.containsKey(_soupSwaps[soup])) {
      final to = foodById[_soupSwaps[soup]]!;
      final from = items.firstWhere((i) => i.foodId == soup).copyWith(eaten: 1);
      final s = makeSuggestion(to, gap, caveat: fits[to.id], unit: (from.portionId, from.qty));
      final fromPrice = itemPrice(from);
      if (s != null && fromPrice != null) {
        final fromProtein = itemProtein(from);
        out.add(
          Upgrade(
            title: title,
            suggestion: s,
            swapFrom: foodById[soup],
            proteinChange: Range(s.protein.min - fromProtein.max, s.protein.max - fromProtein.min),
            costChange: s.price.mid - fromPrice.mid,
            reason: 'Egusi has more protein than ${foodById[soup]!.name.toLowerCase()}.',
          ),
        );
        continue;
      }
    }

    final staple = ids.where(_pairings.containsKey).firstOrNull;
    if (staple == null) continue;
    final candidates = _pairings[staple]!
        .where((id) => fits.containsKey(id) && !ids.contains(id))
        .map((id) => makeSuggestion(foodById[id]!, gap, caveat: fits[id]))
        .whereType<Suggestion>()
        .where((s) => s.price.min <= budget)
        .toList();
    if (candidates.isEmpty) continue;
    final ranked = _rank(candidates, plantFirst);
    final pick = ranked.where((s) => !used.contains(s.food.id)).firstOrNull ?? ranked.first;
    used.add(pick.food.id);
    out.add(
      Upgrade(title: title, suggestion: pick, proteinChange: pick.protein, costChange: pick.price.mid, reason: _pairLine[pick.food.id] ?? pick.food.note ?? ''),
    );
  }
  return out;
}

SolverResult solve({
  required Range gap,
  required int budget,
  required Diet diet,
  required List<Allergen> allergies,
  required bool plantFirst,
  required List<Meal> meals,
}) {
  final fits = <String, String?>{};
  var hidden = 0;
  for (final f in foods) {
    final fit = suggestionFit(f, diet, allergies);
    if (fit.ok) {
      fits[f.id] = fit.caveat;
    } else if (_unit.containsKey(f.id)) {
      hidden++;
    }
  }
  final pool = _unit.keys
      .where(fits.containsKey)
      .map((id) => makeSuggestion(foodById[id]!, gap, caveat: fits[id]))
      .whereType<Suggestion>()
      .where((s) => s.price.min <= budget)
      .toList();
  final ranked = _rank(pool, plantFirst);
  final byValue = [...ranked]
    ..sort((a, b) {
      if (plantFirst && a.plant != b.plant) return a.plant ? -1 : 1;
      return b.per100.compareTo(a.per100);
    });
  final combos = <Combo>[];
  final best = _combo('Best value for ${fmtNaira(budget)}', byValue, gap, budget);
  if (best != null) combos.add(best);
  final ready = _combo('No cooking', byValue.where((s) => s.ready).toList(), gap, budget);
  if (ready != null && ready.items.map((i) => i.food.id).join() != best?.items.map((i) => i.food.id).join()) combos.add(ready);
  return SolverResult(ranked: ranked, combos: combos, upgrades: _upgrades(meals, gap, budget, plantFirst, fits), hiddenCount: hidden);
}

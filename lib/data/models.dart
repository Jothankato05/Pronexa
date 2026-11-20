/// Core data types for Pronexa. Plain immutable classes with JSON helpers;
/// no code generation, so the model layer stays easy to audit.
library;

enum FoodGroup { plant, staple, soup, animal, drink }

enum AnimalKind { meat, fish, egg, dairy }

enum Allergen { peanut, soy, egg, milk, fish, shellfish, gluten, sesame }

enum Diet { none, vegetarian, vegan, pescatarian, dairyFree, eggFree }

enum Activity { light, moderate, active, athlete }

enum LogSource { quick, portion, describe, photo }

enum PortionId {
  smPack('sm_pack'),
  mdPack('md_pack'),
  lgPack('lg_pack'),
  plate('plate'),
  bowl('bowl'),
  spoon('spoon'),
  wrap('wrap'),
  piece('piece'),
  ball('ball'),
  slice('slice'),
  tin('tin'),
  sachet('sachet'),
  handful('handful'),
  cup('cup'),
  bottle('bottle'),
  pack('pack'),
  serving('serving');

  const PortionId(this.key);

  /// Stable key used in storage and in the AI contract.
  final String key;

  static PortionId? fromKey(String? key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }
}

/// A low–high estimate. Every number Pronexa shows is one of these.
class Range {
  const Range(this.min, this.max);

  final double min;
  final double max;

  double get mid => (min + max) / 2;

  static const zero = Range(0, 0);

  Range operator +(Range other) => Range(min + other.min, max + other.max);
}

class Price {
  const Price(this.min, this.max);

  final int min;
  final int max;

  double get mid => (min + max) / 2;

  Price operator *(double factor) => Price((min * factor).round(), (max * factor).round());
}

class FoodPortion {
  const FoodPortion(this.id, this.grams, {this.price, this.label});

  final PortionId id;

  /// Typical grams for one of this portion (of the basis in [Food.basis]).
  final double grams;

  /// Typical price for one. A clue, never a measure of weight.
  final Price? price;

  /// Overrides the generic portion label for this food.
  final String? label;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.aliases,
    required this.group,
    required this.proteinPer100g,
    required this.portions,
    required this.defaultPortion,
    required this.icon,
    required this.source,
    this.local,
    this.altProtein = false,
    this.animal,
    this.mayContain = const [],
    this.plainAvailable = false,
    this.allergens = const [],
    this.mayContainAllergens = const [],
    this.basis,
    this.defaultQty = 1,
    this.note,
  });

  final String id;
  final String name;
  final String? local;
  final List<String> aliases;
  final FoodGroup group;
  final bool altProtein;
  final AnimalKind? animal;
  final List<AnimalKind> mayContain;
  final bool plainAvailable;
  final List<Allergen> allergens;
  final List<Allergen> mayContainAllergens;
  final double proteinPer100g;
  final String? basis;
  final List<FoodPortion> portions;
  final PortionId defaultPortion;
  final double defaultQty;
  final String icon;

  /// One short, factual line used by the Gap Solver.
  final String? note;
  final String source;

  bool get isPlant => animal == null;

  FoodPortion portion(PortionId id) =>
      portions.firstWhere((p) => p.id == id, orElse: () => portions.firstWhere((p) => p.id == defaultPortion, orElse: () => portions.first));

  bool hasPortion(PortionId id) => portions.any((p) => p.id == id);
}

class MealItem {
  const MealItem({required this.foodId, required this.portionId, required this.qty, this.eaten = 1});

  final String foodId;
  final PortionId portionId;
  final double qty;

  /// Fraction actually eaten: 1, 0.75, 0.5 or 0.25.
  final double eaten;

  MealItem copyWith({String? foodId, PortionId? portionId, double? qty, double? eaten}) =>
      MealItem(foodId: foodId ?? this.foodId, portionId: portionId ?? this.portionId, qty: qty ?? this.qty, eaten: eaten ?? this.eaten);

  Map<String, Object?> toJson() => {'foodId': foodId, 'portionId': portionId.key, 'qty': qty, 'eaten': eaten};

  static MealItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final portion = PortionId.fromKey(json['portionId'] as String?);
    final foodId = json['foodId'];
    final qty = json['qty'];
    if (portion == null || foodId is! String || qty is! num) return null;
    final eaten = json['eaten'];
    return MealItem(foodId: foodId, portionId: portion, qty: qty.toDouble(), eaten: eaten is num ? eaten.toDouble() : 1);
  }
}

class Meal {
  const Meal({required this.id, required this.date, required this.time, required this.items, required this.source, this.text, this.price, this.synced = false});

  final String id;

  /// Local calendar day, `YYYY-MM-DD`.
  final String date;
  final DateTime time;
  final List<MealItem> items;
  final LogSource source;
  final String? text;
  final int? price;
  final bool synced;

  Meal copyWith({List<MealItem>? items, bool? synced, LogSource? source, String? text, int? price}) => Meal(
    id: id,
    date: date,
    time: time,
    items: items ?? this.items,
    source: source ?? this.source,
    text: text ?? this.text,
    price: price ?? this.price,
    synced: synced ?? this.synced,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date,
    'time': time.millisecondsSinceEpoch,
    'items': items.map((i) => i.toJson()).toList(),
    'source': source.name,
    if (text != null) 'text': text,
    if (price != null) 'price': price,
    'synced': synced,
  };

  static Meal? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final date = json['date'];
    final time = json['time'];
    final rawItems = json['items'];
    if (id is! String || date is! String || time is! int || rawItems is! List) return null;
    final items = rawItems.map(MealItem.fromJson).whereType<MealItem>().toList();
    if (items.isEmpty) return null;
    final source = LogSource.values.where((s) => s.name == json['source']).firstOrNull ?? LogSource.quick;
    final price = json['price'];
    return Meal(
      id: id,
      date: date,
      time: DateTime.fromMillisecondsSinceEpoch(time),
      items: items,
      source: source,
      text: json['text'] is String ? json['text'] as String : null,
      price: price is int ? price : null,
      synced: json['synced'] == true,
    );
  }
}

class Profile {
  const Profile({required this.diet, required this.allergies, required this.weightKg, required this.activity});

  final Diet diet;
  final List<Allergen> allergies;

  /// `null` means "not sure"; an average is used.
  final int? weightKg;
  final Activity activity;

  Profile copyWith({Diet? diet, List<Allergen>? allergies, int? weightKg, bool clearWeight = false, Activity? activity}) => Profile(
    diet: diet ?? this.diet,
    allergies: allergies ?? this.allergies,
    weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
    activity: activity ?? this.activity,
  );

  Map<String, Object?> toJson() => {'diet': diet.name, 'allergies': allergies.map((a) => a.name).toList(), 'weightKg': weightKg, 'activity': activity.name};

  static Profile? fromJson(Object? json) {
    if (json is! Map) return null;
    final diet = Diet.values.where((d) => d.name == json['diet']).firstOrNull;
    final activity = Activity.values.where((a) => a.name == json['activity']).firstOrNull;
    if (diet == null || activity == null) return null;
    final rawAllergies = json['allergies'];
    final allergies = rawAllergies is List
        ? rawAllergies.map((a) => Allergen.values.where((x) => x.name == a).firstOrNull).whereType<Allergen>().toList()
        : <Allergen>[];
    final weight = json['weightKg'];
    return Profile(diet: diet, allergies: allergies, weightKg: weight is int ? weight : null, activity: activity);
  }
}

class Settings {
  const Settings({this.lowData = false, this.syncEnabled = false, this.plantFirst = true, this.budget = 500, this.simulateAiDown = false, this.lastCelebrated});

  final bool lowData;
  final bool syncEnabled;
  final bool plantFirst;
  final int budget;
  final bool simulateAiDown;
  final String? lastCelebrated;

  Settings copyWith({bool? lowData, bool? syncEnabled, bool? plantFirst, int? budget, bool? simulateAiDown, String? lastCelebrated}) => Settings(
    lowData: lowData ?? this.lowData,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    plantFirst: plantFirst ?? this.plantFirst,
    budget: budget ?? this.budget,
    simulateAiDown: simulateAiDown ?? this.simulateAiDown,
    lastCelebrated: lastCelebrated ?? this.lastCelebrated,
  );

  Map<String, Object?> toJson() => {
    'lowData': lowData,
    'syncEnabled': syncEnabled,
    'plantFirst': plantFirst,
    'budget': budget,
    'simulateAiDown': simulateAiDown,
    'lastCelebrated': lastCelebrated,
  };

  static Settings fromJson(Object? json) {
    if (json is! Map) return const Settings();
    bool b(String k, bool d) => json[k] is bool ? json[k] as bool : d;
    final budget = json['budget'];
    return Settings(
      lowData: b('lowData', false),
      syncEnabled: b('syncEnabled', false),
      plantFirst: b('plantFirst', true),
      budget: budget is int && budget > 0 && budget <= 100000 ? budget : 500,
      simulateAiDown: b('simulateAiDown', false),
      lastCelebrated: json['lastCelebrated'] is String ? json['lastCelebrated'] as String : null,
    );
  }
}

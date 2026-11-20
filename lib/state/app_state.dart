import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../ai/meal_reader.dart';
import '../data/models.dart';
import '../logic/calc.dart';
import 'storage.dart';

String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Meals older than this are dropped to keep storage small on cheap phones.
const keepDays = 120;

/// App state. One ChangeNotifier, no extra framework.
class AppState extends ChangeNotifier {
  AppState({required this.storage, MealReader? reader, DateTime Function()? clock}) : reader = reader ?? MealReader(), _clock = clock ?? DateTime.now;

  final Storage storage;
  final MealReader reader;
  final DateTime Function() _clock;
  final _random = Random.secure();

  bool ready = false;
  Profile? profile;
  Settings settings = const Settings();
  List<Meal> meals = [];
  bool online = true;

  /// Bumped when today's gap closes for the first time.
  int celebrateTick = 0;

  DateTime get now => _clock();
  String get todayKey => dateKey(now);

  List<Meal> get todayMeals => meals.where((m) => m.date == todayKey).toList()..sort((a, b) => a.time.compareTo(b.time));
  Range get target => profile == null ? Range.zero : proteinTarget(profile!);
  Range get eaten => itemsProtein(todayMeals.expand((m) => m.items));
  Range get gap => proteinGap(target, eaten);

  Future<void> load() async {
    try {
      profile = Profile.fromJson(_decode(await storage.read('profile')));
      settings = Settings.fromJson(_decode(await storage.read('settings')));
      final raw = _decode(await storage.read('meals'));
      final cutoff = dateKey(now.subtract(const Duration(days: keepDays)));
      meals = raw is List ? raw.map(Meal.fromJson).whereType<Meal>().where((m) => m.date.compareTo(cutoff) >= 0).toList() : [];
    } on Exception {
      // Corrupt or unreadable storage: start clean rather than crash.
      meals = [];
    }
    ready = true;
    notifyListeners();
  }

  Object? _decode(String? s) {
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } on FormatException {
      return null;
    }
  }

  Future<void> _saveMeals() => storage.write('meals', jsonEncode(meals.map((m) => m.toJson()).toList()));

  Future<void> saveProfile(Profile p) async {
    profile = p;
    notifyListeners();
    await storage.write('profile', jsonEncode(p.toJson()));
  }

  Future<void> updateSettings(Settings s) async {
    settings = s;
    notifyListeners();
    await storage.write('settings', jsonEncode(s.toJson()));
  }

  void setOnline(bool value) {
    if (value == online) return;
    online = value;
    notifyListeners();
  }

  String _newId() => 'm_${now.millisecondsSinceEpoch.toRadixString(36)}_${_random.nextInt(1 << 32).toRadixString(36)}';

  /// Saves a confirmed meal. Returns it, so the UI can show the total.
  Future<Meal> saveMeal({required List<MealItem> items, required LogSource source, String? text, int? price, String? editingId}) async {
    final before = gap.mid;
    final existing = editingId == null ? null : meals.where((m) => m.id == editingId).firstOrNull;
    final meal = existing != null
        ? existing.copyWith(items: items, text: text, price: price)
        : Meal(id: _newId(), date: todayKey, time: now, items: items, source: source, text: text, price: price);
    meals = existing != null ? meals.map((m) => m.id == meal.id ? meal : m).toList() : [...meals, meal];
    if (before > 0 && gap.mid <= 0 && settings.lastCelebrated != todayKey) {
      celebrateTick++;
      settings = settings.copyWith(lastCelebrated: todayKey);
      await storage.write('settings', jsonEncode(settings.toJson()));
    }
    notifyListeners();
    await _saveMeals();
    return meal;
  }

  /// Removes a meal and returns it so it can be restored (undo).
  Future<Meal?> deleteMeal(String id) async {
    final meal = meals.where((m) => m.id == id).firstOrNull;
    if (meal == null) return null;
    meals = meals.where((m) => m.id != id).toList();
    notifyListeners();
    await _saveMeals();
    return meal;
  }

  Future<void> restoreMeal(Meal meal) async {
    if (meals.any((m) => m.id == meal.id)) return;
    meals = [...meals, meal];
    notifyListeners();
    await _saveMeals();
  }

  Future<void> loadDemoDay() async {
    final today = todayKey;
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    final demo = [
      Meal(
        id: _newId(),
        date: today,
        time: at(8, 10),
        source: LogSource.quick,
        items: const [
          MealItem(foodId: 'bread', portionId: PortionId.slice, qty: 3),
          MealItem(foodId: 'akara', portionId: PortionId.ball, qty: 3),
        ],
      ),
      Meal(
        id: '${_newId()}b',
        date: today,
        time: at(13, 30),
        source: LogSource.describe,
        text: '₦1,000 rice and beans, medium takeaway',
        price: 1000,
        items: const [MealItem(foodId: 'rice_beans', portionId: PortionId.mdPack, qty: 1)],
      ),
    ];
    meals = [...meals.where((m) => m.date != today), ...demo];
    settings = Settings(
      lowData: settings.lowData,
      syncEnabled: settings.syncEnabled,
      plantFirst: settings.plantFirst,
      budget: settings.budget,
      simulateAiDown: settings.simulateAiDown,
    );
    notifyListeners();
    await _saveMeals();
    await storage.write('settings', jsonEncode(settings.toJson()));
  }

  Future<void> resetAll() async {
    await storage.clear();
    profile = null;
    meals = [];
    settings = const Settings();
    notifyListeners();
  }

  /// The last seven days, oldest first: protein eaten and whether anything was logged.
  List<DaySummary> week() => [
    for (var i = 6; i >= 0; i--)
      () {
        final day = now.subtract(Duration(days: i));
        final key = dateKey(day);
        final list = meals.where((m) => m.date == key);
        return DaySummary(day: day, eaten: itemsProtein(list.expand((m) => m.items)), logged: list.isNotEmpty);
      }(),
  ];

  /// Opt-in pilot export: only what the student typed and the foods they
  /// confirmed, in the format of test/data/describe_set.json. No profile,
  /// dates or other meals.
  ({String json, int count}) exportDescriptions() {
    final cases = [
      for (final m in meals.where((m) => m.source == LogSource.describe && (m.text ?? '').trim().isNotEmpty))
        {
          'text': m.text!.trim(),
          'foods': [for (final i in m.items) i.foodId],
          'portions': {for (final i in m.items) i.foodId: i.portionId.key},
          'qty': {for (final i in m.items) i.foodId: i.qty},
        },
    ];
    return (json: const JsonEncoder.withIndent('  ').convert(cases), count: cases.length);
  }

  String exportJson() => const JsonEncoder.withIndent(
    '  ',
  ).convert({'exportedAt': now.toIso8601String(), 'profile': profile?.toJson(), 'settings': settings.toJson(), 'meals': meals.map((m) => m.toJson()).toList()});
}

class DaySummary {
  const DaySummary({required this.day, required this.eaten, required this.logged});

  final DateTime day;
  final Range eaten;
  final bool logged;
}

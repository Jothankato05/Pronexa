import 'package:flutter_test/flutter_test.dart';
import 'package:pronexa/ai/rule_reader.dart';
import 'package:pronexa/ai/types.dart';
import 'package:pronexa/ai/validator.dart';
import 'package:pronexa/data/foods.dart';
import 'package:pronexa/data/models.dart';
import 'package:pronexa/logic/calc.dart';
import 'package:pronexa/logic/diet.dart';
import 'package:pronexa/logic/solver.dart';

Meal meal(String id, List<MealItem> items) => Meal(id: id, date: '2026-11-20', time: DateTime(2026, 11, 20, 12), items: items, source: LogSource.quick);

void main() {
  group('food database', () {
    test('has about 30 foods, each with a valid default portion and source', () {
      expect(foods.length, greaterThanOrEqualTo(30));
      for (final f in foods) {
        expect(f.hasPortion(f.defaultPortion), isTrue, reason: f.id);
        expect(f.proteinPer100g, greaterThan(0), reason: f.id);
        expect(f.source.length, greaterThan(5), reason: f.id);
      }
    });
    test('ids are unique', () => expect(foods.map((f) => f.id).toSet().length, foods.length));
    test('no name belongs to two foods', () {
      final owner = <String, String>{};
      final clashes = <String>[];
      for (final f in foods) {
        for (final a in f.aliases.map(normalise)) {
          final prev = owner[a];
          if (prev != null && prev != f.id) clashes.add('"$a": $prev and ${f.id}');
          owner[a] = f.id;
        }
      }
      expect(clashes, isEmpty);
    });
    test('protein values are plausible and every portion has grams', () {
      for (final f in foods) {
        expect(f.proteinPer100g, inInclusiveRange(0.1, 60), reason: f.id);
        expect(f.portions, isNotEmpty, reason: f.id);
        for (final p in f.portions) {
          expect(p.grams, greaterThan(0), reason: '${f.id} ${p.id}');
        }
      }
    });
    test('animal foods are never marked plant', () {
      for (final f in foods.where((f) => f.group == FoodGroup.animal)) {
        expect(f.animal, isNotNull, reason: f.id);
      }
    });
  });

  group('calculation', () {
    test('medium pack of rice and beans is a range', () {
      final p = itemProtein(const MealItem(foodId: 'rice_beans', portionId: PortionId.mdPack, qty: 1));
      expect(p.mid, closeTo(19.2, 0.1));
      expect(fmtRange(p), '14–24 g');
    });
    test('scales by amount eaten', () {
      final all = itemProtein(const MealItem(foodId: 'beans', portionId: PortionId.spoon, qty: 2));
      final half = itemProtein(const MealItem(foodId: 'beans', portionId: PortionId.spoon, qty: 2, eaten: 0.5));
      expect(half.mid, closeTo(all.mid / 2, 0.001));
    });
    test('target from weight and activity', () {
      final t = proteinTarget(const Profile(diet: Diet.none, allergies: [], weightKg: 60, activity: Activity.moderate));
      expect(t.min, 54);
      expect(t.max, 66);
    });
    test('gap never goes negative', () => expect(proteinGap(const Range(50, 60), const Range(70, 80)).mid, 0));
    test('labels pluralise the head noun', () {
      expect(pluralise('serving spoon of stew'), 'serving spoons of stew');
      expect(pluralise('piece (buka size)'), 'pieces (buka size)');
      expect(portionLabel('stew', PortionId.spoon, 2), '2 serving spoons of stew');
      expect(fmtNaira(1500), '₦1,500');
    });
  });

  group('diet safety', () {
    final animal = foods.where((f) => f.animal != null).map((f) => f.id).toSet();
    test('vegans never see animal products, at any budget or mode', () {
      for (final budget in [200, 500, 1000, 3000]) {
        for (final plantFirst in [true, false]) {
          final r = solve(gap: const Range(30, 40), budget: budget, diet: Diet.vegan, allergies: const [], plantFirst: plantFirst, meals: const []);
          final ids = [
            ...r.ranked.map((s) => s.food.id),
            ...r.combos.expand((c) => c.items.map((i) => i.food.id)),
            ...r.upgrades.map((u) => u.suggestion.food.id),
          ];
          expect(ids.where(animal.contains), isEmpty);
          expect(ids, isNot(contains('egusi')));
        }
      }
    });
    test('vegetarian, pescatarian, dairy-free and egg-free', () {
      final cases = {
        Diet.vegetarian: ['beef', 'chicken', 'fish', 'sardine'],
        Diet.pescatarian: ['beef', 'chicken'],
        Diet.dairyFree: ['milk'],
        Diet.eggFree: ['egg'],
      };
      cases.forEach((diet, banned) {
        final r = solve(gap: const Range(30, 40), budget: 5000, diet: diet, allergies: const [], plantFirst: false, meals: const []);
        expect(r.ranked.map((s) => s.food.id).where(banned.contains), isEmpty, reason: diet.name);
      });
    });
    test('allergens are excluded, including "may contain"', () {
      final r = solve(
        gap: const Range(30, 40),
        budget: 5000,
        diet: Diet.none,
        allergies: const [Allergen.peanut, Allergen.soy, Allergen.shellfish],
        plantFirst: false,
        meals: const [],
      );
      final ids = r.ranked.map((s) => s.food.id);
      for (final id in ['groundnuts', 'soybeans', 'soya_chunks', 'tofu', 'soy_milk', 'moi_moi']) {
        expect(ids, isNot(contains(id)));
      }
    });
    test('plain moi-moi is shown to vegans with a caveat', () {
      final fit = suggestionFit(foodById['moi_moi']!, Diet.vegan, const []);
      expect(fit.ok, isTrue);
      expect(fit.caveat, contains('plain'));
    });
  });

  group('gap solver', () {
    test('plant-first ranks every plant option first', () {
      final r = solve(gap: const Range(25, 30), budget: 3000, diet: Diet.none, allergies: const [], plantFirst: true, meals: const []);
      final firstAnimal = r.ranked.indexWhere((s) => !s.plant);
      final lastPlant = r.ranked.lastIndexWhere((s) => s.plant);
      expect(firstAnimal, greaterThan(lastPlant));
    });
    test('combos stay within budget', () {
      final r = solve(gap: const Range(25, 30), budget: 500, diet: Diet.vegan, allergies: const [], plantFirst: true, meals: const []);
      expect(r.combos, isNotEmpty);
      for (final c in r.combos) {
        expect(c.cost, lessThanOrEqualTo(500));
      }
    });
    test('upgrades a low-protein meal with a pairing', () {
      final r = solve(
        gap: const Range(30, 40),
        budget: 1000,
        diet: Diet.none,
        allergies: const [],
        plantFirst: true,
        meals: [
          meal('m1', const [MealItem(foodId: 'white_rice', portionId: PortionId.mdPack, qty: 1), MealItem(foodId: 'stew', portionId: PortionId.spoon, qty: 2)]),
        ],
      );
      expect(['beans', 'moi_moi', 'soya_chunks', 'tofu'], contains(r.upgrades.first.suggestion.food.id));
    });
    test('swaps okra soup for egusi when allowed', () {
      final r = solve(
        gap: const Range(30, 40),
        budget: 1000,
        diet: Diet.none,
        allergies: const [],
        plantFirst: false,
        meals: [
          meal('m2', const [MealItem(foodId: 'eba', portionId: PortionId.wrap, qty: 1), MealItem(foodId: 'okra', portionId: PortionId.serving, qty: 1)]),
        ],
      );
      final swap = r.upgrades.where((u) => u.swapFrom != null).first;
      expect(swap.suggestion.food.id, 'egusi');
      expect(swap.proteinChange.mid, greaterThan(0));
    });
  });

  group('AI guard rails', () {
    test('foods not in the database are dropped', () {
      final v = validate(
        RawReading.fromJson({
          'items': [
            {'foodId': 'sushi'},
            {'foodId': 'beans', 'portionId': 'spoon', 'qty': 2},
          ],
        }),
      );
      expect(v.items.map((i) => i.item.foodId), ['beans']);
      expect(v.rejected, ['sushi']);
    });
    test('invalid portions fall back and quantities are clamped', () {
      final v = validate(
        RawReading.fromJson({
          'items': [
            {'foodId': 'egg', 'portionId': 'lg_pack', 'qty': 999, 'eaten': 0.6},
          ],
        }),
      );
      expect(v.items.single.item.portionId, PortionId.piece);
      expect(v.items.single.item.qty, 20);
      expect(v.items.single.item.eaten, 0.5);
    });
    test('malformed AI output is ignored safely', () {
      expect(RawReading.fromJson('not json').items, isEmpty);
      expect(RawReading.fromJson({'items': 'nope', 'price': -5}).price, isNull);
      expect(
        RawReading.fromJson({
          'items': [
            42,
            null,
            {'foodId': 7},
          ],
        }).items,
        isEmpty,
      );
    });
    test('price only suggests a size, and the size is asked', () {
      final v = validate(readMeal('rice and stew 700 naira'));
      expect(v.items.firstWhere((i) => i.item.foodId == 'white_rice').source, PortionSource.price);
      expect(v.confidence, isNot(Confidence.high));
      expect(v.question?.text, contains('How big'));
    });
    test('the demo sentence is read with high confidence', () {
      final v = validate(readMeal('₦1,000 rice and beans, medium takeaway'));
      expect(v.confidence, Confidence.high);
      expect(v.question, isNull);
    });
    test('unknown words get an honest question', () {
      final v = validate(readMeal('rice and sushi'));
      expect(v.unknown, contains('sushi'));
      expect(v.question!.options.map((o) => o.label), ['Skip']);
    });
    test('no-protein items are noted', () {
      expect(validate(readMeal('bread and tea')).notes.join(' '), contains('tea'));
    });
  });
}

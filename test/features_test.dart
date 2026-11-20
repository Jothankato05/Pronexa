import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronexa/data/foods.dart';
import 'package:pronexa/data/lessons.dart';
import 'package:pronexa/data/models.dart';
import 'package:pronexa/logic/calc.dart';
import 'package:pronexa/logic/plans.dart';
import 'package:pronexa/main.dart';
import 'package:pronexa/state/app_state.dart';
import 'package:pronexa/state/storage.dart';

const _target = Range(54, 66);

AppState _state({Diet diet = Diet.none}) {
  final s = MemoryStorage();
  s.data['profile'] = jsonEncode(Profile(diet: diet, allergies: const [], weightKg: 60, activity: Activity.moderate).toJson());
  return AppState(storage: s, clock: () => DateTime(2026, 11, 20, 13));
}

void main() {
  group('meal planner', () {
    test('every planned portion exists and has a price', () {
      for (final diet in Diet.values) {
        for (final p in planDays(target: _target, budget: 100000, diet: diet, allergies: const [], limit: 1000)) {
          for (final m in p.meals) {
            for (final i in m.items) {
              expect(foodById[i.foodId]!.hasPortion(i.portionId), isTrue, reason: '${i.foodId} ${i.portionId}');
              expect(itemPrice(i), isNotNull, reason: i.foodId);
            }
          }
        }
      }
    });

    test('plans stay within the daily budget', () {
      for (final budget in [1500, 2500, 4000]) {
        for (final p in planDays(target: _target, budget: budget, diet: Diet.none, allergies: const [])) {
          expect(p.cost, lessThanOrEqualTo(budget));
        }
      }
    });

    test('a vegan plan has no animal products, and a ₦2,500 day reaches 60 g', () {
      final plans = planDays(target: _target, budget: 2500, diet: Diet.vegan, allergies: const []);
      expect(plans, isNotEmpty);
      for (final p in plans) {
        for (final m in p.meals) {
          for (final i in m.items) {
            expect(foodById[i.foodId]!.animal, isNull, reason: i.foodId);
          }
        }
      }
      expect(plans.first.protein.mid, greaterThanOrEqualTo(_target.mid));
    });

    test('allergies are respected', () {
      final plans = planDays(target: _target, budget: 4000, diet: Diet.none, allergies: const [Allergen.peanut, Allergen.soy]);
      final ids = plans.expand((p) => p.meals).expand((m) => m.items).map((i) => i.foodId).toSet();
      expect(ids.intersection({'groundnuts', 'kuli_kuli', 'peanut_butter', 'soya_chunks', 'tofu', 'soy_milk'}), isEmpty);
    });
  });

  test('lessons are short', () {
    expect(lessons.length, 5);
    for (final l in lessons) {
      expect(l.points.length, inInclusiveRange(3, 5));
      for (final p in l.points) {
        expect(p.length, lessThan(140), reason: p);
      }
    }
  });

  group('app state', () {
    test('week has seven days ending today', () async {
      final s = _state();
      await s.load();
      await s.loadDemoDay();
      final w = s.week();
      expect(w.length, 7);
      expect(dateKey(w.last.day), s.todayKey);
      expect(w.last.logged, isTrue);
      expect(w.first.logged, isFalse);
    });

    test('the pilot export holds only typed text and confirmed foods', () async {
      final s = _state();
      await s.load();
      await s.saveMeal(
        items: const [MealItem(foodId: 'beans', portionId: PortionId.spoon, qty: 2)],
        source: LogSource.describe,
        text: 'beans 2 spoon',
      );
      await s.saveMeal(
        items: const [MealItem(foodId: 'egg', portionId: PortionId.piece, qty: 1)],
        source: LogSource.quick,
      );
      final out = s.exportDescriptions();
      expect(out.count, 1);
      final list = jsonDecode(out.json) as List;
      final c = list.single as Map;
      expect(c.keys.toSet(), {'text', 'foods', 'portions', 'qty'});
      expect(c['foods'], ['beans']);
      expect(out.json, isNot(contains('weightKg')));
    });
  });

  testWidgets('Learn opens the planner, the challenge and a lesson', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = _state(diet: Diet.vegan);
    await t.pumpWidget(PronexaApp(state: s, watchConnectivity: false));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Learn'));
    await t.pumpAndSettle();
    await t.tap(find.text('Meal planner'));
    await t.pumpAndSettle();
    expect(find.textContaining('BREAKFAST'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Another plan'), 300);
    await t.tap(find.text('Another plan'));
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('₦500 challenge'));
    await t.pumpAndSettle();
    expect(find.textContaining('/ 7'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text(lessons.first.title));
    await t.pumpAndSettle();
    expect(find.text(lessons.first.points.first), findsOneWidget);
  });
}

import '../data/foods.dart';
import '../data/models.dart';
import 'calc.dart';
import 'diet.dart';

/// A meal in a plan: a name and what is in it.
class PlanMeal {
  const PlanMeal(this.slot, this.items);

  final String slot;
  final List<MealItem> items;

  Range get protein => itemsProtein(items);
  double get cost => items.fold(0, (n, i) => n + (itemPrice(i)?.mid ?? 0));
  bool get plant => items.every((i) => foodById[i.foodId]!.isPlant);
}

class DayPlan {
  const DayPlan(this.meals);

  final List<PlanMeal> meals;

  Range get protein => meals.fold(Range.zero, (r, m) => r + m.protein);
  double get cost => meals.fold(0, (n, m) => n + m.cost);
  int get plantMeals => meals.where((m) => m.plant).length;
}

MealItem _i(String id, PortionId p, double q) => MealItem(foodId: id, portionId: p, qty: q);

/// Everyday campus meals, plant protein first. Only foods from the database.
final _breakfasts = [
  [_i('bread', PortionId.slice, 4), _i('akara', PortionId.ball, 4)],
  [_i('moi_moi', PortionId.wrap, 1), _i('bread', PortionId.slice, 2)],
  [_i('garri_soaked', PortionId.cup, 1), _i('groundnuts', PortionId.sachet, 1)],
  [_i('bread', PortionId.slice, 3), _i('peanut_butter', PortionId.spoon, 1)],
  [_i('oats', PortionId.cup, 1), _i('soy_milk', PortionId.bottle, 1)],
  [_i('garri_soaked', PortionId.cup, 1), _i('kuli_kuli', PortionId.handful, 1)],
  [_i('bread', PortionId.slice, 4), _i('egg', PortionId.piece, 2)],
  [_i('yam', PortionId.slice, 3), _i('egg', PortionId.piece, 2), _i('stew', PortionId.spoon, 1)],
];

final _lunches = [
  [_i('rice_beans', PortionId.mdPack, 1)],
  [_i('rice_beans', PortionId.mdPack, 1), _i('stew', PortionId.spoon, 1)],
  [_i('white_rice', PortionId.smPack, 1), _i('beans', PortionId.spoon, 2), _i('plantain', PortionId.serving, 1)],
  [_i('amala', PortionId.wrap, 1), _i('gbegiri', PortionId.serving, 1)],
  [_i('beans', PortionId.mdPack, 1), _i('bread', PortionId.slice, 2)],
  [_i('white_rice', PortionId.mdPack, 1), _i('beans', PortionId.spoon, 2), _i('stew', PortionId.spoon, 2)],
  [_i('jollof_rice', PortionId.mdPack, 1), _i('moi_moi', PortionId.wrap, 1)],
  [_i('spaghetti', PortionId.plate, 1), _i('soya_chunks', PortionId.handful, 1), _i('stew', PortionId.spoon, 1)],
  [_i('eba', PortionId.wrap, 1), _i('egusi', PortionId.serving, 1), _i('tofu', PortionId.piece, 3)],
  [_i('amala', PortionId.wrap, 1), _i('gbegiri', PortionId.serving, 1), _i('ewedu', PortionId.serving, 1)],
  [_i('white_rice', PortionId.mdPack, 1), _i('stew', PortionId.spoon, 2), _i('fish', PortionId.piece, 1)],
  [_i('eba', PortionId.wrap, 1), _i('egusi', PortionId.serving, 1), _i('beef', PortionId.piece, 2)],
];

final _dinners = [
  [_i('beans', PortionId.spoon, 3), _i('plantain', PortionId.serving, 1)],
  [_i('okpa', PortionId.wrap, 1)],
  [_i('lentils', PortionId.bowl, 1), _i('white_rice', PortionId.spoon, 2)],
  [_i('pounded_yam', PortionId.wrap, 1), _i('efo_riro', PortionId.serving, 1), _i('tofu', PortionId.piece, 3)],
  [_i('noodles', PortionId.pack, 1), _i('soya_chunks', PortionId.handful, 1)],
  [_i('pigeon_pea', PortionId.spoon, 2), _i('yam', PortionId.slice, 2)],
  [_i('noodles', PortionId.pack, 1), _i('egg', PortionId.piece, 2)],
  [_i('yam_porridge', PortionId.plate, 1), _i('fish', PortionId.piece, 1)],
];

final _snacks = <List<MealItem>>[
  [],
  [_i('groundnuts', PortionId.sachet, 1)],
  [_i('soy_milk', PortionId.bottle, 1)],
  [_i('kuli_kuli', PortionId.handful, 1)],
];

bool _fits(List<MealItem> items, Diet diet, List<Allergen> allergies) =>
    items.every((i) => suggestionFit(foodById[i.foodId]!, diet, allergies).ok && itemPrice(i) != null);

/// Day plans that fit the diet, allergies and daily budget, best first:
/// plans that reach the target, then more plant meals, then cheaper.
/// Different plans differ in lunch and dinner, so "another plan" feels new.
List<DayPlan> planDays({required Range target, required int budget, required Diet diet, required List<Allergen> allergies, int limit = 12}) {
  List<List<MealItem>> ok(List<List<MealItem>> list) => list.where((m) => _fits(m, diet, allergies)).toList();
  final b = ok(_breakfasts);
  final l = ok(_lunches);
  final d = ok(_dinners);
  final s = ok(_snacks);
  final all = <DayPlan>[];
  for (final x in b) {
    for (final y in l) {
      for (final z in d) {
        for (final w in s) {
          final plan = DayPlan([PlanMeal('Breakfast', x), PlanMeal('Lunch', y), PlanMeal('Dinner', z), if (w.isNotEmpty) PlanMeal('Snack', w)]);
          if (plan.cost <= budget) all.add(plan);
        }
      }
    }
  }
  int reaches(DayPlan p) => p.protein.mid >= target.mid ? 1 : 0;
  all.sort((p, q) {
    final r = reaches(q).compareTo(reaches(p));
    if (r != 0) return r;
    if (reaches(p) == 0) return q.protein.mid.compareTo(p.protein.mid);
    final plant = q.plantMeals.compareTo(p.plantMeals);
    if (plant != 0) return plant;
    return p.cost.compareTo(q.cost);
  });
  final picked = <DayPlan>[];
  final seen = <String>{};
  for (final p in all) {
    final key = '${p.meals[1].items.first.foodId}-${p.meals[2].items.first.foodId}';
    if (seen.add(key)) picked.add(p);
    if (picked.length == limit) break;
  }
  return picked;
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pronexa/ai/rule_reader.dart';
import 'package:pronexa/ai/validator.dart';
import 'package:pronexa/data/foods.dart';

/// Describe-it test set (test/data/describe_set.json): English, Pidgin, local
/// names, typos, fractions and prices, checked against the offline reader.
/// It was written alongside the reader, so it is a regression check, not an
/// accuracy claim. Measure any real AI on fresh descriptions.
class Case {
  Case.fromJson(Map<String, Object?> j)
    : text = j['text']! as String,
      foods = (j['foods']! as List).cast<String>(),
      portions = ((j['portions'] ?? <String, Object?>{}) as Map).cast<String, String>(),
      qty = ((j['qty'] ?? <String, Object?>{}) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      eaten = (j['eaten'] as num?)?.toDouble();

  final String text;
  final List<String> foods;
  final Map<String, String> portions;
  final Map<String, double> qty;
  final double? eaten;
}

/// Returns null when the reading matches, or what went wrong.
String? check(Case c) {
  final raw = readMeal(c.text);
  final got = raw.items.map((i) => i.foodId).toList()..sort();
  final want = [...c.foods]..sort();
  if (got.join(',') != want.join(',')) return 'foods $got, wanted $want';
  final reading = validate(raw);
  for (final e in c.portions.entries) {
    final p = reading.items.firstWhere((i) => i.item.foodId == e.key).item.portionId.key;
    if (p != e.value) return 'portion of ${e.key} is $p, wanted ${e.value}';
  }
  for (final e in c.qty.entries) {
    final q = reading.items.firstWhere((i) => i.item.foodId == e.key).item.qty;
    if (q != e.value) return 'qty of ${e.key} is $q, wanted ${e.value}';
  }
  if (c.eaten != null && !reading.items.every((i) => i.item.eaten == c.eaten)) return 'eaten, wanted ${c.eaten}';
  return null;
}

List<Case> load(String path) => (jsonDecode(File(path).readAsStringSync()) as List).map((j) => Case.fromJson(j as Map<String, Object?>)).toList();

void main() {
  final cases = [...load('test/data/describe_set.json'), ...load('test/data/describe_holdout.json')];

  test('every expected food id exists', () {
    for (final c in cases) {
      for (final id in [...c.foods, ...c.portions.keys, ...c.qty.keys]) {
        expect(foodById.containsKey(id), isTrue, reason: '$id in "${c.text}"');
      }
    }
  });

  test('describe-it set: ${cases.length} descriptions', () {
    final failures = <String>[];
    for (final c in cases) {
      final why = check(c);
      if (why != null) failures.add('"${c.text}": $why');
    }
    // ignore: avoid_print
    print('Describe-it set: ${cases.length - failures.length}/${cases.length} read correctly');
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  // Real descriptions from pilot students (tool/add_pilot_cases.dart). Scored,
  // never failing: fix the reader for the misses, then move them into the set.
  test('pilot descriptions (scored only)', () {
    final pilot = load('test/data/describe_pilot.json');
    if (pilot.isEmpty) return;
    final misses = [
      for (final c in pilot)
        if (check(c) case final why?) '"${c.text}": $why',
    ];
    // ignore: avoid_print
    print('Pilot set: ${pilot.length - misses.length}/${pilot.length} read correctly${misses.isEmpty ? '' : '\n${misses.join('\n')}'}');
  });
}

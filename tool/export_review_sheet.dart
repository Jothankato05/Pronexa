// Writes docs/food_review.csv: every food, its protein value, portions and
// source, with empty columns for a nutrition professional to fill in.
//   dart run tool/export_review_sheet.dart
import 'dart:io';

import 'package:pronexa/data/foods.dart';
import 'package:pronexa/data/portions.dart';

String _cell(Object? v) {
  final s = '${v ?? ''}';
  return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

void main() {
  final rows = <List<Object?>>[
    [
      'id',
      'name',
      'local name',
      'group',
      'protein g/100 g',
      'basis',
      'portions (grams, price ₦)',
      'source',
      'reviewed protein g/100 g',
      'portion notes',
      'ok? (y/n)',
      'reviewer',
    ],
    for (final f in foods)
      [
        f.id,
        f.name,
        f.local,
        f.group.name,
        f.proteinPer100g,
        f.basis ?? 'as eaten',
        f.portions
            .map((p) => '${p.label ?? portionMeta[p.id]!.one}: ${p.grams.round()} g${p.price == null ? '' : ', ${p.price!.min}–${p.price!.max}'}')
            .join('; '),
        f.source,
        '',
        '',
        '',
        '',
      ],
  ];
  File('docs/food_review.csv').writeAsStringSync('${rows.map((r) => r.map(_cell).join(',')).join('\n')}\n');
  stdout.writeln('docs/food_review.csv written (${foods.length} foods)');
}

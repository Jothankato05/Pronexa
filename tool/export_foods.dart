// Exports the food list the AI server may choose from, so the app's database
// stays the single source of truth. Run: dart run tool/export_foods.dart
import 'dart:convert';
import 'dart:io';

import 'package:pronexa/data/foods.dart';

String exportFoodsJson() => const JsonEncoder.withIndent('  ').convert({
  'dbVersion': dbVersion,
  'foods': [
    for (final f in foods)
      {
        'id': f.id,
        'name': f.name,
        'aliases': f.aliases.take(8).toList(),
        'portions': f.portions.map((p) => p.id.key).toList(),
        'defaultPortion': f.defaultPortion.key,
      },
  ],
});

void main() {
  File('server/src/foods.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('${exportFoodsJson()}\n');
  stdout.writeln('server/src/foods.json written (${foods.length} foods)');
}

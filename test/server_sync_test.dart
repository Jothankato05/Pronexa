import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/export_foods.dart';

/// The AI server may only choose foods from the app's database. If this fails,
/// run `dart run tool/export_foods.dart` and commit server/src/foods.json.
void main() {
  test('server food list matches the app database', () {
    final onDisk = File('server/src/foods.json').readAsStringSync().trim();
    expect(onDisk, exportFoodsJson().trim());
  });
}

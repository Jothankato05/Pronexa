// Adds meal descriptions shared by pilot students (Profile > Share meal
// descriptions) to test/data/describe_pilot.json.
//
//   dart run tool/add_pilot_cases.dart shared1.json shared2.json ...
//
// Each file is the JSON the app copies. Cases with unknown food ids or text
// already in a test set are skipped. The pilot set is scored by
// `flutter test test/reader_eval_test.dart` but never fails the build: fix
// the reader for the misses, then move the cases into describe_set.json.
import 'dart:convert';
import 'dart:io';

import 'package:pronexa/data/foods.dart';

const _sets = ['test/data/describe_set.json', 'test/data/describe_holdout.json', 'test/data/describe_pilot.json'];
const _out = 'test/data/describe_pilot.json';

List<Map<String, Object?>> _read(String path) {
  final f = File(path);
  if (!f.existsSync()) return [];
  final data = jsonDecode(f.readAsStringSync());
  return data is List ? data.whereType<Map<String, Object?>>().toList() : [];
}

String _key(Object? text) => '$text'.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/add_pilot_cases.dart shared.json [...]');
    exitCode = 64;
    return;
  }
  final seen = {for (final s in _sets) ..._read(s).map((c) => _key(c['text']))};
  final pilot = _read(_out);
  var added = 0;
  var skipped = 0;
  for (final path in args) {
    for (final c in _read(path)) {
      final text = c['text'];
      final ids = c['foods'];
      final ok = text is String && text.trim().isNotEmpty && text.length <= 280 && ids is List && ids.isNotEmpty && ids.every((id) => foodById.containsKey(id));
      if (!ok || !seen.add(_key(text))) {
        skipped++;
        continue;
      }
      pilot.add({'text': text.trim(), 'foods': ids, if (c['portions'] is Map) 'portions': c['portions'], if (c['qty'] is Map) 'qty': c['qty']});
      added++;
    }
  }
  File(_out).writeAsStringSync('[\n${pilot.map((c) => '  ${jsonEncode(c)}').join(',\n')}\n]\n');
  stdout.writeln('$added added, $skipped skipped. $_out now has ${pilot.length} descriptions.');
}

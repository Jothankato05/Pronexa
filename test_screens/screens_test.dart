// Renders the main screens to PNG with the real fonts, for review and docs.
// Not part of CI. Run: flutter test test_screens --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronexa/ai/rule_reader.dart';
import 'package:pronexa/ai/validator.dart';
import 'package:pronexa/data/models.dart';
import 'package:pronexa/main.dart';
import 'package:pronexa/state/app_state.dart';
import 'package:pronexa/state/storage.dart';
import 'package:pronexa/ui/draft.dart';
import 'package:pronexa/ui/scope.dart';
import 'package:pronexa/ui/screens/confirm.dart';
import 'package:pronexa/ui/screens/describe.dart';
import 'package:pronexa/ui/screens/photo.dart';
import 'package:pronexa/ui/screens/quick_pick.dart';
import 'package:pronexa/ui/screens/settings.dart';
import 'package:pronexa/ui/theme.dart';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> paths) async {
    final loader = FontLoader(name);
    for (final p in paths) {
      loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Poppins', ['assets/fonts/Poppins-Regular.ttf', 'assets/fonts/Poppins-Medium.ttf', 'assets/fonts/Poppins-SemiBold.ttf']);
  await family('NairaSign', ['assets/fonts/NairaSign.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  await family('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
}

AppState _state({bool profile = true, Diet diet = Diet.none}) {
  final s = MemoryStorage();
  if (profile) s.data['profile'] = jsonEncode(Profile(diet: diet, allergies: const [], weightKg: 65, activity: Activity.moderate).toJson());
  return AppState(storage: s, clock: () => DateTime(2026, 11, 20, 14, 5));
}

Future<void> _size(WidgetTester t) async {
  t.view.physicalSize = const Size(720, 1560);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.pumpAndSettle();
  await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('../docs/screens/$name.png'));
}

Widget _wrap(AppState s, Widget home) => AppScope(
  state: s,
  child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(), home: home),
);

void main() {
  setUpAll(_loadFonts);

  testWidgets('01 welcome', (t) async {
    await _size(t);
    await t.pumpWidget(PronexaApp(state: _state(profile: false), watchConnectivity: false));
    await _shot(t, '01-welcome');
    await t.tap(find.text('Start'));
    await t.pumpAndSettle();
    await _shot(t, '02-diet');
  });

  testWidgets('03 today', (t) async {
    await _size(t);
    final s = _state();
    await t.pumpWidget(PronexaApp(state: s, watchConnectivity: false));
    await t.pumpAndSettle();
    await s.loadDemoDay();
    await _shot(t, '03-today');
    await t.tap(find.byTooltip('Log a meal'));
    await _shot(t, '04-log');
    await t.tap(find.byTooltip('Close the gap'));
    await _shot(t, '06-solve');
    await t.tap(find.byTooltip('Learn'));
    await _shot(t, '09-learn');
  });

  testWidgets('05 confirm', (t) async {
    await _size(t);
    final s = _state();
    await s.load();
    final reading = validate(readMeal('rice and stew 700 naira and shawarma'));
    await t.pumpWidget(
      _wrap(
        s,
        ConfirmScreen(
          draft: Draft.fromReading(reading, source: LogSource.describe, text: 'rice and stew 700 naira and shawarma'),
        ),
      ),
    );
    await _shot(t, '05-confirm');
  });

  testWidgets('07 describe, photo, pick, profile', (t) async {
    await _size(t);
    final s = _state(diet: Diet.vegan);
    await s.load();
    await t.pumpWidget(_wrap(s, const DescribeScreen()));
    await _shot(t, '07-describe');
    await t.pumpWidget(_wrap(s, const PhotoScreen()));
    await _shot(t, '08-photo');
    await t.pumpWidget(_wrap(s, const QuickPickScreen()));
    await _shot(t, '10-pick');
    await t.pumpWidget(_wrap(s, const SettingsScreen()));
    await _shot(t, '11-profile');
  });
}

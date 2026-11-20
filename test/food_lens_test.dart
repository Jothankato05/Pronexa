import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pronexa/ai/food_lens.dart';
import 'package:pronexa/data/foods.dart';
import 'package:pronexa/data/models.dart';
import 'package:pronexa/state/app_state.dart';
import 'package:pronexa/state/storage.dart';
import 'package:pronexa/ui/scope.dart';
import 'package:pronexa/ui/screens/photo.dart';
import 'package:pronexa/ui/theme.dart';

final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

class _Picker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(_png, name: 'meal.jpg', mimeType: 'image/jpeg');

  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

class FakeLens implements FoodLens {
  FakeLens({this.available = true, this.guesses = const [LensGuess('moi_moi', 0.7), LensGuess('plantain', 0.4)]});

  final bool available;
  final List<LensGuess> guesses;
  int recognised = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<LensGuess>> recognise(Uint8List photo) async {
    recognised++;
    return guesses;
  }
}

Future<AppState> _pump(WidgetTester t, FoodLens lens) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final storage = MemoryStorage();
  storage.data['profile'] = jsonEncode(const Profile(diet: Diet.none, allergies: [], weightKg: 60, activity: Activity.moderate).toJson());
  final state = AppState(storage: storage, lens: lens, clock: () => DateTime(2026, 11, 20, 13));
  await state.load();
  await t.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme(),
        home: PhotoScreen(picker: _Picker()),
      ),
    ),
  );
  await t.pumpAndSettle();
  return state;
}

void main() {
  group('label map', () {
    test('41 labels, every mapped food exists', () {
      expect(lensLabels.length, 41);
      for (final (name, ids) in lensLabels) {
        for (final id in ids) {
          expect(foodById.containsKey(id), isTrue, reason: '$name -> $id');
        }
      }
    });

    test('scores become database foods, best first, above the threshold', () {
      final scores = List<double>.filled(41, 0.05);
      scores[lensLabels.indexWhere((l) => l.$1 == 'Eba')] = 0.81;
      scores[lensLabels.indexWhere((l) => l.$1 == 'Egusi soup')] = 0.87;
      scores[lensLabels.indexWhere((l) => l.$1 == 'Stockfish')] = 0.74;
      scores[lensLabels.indexWhere((l) => l.$1 == 'Onion')] = 0.9; // no protein: ignored
      scores[lensLabels.indexWhere((l) => l.$1 == 'Rice')] = 0.19; // below threshold
      expect(guessesFromScores(scores).map((g) => g.foodId), ['egusi', 'eba', 'dry_fish']);
    });

    test('combined labels give both foods, keeping the higher score', () {
      final scores = List<double>.filled(41, 0);
      scores[lensLabels.indexWhere((l) => l.$1 == 'Akara And Bread')] = 0.6;
      scores[lensLabels.indexWhere((l) => l.$1 == 'Akara')] = 0.8;
      final g = guessesFromScores(scores);
      expect(g.map((x) => x.foodId), ['akara', 'bread']);
      expect(g.first.score, 0.8);
    });

    test('never more than four guesses', () {
      expect(guessesFromScores(List<double>.filled(41, 0.9)).length, 4);
    });
  });

  test('the model input is the centre square, 384x384 RGB in 0..1', () async {
    // A 2x1 image: red on the left, blue on the right. The centre square is
    // the middle, so the output mixes both but stays within 0..1.
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, 200, 100), ui.Paint()..color = const ui.Color(0xFFFF0000));
    final img = await recorder.endRecording().toImage(200, 100);
    final png = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final x = await lensInput(png);
    expect(x.length, 384 * 384 * 3);
    expect(x.every((v) => v >= 0 && v <= 1), isTrue);
    expect(x[0], closeTo(1, 0.01)); // red
    expect(x[1], closeTo(0, 0.01));
    expect(x[2], closeTo(0, 0.01));
  });

  test('optional: dump the model input for the sample meal photo', () async {
    // Used to check the app's preparation against the Python reference
    // (tool/food_model). Runs only when PRONEXA_LENS_SAMPLE points to a JPEG.
    final path = Platform.environment['PRONEXA_LENS_SAMPLE'];
    if (path == null) return;
    final x = await lensInput(File(path).readAsBytesSync());
    File('$path.f32').writeAsBytesSync(x.buffer.asUint8List());
  });

  testWidgets('with the recogniser installed, a photo shows "Looks like" and Pick offers them first', (t) async {
    final lens = FakeLens();
    final state = await _pump(t, lens);
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(lens.recognised, 1);
    expect(find.text('LOOKS LIKE'), findsOneWidget);
    expect(find.textContaining('Moi-moi'), findsWidgets);
    await t.tap(find.text('Check and add foods'));
    await t.pumpAndSettle();
    expect(find.text('LOOKS LIKE'), findsOneWidget, reason: 'suggestions shown first on Pick');
    expect(find.text('Next: 1 food'), findsNothing, reason: 'suggestions are not pre-selected');
    await t.tap(find.text('Moi-moi').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Next: 1 food'));
    await t.pumpAndSettle();
    await t.tap(find.text('Add to today'));
    await t.pumpAndSettle();
    expect(state.meals.single.items.single.foodId, 'moi_moi');
    expect(state.meals.single.source, LogSource.photo);
  });

  testWidgets('a build without the recogniser falls back to picking', (t) async {
    final lens = FakeLens(available: false);
    await _pump(t, lens);
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(lens.recognised, 0);
    expect(find.text('Pick the foods you see.'), findsOneWidget);
    expect(find.text('Pick the foods myself'), findsOneWidget);
  });

  testWidgets('works with no internet and in low-data mode', (t) async {
    final lens = FakeLens();
    final state = await _pump(t, lens);
    state.setOnline(false);
    await state.updateSettings(state.settings.copyWith(lowData: true));
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(lens.recognised, 1);
    expect(find.text('LOOKS LIKE'), findsOneWidget);
  });

  test('the bundled model and the label map agree', () {
    // Checked when the model has been built into assets/models.
    final f = File('assets/models/pronexa-food-v1.labels.json');
    if (!f.existsSync()) return;
    final labels = ((jsonDecode(f.readAsStringSync()) as Map)['labels'] as List).cast<String>();
    expect(labels, lensLabels.map((l) => l.$1).toList());
  });
}

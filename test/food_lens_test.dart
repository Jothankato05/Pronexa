import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pronexa/ai/food_lens.dart';
import 'package:pronexa/ai/photo_memory.dart';
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
  FakeLens({this.available = true, this.guesses = const [LensGuess('moi_moi', 0.7), LensGuess('plantain', 0.4)], this.features});

  final bool available;
  final List<LensGuess> guesses;
  Float32List? features;
  int recognised = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> prepare() async {}

  @override
  Future<LensResult> recognise(Uint8List photo) async {
    recognised++;
    return LensResult(guesses, features);
  }
}

/// A unit-length fingerprint pointing mostly along [axis], tilted by [tilt].
Float32List fingerprint(int axis, {double tilt = 0, int tiltAxis = 0}) {
  final v = Float32List(lensFeatures);
  v[axis] = 1;
  v[tiltAxis] += tilt;
  var n = 0.0;
  for (final x in v) {
    n += x * x;
  }
  final len = math.sqrt(n);
  for (var i = 0; i < v.length; i++) {
    v[i] /= len;
  }
  return v;
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

  group('dish head (trained on photo fingerprints)', () {
    // Two dishes; fingerprint axis 0 means suya, axis 1 means egusi.
    Float32List fp(int axis) => Float32List(lensFeatures)..[axis] = 1;
    DishHead head() {
      final w = Float32List(2 * lensFeatures)
        ..[0] = 1
        ..[lensFeatures + 1] = 1;
      return DishHead(
        scale: 10,
        minScore: 0.35,
        foods: const [
          ['suya'],
          ['egusi'],
        ],
        bias: Float64List(2),
        weights: w,
      );
    }

    test('probabilities sum to one and follow the fingerprint', () {
      final p = head().probabilities(fp(0));
      expect(p.reduce((a, b) => a + b), closeTo(1, 1e-9));
      expect(p[0], greaterThan(0.99));
    });

    test('a confident dish comes first, then the recogniser foods, at most four', () {
      const lens = [LensGuess('eba', 0.9), LensGuess('suya', 0.3), LensGuess('beef', 0.25), LensGuess('fish', 0.22), LensGuess('egg', 0.21)];
      final out = head().merge(fp(0), lens);
      expect(out.map((g) => g.foodId), ['suya', 'eba', 'beef', 'fish']);
    });

    test('an unsure head leaves the recogniser alone', () {
      const lens = [LensGuess('eba', 0.9)];
      // A blank fingerprint gives 50/50, below this head's 0.9 bar.
      final unsure = DishHead(scale: 1, minScore: 0.9, foods: head().foods, bias: Float64List(2), weights: head().weights);
      expect(unsure.merge(Float32List(lensFeatures), lens).map((g) => g.foodId), ['eba']);
    });

    test('the shipped head matches the fingerprint size and names only database foods', () {
      final f = File(dishHeadAsset);
      expect(f.existsSync(), isTrue, reason: 'run tool/food_model/train_head.py');
      final h = DishHead.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, Object?>);
      expect(h.weights.length, h.bias.length * lensFeatures);
      for (final ids in h.foods) {
        for (final id in ids) {
          expect(foodById, contains(id));
        }
      }
    });
  });

  group('photo memory (learning new foods on the phone)', () {
    test('a confirmed photo is recalled for a similar photo, not for a different one', () {
      final m = PhotoMemory();
      expect(m.learn(['chips', 'egg'], fingerprint(3), '2026-11-20'), isTrue);
      final similar = m.recall(fingerprint(3, tilt: 0.5, tiltAxis: 9)); // cosine about 0.89
      expect(similar.map((g) => g.foodId), ['chips', 'egg']);
      expect(similar.every((g) => g.learned), isTrue);
      expect(m.recall(fingerprint(3, tilt: 2, tiltAxis: 9)), isEmpty); // cosine about 0.45
      expect(m.recall(fingerprint(700)), isEmpty);
    });

    test('8-bit storage keeps similarities accurate', () {
      final m = PhotoMemory()..learn(['suya'], fingerprint(5, tilt: 0.3, tiltAxis: 6), 'd');
      final q = fingerprint(5, tilt: 0.3, tiltAxis: 6);
      expect(m.examples.single.similarity(q), closeTo(1, 0.01));
    });

    test('near-duplicates are not stored twice, and the oldest are forgotten', () {
      final m = PhotoMemory();
      expect(m.learn(['chips'], fingerprint(1), 'd'), isTrue);
      expect(m.learn(['chips'], fingerprint(1), 'd'), isFalse);
      expect(m.learn(['egg'], fingerprint(1), 'd'), isTrue, reason: 'same look, different foods: worth keeping');
      for (var i = 0; i < PhotoMemory.maxExamples + 20; i++) {
        m.learn(['beans'], fingerprint(10 + i), 'd');
      }
      expect(m.length, PhotoMemory.maxExamples);
      expect(m.recall(fingerprint(1)), isEmpty, reason: 'the first photos were forgotten');
    });

    test('unknown foods and bad fingerprints are ignored; storage round-trips', () {
      final m = PhotoMemory();
      expect(m.learn(['not_a_food'], fingerprint(1), 'd'), isFalse);
      expect(m.learn(['chips'], Float32List(10), 'd'), isFalse);
      m.learn(['chips', 'egg'], fingerprint(2), '2026-11-20');
      final back = PhotoMemory.fromJson(jsonDecode(jsonEncode(m.toJson())));
      expect(back.length, 1);
      expect(back.recall(fingerprint(2)).map((g) => g.foodId), ['chips', 'egg']);
      expect(PhotoMemory.fromJson('rubbish').length, 0);
      expect(
        PhotoMemory.fromJson([
          {
            'foods': ['chips'],
            'v': 'not base64!',
          },
        ]).length,
        0,
      );
    });
  });

  testWidgets('after one confirmed photo of chips, the next similar photo suggests chips', (t) async {
    final lens = FakeLens(guesses: const [LensGuess('plantain', 0.33)], features: fingerprint(42));
    final state = await _pump(t, lens);

    // First photo: the recogniser doesn't know chips; the student picks it.
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(find.textContaining('Chips'), findsNothing);
    await t.tap(find.text('Check and add foods'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'chips');
    await t.pumpAndSettle();
    await t.tap(find.text('Chips').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Next: 1 food'));
    await t.pumpAndSettle();
    await t.tap(find.text('Add to today'));
    await t.pumpAndSettle();
    expect(state.memory.length, 1);
    expect(state.memory.examples.single.foods, ['chips']);

    // A similar photo later: chips comes first, marked as learned.
    lens.features = fingerprint(42, tilt: 0.4, tiltAxis: 7);
    await t.pumpWidget(const SizedBox());
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
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(find.text('Chips'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.textContaining('meals you confirmed before'), findsOneWidget);
  });

  test('clearing or deleting everything forgets learned photos', () async {
    final storage = MemoryStorage();
    storage.data['profile'] = jsonEncode(const Profile(diet: Diet.none, allergies: [], weightKg: 60, activity: Activity.moderate).toJson());
    final state = AppState(storage: storage, lens: FakeLens(), clock: () => DateTime(2026, 11, 20, 13));
    await state.load();
    await state.saveMeal(
      items: const [MealItem(foodId: 'chips', portionId: PortionId.smPack, qty: 1)],
      source: LogSource.photo,
      photoFeatures: fingerprint(3),
    );
    expect(state.memory.length, 1);
    final reloaded = AppState(storage: storage, lens: FakeLens(), clock: () => DateTime(2026, 11, 20, 13));
    await reloaded.load();
    expect(reloaded.memory.length, 1, reason: 'kept on the phone across restarts');
    await reloaded.clearPhotoMemory();
    expect(reloaded.memory.length, 0);
    await state.resetAll();
    expect(state.memory.length, 0);
  });
}

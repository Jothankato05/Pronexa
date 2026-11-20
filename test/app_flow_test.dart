import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pronexa/ai/food_lens.dart';
import 'package:pronexa/data/models.dart';
import 'package:pronexa/main.dart';
import 'package:pronexa/state/app_state.dart';
import 'package:pronexa/state/storage.dart';
import 'package:pronexa/ui/screens/photo.dart';
import 'package:pronexa/ui/scope.dart';
import 'package:pronexa/ui/theme.dart';

// 1×1 PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

class FakePicker extends ImagePicker {
  FakePicker(this.bytes);
  final Uint8List bytes;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(bytes, name: 'meal.jpg', mimeType: 'image/jpeg');

  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

/// The real recogniser needs the phone's ONNX Runtime; tests use none.
class NoLens implements FoodLens {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> prepare() async {}

  @override
  Future<List<LensGuess>> recognise(Uint8List photo) async => const [];
}

AppState _state({bool withProfile = true}) {
  final storage = MemoryStorage();
  if (withProfile) {
    storage.data['profile'] = jsonEncode(const Profile(diet: Diet.none, allergies: [], weightKg: 60, activity: Activity.moderate).toJson());
  }
  return AppState(storage: storage, lens: NoLens(), clock: () => DateTime(2026, 11, 20, 13));
}

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PronexaApp(state: state, watchConnectivity: false));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).first;
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding sets a target and lands on Today', (tester) async {
    final state = _state(withProfile: false);
    await _pumpApp(tester, state);
    await _tapText(tester, 'Start');
    await _tapText(tester, 'No restrictions');
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'None');
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'On my feet a lot');
    await _tapText(tester, 'Continue');
    expect(find.text('60'), findsOneWidget);
    expect(find.text('54–66 g'), findsOneWidget);
    await _tapText(tester, 'Start');
    expect(find.text("Today's meals"), findsOneWidget);
    expect(state.profile?.activity, Activity.moderate);
  });

  testWidgets('Pick logs a meal after confirmation', (tester) async {
    final state = _state();
    await _pumpApp(tester, state);
    await _tapText(tester, 'PICK');
    await _tapText(tester, 'Beans');
    await _tapText(tester, 'Next: 1 food');
    expect(find.text('Check your meal'), findsOneWidget);
    expect(state.meals, isEmpty, reason: 'nothing is counted before confirming');
    await _tapText(tester, 'Add to today');
    expect(state.meals.single.items.single.foodId, 'beans');
    expect(find.textContaining('Added'), findsOneWidget);
  });

  testWidgets('Describe reads Pidgin/price text and asks for confirmation', (tester) async {
    final state = _state();
    await _pumpApp(tester, state);
    await _tapText(tester, 'DESCRIBE');
    await tester.enterText(find.byType(TextField).first, '₦1,000 rice and beans, medium takeaway');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Check your meal'), findsOneWidget);
    expect(find.text('Rice and beans'), findsWidgets);
    expect(find.text('Looks clear'), findsOneWidget);
    await _tapText(tester, 'Add to today');
    expect(state.meals.single.source, LogSource.describe);
  });

  testWidgets('Photo mode: take a photo, then pick the foods in it', (tester) async {
    final state = _state();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await state.load();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: buildTheme(),
          home: PhotoScreen(picker: FakePicker(_png)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tapText(tester, 'Take a photo');
    expect(find.byType(Image), findsOneWidget, reason: 'the photo is shown');
    // No AI server in tests, so the student picks the foods.
    expect(find.text('Pick the foods myself'), findsOneWidget);
    await _tapText(tester, 'Pick the foods myself');
    expect(find.text("What's in it?"), findsOneWidget);
    await _tapText(tester, 'Akara');
    await _tapText(tester, 'Next: 1 food');
    await _tapText(tester, 'Add to today');
    expect(state.meals.single.source, LogSource.photo);
    expect(state.meals.single.items.single.foodId, 'akara');
  });

  testWidgets('vegan suggestions show no animal products', (tester) async {
    final state = _state();
    state.storage as MemoryStorage;
    await _pumpApp(tester, state);
    await state.saveProfile(state.profile!.copyWith(diet: Diet.vegan));
    await tester.tap(find.byTooltip('Close the gap'));
    await tester.pumpAndSettle();
    for (final animal in ['Egg', 'Chicken', 'Beef', 'Fish', 'Sardines', 'Milk']) {
      expect(find.text(animal), findsNothing, reason: animal);
    }
    expect(find.text('Soybeans'), findsWidgets);
  });
}

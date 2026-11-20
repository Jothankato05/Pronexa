import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/food_lens.dart';
import '../../ai/meal_reader.dart';
import '../../data/foods.dart';
import '../../data/models.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Photo mode. Uses the phone's own camera app through image_picker, so the
/// app needs no camera permission. Photos stay in memory and are never saved.
/// They leave the phone only if the student taps "Read the photo" and the AI
/// server is set up.
class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key, this.picker});

  /// Injected in tests.
  final ImagePicker? picker;

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  Uint8List? _photo;
  bool _busy = false;
  String? _message;

  // On-phone recogniser.
  bool _lens = false;
  bool _looking = false;
  List<LensGuess>? _guesses;

  @override
  void initState() {
    super.initState();
    unawaited(_checkLens());
    // On low-memory Android phones the system can close Pronexa while the camera
    // app is open. This recovers the photo when the app comes back.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) unawaited(_recoverLost());
  }

  Future<void> _checkLens() async {
    final lens = AppScope.read(context).lens;
    final available = await lens.isAvailable();
    if (available) unawaited(lens.prepare());
    if (!mounted) return;
    setState(() => _lens = available);
    if (available && _photo != null) unawaited(_recognise());
  }

  Future<void> _recognise() async {
    final photo = _photo;
    if (photo == null || !_lens) return;
    setState(() {
      _looking = true;
      _guesses = null;
    });
    List<LensGuess> found;
    try {
      found = await AppScope.read(context).lens.recognise(photo).timeout(const Duration(seconds: 60));
    } on Exception {
      // Includes the time limit: fall back to picking by hand.
      found = const [];
    }
    if (!mounted || _photo != photo) return;
    setState(() {
      _looking = false;
      _guesses = found;
    });
  }

  Future<void> _recoverLost() async {
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty || lost.file == null) return;
      await _load(lost.file!);
    } on Exception {
      // Nothing to recover, or recovery isn't supported here. Never block the screen.
    }
  }

  Future<void> _take(ImageSource source) async {
    setState(() => _message = null);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
        requestFullMetadata: false, // no location or camera details
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return; // cancelled
      await _load(file);
    } on PlatformException catch (e) {
      setState(
        () => _message = switch (e.code) {
          'camera_access_denied' => 'Camera not allowed. Use the gallery instead.',
          'no_available_camera' => 'No camera found. Use the gallery instead.',
          _ => "The camera didn't open. Try again.",
        },
      );
    }
  }

  Future<void> _load(XFile file) async {
    final bytes = await file.readAsBytes();
    // Remove the temporary copy right away; keep the photo in memory only.
    if (!kIsWeb && file.path.isNotEmpty) {
      try {
        await File(file.path).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    if (!mounted) return;
    if (bytes.lengthInBytes > maxPhotoBytes) {
      setState(() => _message = 'Photo too large. Try the camera.');
      return;
    }
    setState(() {
      _photo = bytes;
      _guesses = null;
    });
    final state = AppScope.read(context);
    final canRead = state.reader.hasRemote && state.online && !state.settings.lowData && !state.settings.simulateAiDown;
    if (!canRead) unawaited(_recognise());
  }

  Future<void> _read() async {
    final photo = _photo;
    if (photo == null) return;
    final state = AppScope.read(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await state.reader.readPhoto(photo, online: state.online, lowData: state.settings.lowData, aiDown: state.settings.simulateAiDown);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case ReadOk(:final reading):
        await openConfirm(context, Draft.fromReading(reading, source: LogSource.photo, photo: photo));
      case ReadFail(:final reason):
        setState(() => _message = reason == ReadFailure.nothingFound ? 'No foods found. Pick them yourself.' : "Couldn't read it. Pick the foods yourself.");
    }
  }

  /// What the on-phone recogniser shows under the photo.
  Widget _lensPanel() {
    final text = Theme.of(context).textTheme;
    if (!_lens) return Text('Pick the foods you see.', style: text.bodyMedium, textAlign: TextAlign.center);
    if (_looking) {
      return const Column(
        children: [
          LinearProgressIndicator(minHeight: 4),
          SizedBox(height: 12),
          Text('Looking at your photo…', textAlign: TextAlign.center),
        ],
      );
    }
    final g = _guesses;
    if (g == null) return const SizedBox.shrink();
    if (g.isEmpty) return Text("Couldn't tell. Pick the foods you see.", style: text.bodyMedium, textAlign: TextAlign.center);
    return Appear(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Label('Looks like'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final x in g) _GuessChip(name: foodById[x.foodId]!.name, score: x.score)],
          ),
          const SizedBox(height: 10),
          Text('Check before adding: guesses can be wrong.', style: text.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final canRead = state.reader.hasRemote && state.online && !state.settings.lowData && !state.settings.simulateAiDown;
    final photo = _photo;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        children: [
          FadeSwap(
            id: photo == null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photo == null) ...[
                  Container(
                    height: 300,
                    decoration: BoxDecoration(color: C.indigo, borderRadius: BorderRadius.circular(R.xl)),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(color: const Color(0x1CFFFFFF), borderRadius: BorderRadius.circular(R.lg)),
                          child: const Icon(Icons.photo_camera_outlined, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SHOOT FROM ABOVE, IN GOOD LIGHT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: Color(0xB3FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(onPressed: () => _take(ImageSource.camera), child: const Text('Take a photo')),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => _take(ImageSource.gallery), child: const Text('Choose from gallery')),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(R.xl),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.memory(photo, fit: BoxFit.cover, semanticLabel: 'Your meal photo'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (canRead)
                    FilledButton.icon(
                      onPressed: _busy ? null : _read,
                      icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                      label: Text(_busy ? 'Reading the photo…' : 'Read the photo'),
                    )
                  else
                    _lensPanel(),
                  const SizedBox(height: 16),
                  (canRead ? OutlinedButton.new : FilledButton.new)(
                    onPressed: _busy || _looking ? null : () => openQuickPick(context, photo: photo, suggested: [...?_guesses?.map((g) => g.foodId)]),
                    child: Text((_guesses?.isNotEmpty ?? false) ? 'Check and add foods' : 'Pick the foods myself'),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(onPressed: _busy ? null : () => setState(() => _photo = null), icon: const Icon(Icons.refresh), label: const Text('Retake')),
                ],
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Appear(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: C.warm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuessChip extends StatelessWidget {
  const _GuessChip({required this.name, required this.score});

  final String name;
  final double score;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: C.fill,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: C.line),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: C.ink),
          ),
          TextSpan(
            text: '  ${(score * 100).round()}%',
            style: const TextStyle(fontSize: 12, color: C.ink3),
          ),
        ],
      ),
    ),
  );
}

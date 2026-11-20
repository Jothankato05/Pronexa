import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/meal_reader.dart';
import '../../data/models.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

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

  @override
  void initState() {
    super.initState();
    // On low-memory Android phones the system can close Pronexa while the camera
    // app is open. This recovers the photo when the app comes back.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) unawaited(_recoverLost());
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
          'camera_access_denied' => 'Pronexa is not allowed to use the camera. Allow it in your phone settings, or choose from the gallery.',
          'no_available_camera' => 'No camera app found on this phone. Choose from the gallery instead.',
          _ => 'The camera could not open. Try again, or choose from the gallery.',
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
      setState(() => _message = 'That photo is too large. Try again with the camera.');
      return;
    }
    setState(() => _photo = bytes);
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
        setState(
          () => _message = reason == ReadFailure.nothingFound
              ? 'No foods found in the photo. Pick them yourself.'
              : 'The photo could not be read right now. Pick the foods yourself.',
        );
    }
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (photo == null) ...[
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 48, color: C.leaf600),
                  const SizedBox(height: 12),
                  Text('Photograph your plate or pack', style: text.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Take it from above, in good light.', style: text.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => _take(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Take a photo')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _take(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(R.lg),
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
              Panel(
                color: C.ochre100,
                child: Text(
                  state.settings.lowData
                      ? 'Low-data mode is on, so the photo stays on your phone. Pick the foods you see.'
                      : !state.online
                      ? 'You are offline. Pick the foods you see in the photo.'
                      : 'Reading photos needs the AI server. Pick the foods you see in the photo.',
                  style: text.bodyMedium?.copyWith(color: C.ochre800),
                ),
              ),
            const SizedBox(height: 10),
            (canRead ? OutlinedButton.new : FilledButton.new)(
              onPressed: _busy ? null : () => openQuickPick(context, photo: photo),
              child: const Text('Pick the foods myself'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(onPressed: _busy ? null : () => setState(() => _photo = null), icon: const Icon(Icons.refresh), label: const Text('Retake')),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Panel(
                color: C.clay100,
                child: Text(_message!, style: text.bodyMedium?.copyWith(color: C.clay700)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Photos are not saved. They are sent only when you tap "Read the photo".', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

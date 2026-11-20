import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/foods.dart';
import 'rule_reader.dart';
import 'types.dart';
import 'validator.dart';

/// Optional remote AI reader (see server/). Set at build time:
///   flutter build apk --dart-define=PRONEXA_AI_URL=https://your-server.example
/// The app never holds an AI key; the server does.
const aiEndpoint = String.fromEnvironment('PRONEXA_AI_URL');

const maxTextLength = 280;
const maxPhotoBytes = 1500 * 1024;

sealed class ReadResult {
  const ReadResult();
}

class ReadOk extends ReadResult {
  const ReadOk(this.reading, {required this.onDevice});
  final Reading reading;

  /// True when the phone's own rules read it (no AI call).
  final bool onDevice;
}

enum ReadFailure { empty, unavailable, nothingFound, needsAi, tooLarge }

class ReadFail extends ReadResult {
  const ReadFail(this.reason, {this.unknown = const []});
  final ReadFailure reason;
  final List<String> unknown;
}

class MealReader {
  MealReader({http.Client? client, String endpoint = aiEndpoint, this.timeout = const Duration(seconds: 12)})
    : _client = client ?? http.Client(),
      _endpoint = endpoint.trim();

  final http.Client _client;
  final String _endpoint;
  final Duration timeout;
  final Map<String, RawReading> _cache = {};

  bool get hasRemote => _endpoint.startsWith('https://');

  /// Reads a typed description. Uses the remote AI when available, otherwise
  /// the on-device rules, so describing still works offline.
  Future<ReadResult> readText(String input, {required bool online, bool aiDown = false}) async {
    final text = input.trim();
    if (text.isEmpty) return const ReadFail(ReadFailure.empty);
    if (aiDown) return const ReadFail(ReadFailure.unavailable);
    final clipped = text.length > maxTextLength ? text.substring(0, maxTextLength) : text;
    final key = '$dbVersion:${normalise(clipped)}';

    var raw = _cache[key];
    var onDevice = true;
    if (raw == null && hasRemote && online) {
      raw = await _postJson('/v1/read-text', {'text': clipped, 'dbVersion': dbVersion});
      onDevice = raw == null;
    }
    raw ??= readMeal(clipped);
    if (_cache.length > 100) _cache.remove(_cache.keys.first);
    _cache[key] = raw;

    final reading = validate(raw);
    if (reading.items.isEmpty) return ReadFail(ReadFailure.nothingFound, unknown: reading.unknown);
    return ReadOk(reading, onDevice: onDevice);
  }

  /// Reads a meal photo. Needs the remote AI: photos are never read on the phone.
  Future<ReadResult> readPhoto(Uint8List jpeg, {required bool online, required bool lowData, bool aiDown = false}) async {
    if (aiDown || !hasRemote || !online || lowData) return const ReadFail(ReadFailure.needsAi);
    if (jpeg.lengthInBytes > maxPhotoBytes) return const ReadFail(ReadFailure.tooLarge);
    final raw = await _postJson('/v1/read-photo', {'image': base64Encode(jpeg), 'mediaType': 'image/jpeg', 'dbVersion': dbVersion});
    if (raw == null) return const ReadFail(ReadFailure.unavailable);
    final reading = validate(raw);
    if (reading.items.isEmpty) return ReadFail(ReadFailure.nothingFound, unknown: reading.unknown);
    return ReadOk(reading, onDevice: false);
  }

  Future<RawReading?> _postJson(String path, Map<String, Object?> body) async {
    try {
      final res = await _client.post(Uri.parse('$_endpoint$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(timeout);
      if (res.statusCode != 200 || res.bodyBytes.length > 64 * 1024) return null;
      return RawReading.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    } on Exception {
      // Network, timeout or bad JSON: the caller falls back. Nothing is logged (no user text in logs).
      return null;
    }
  }
}

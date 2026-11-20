import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value store. Everything lives on the phone.
abstract class Storage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class PrefsStorage implements Storage {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString('pronexa.$key');

  @override
  Future<void> write(String key, String value) => _prefs.setString('pronexa.$key', value);

  @override
  Future<void> clear() => _prefs.clear();
}

/// For tests, and as a fallback if the platform store fails.
class MemoryStorage implements Storage {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> clear() async => data.clear();
}

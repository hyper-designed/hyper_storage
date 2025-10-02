import 'package:hyper_storage/hyper_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A storage backend implementation that uses [SharedPreferences] for persistent
/// key-value data storage across app sessions.
class SharedPreferencesBackend extends StorageBackend {
  SharedPreferencesAsync? _prefs;

  /// Gets the underlying [SharedPreferences] instance.
  SharedPreferencesAsync get prefs {
    return _prefs ??
        (throw StateError(
          'SharedPreferencesBackend not initialized. Call init() first.',
        ));
  }

  /// Creates a new [SharedPreferencesBackend].
  ///
  /// Optionally accepts an existing [SharedPreferencesAsync] instance for
  /// dependency injection or custom configuration.
  ///
  /// If none is provided, a new instance will be created during [init].
  SharedPreferencesBackend([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<void> setString(String key, String value) => prefs.setString(key, value);

  @override
  Future<String?> getString(String key) => prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) => prefs.setBool(key, value);

  @override
  Future<bool?> getBool(String key) => prefs.getBool(key);

  @override
  Future<void> setDouble(String key, double value) => prefs.setDouble(key, value);

  @override
  Future<double?> getDouble(String key) => prefs.getDouble(key);

  @override
  Future<void> setInt(String key, int value) => prefs.setInt(key, value);

  @override
  Future<int?> getInt(String key) => prefs.getInt(key);

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    final allKeys = await getKeys();
    if (allowList == null || allowList.isEmpty) allowList = allKeys;
    final data = await prefs.getAll(allowList: allowList.toSet());
    return data.map((key, value) => MapEntry(key, value));
  }

  @override
  Future<Set<String>> getKeys() => prefs.getKeys();

  @override
  Future<void> remove(String key) => prefs.remove(key);

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  @override
  Future<bool> containsKey(String key) => prefs.containsKey(key);

  @override
  Future<void> clear() => prefs.clear();

  @override
  Future<void> close() async {
    _prefs = null;
  }
}

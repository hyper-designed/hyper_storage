import 'package:hyper_storage/hyper_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesBackend extends StorageBackend {
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync get prefs {
    return _prefs ??
        (throw StateError(
          'SharedPreferencesBackend not initialized. Call init() first.',
        ));
  }

  @override
  Future<SharedPreferencesBackend> init() async {
    _prefs ??= SharedPreferencesAsync();
    return this;
  }

  @override
  Future<HyperStorageContainer> container(String name) async {
    final backend = SharedPreferencesBackend();
    await backend.init();
    return HyperStorageContainer(backend: backend, name: name);
  }

  @override
  Future<void> setString(String key, String value) =>
      prefs.setString(key, value);

  @override
  Future<String?> getString(String key) => prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) => prefs.setBool(key, value);

  @override
  Future<bool?> getBool(String key) => prefs.getBool(key);

  @override
  Future<void> setDouble(String key, double value) =>
      prefs.setDouble(key, value);

  @override
  Future<double?> getDouble(String key) => prefs.getDouble(key);

  @override
  Future<void> setInt(String key, int value) => prefs.setInt(key, value);

  @override
  Future<int?> getInt(String key) => prefs.getInt(key);

  Future<void> setStringList(String key, List<String> value) =>
      prefs.setStringList(key, value);

  Future<List<String>?> getStringList(String key) => prefs.getStringList(key);

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    for (final MapEntry(:key, :value) in values.entries) {
      await switch (value) {
        String value => prefs.setString(key, value),
        int value => prefs.setInt(key, value),
        double value => prefs.setDouble(key, value),
        bool value => prefs.setBool(key, value),
        List<String> value => prefs.setStringList(key, value),
        _ => throw ArgumentError(
          'Unsupported value type: ${value.runtimeType}',
        ),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    // decoded keys associated with this container.
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
  Future<void> clear() => prefs.clear();

  @override
  Future<bool> containsKey(String key) => prefs.containsKey(key);

  @override
  Future<void> close() async {
    _prefs = null;
  }
}

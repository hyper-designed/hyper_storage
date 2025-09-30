part of 'hyper_storage.dart';

abstract class _StorageBase with ListenableStorage implements StorageOperationsApi {
  final StorageBackend backend;

  _StorageBase(this.backend);

  @override
  Future<bool> containsKey(String key) => backend.containsKey(key);

  @override
  Future<E?> get<E>(String key) => backend.get<E>(key);

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) => backend.getAll(allowList);

  @override
  Future<bool?> getBool(String key) => backend.getBool(key);

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) => backend.getDateTime(key, isUtc: isUtc);

  @override
  Future<double?> getDouble(String key) => backend.getDouble(key);

  @override
  Future<Duration?> getDuration(String key) => backend.getDuration(key);

  @override
  Future<int?> getInt(String key) => backend.getInt(key);

  @override
  Future<Map<String, dynamic>?> getJson(String key) => backend.getJson(key);

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) => backend.getJsonList(key);

  @override
  Future<Set<String>> getKeys() => backend.getKeys();

  @override
  Future<String?> getString(String key) => backend.getString(key);

  @override
  Future<List<String>?> getStringList(String key) => backend.getStringList(key);

  @override
  Future<bool> get isEmpty => backend.isEmpty;

  @override
  Future<bool> get isNotEmpty => backend.isNotEmpty;

  @override
  Future<void> remove(String key) async {
    await backend.remove(key);
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    await backend.removeAll(keys);
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> set<E>(String key, E value) async {
    await backend.set<E>(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    await backend.setAll(values);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await backend.setBool(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    await backend.setDateTime(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await backend.setDouble(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    await backend.setDuration(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await backend.setInt(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await backend.setJson(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await backend.setJsonList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await backend.setString(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await backend.setStringList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> clear() async {
    await backend.clear();
    notifyListeners();
    removeAllListeners();
  }

  @override
  Future<void> close() => backend.close();
}

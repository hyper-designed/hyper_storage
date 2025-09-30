part of 'hyper_storage.dart';

abstract class _StorageBase with ListenableStorage implements StorageOperationsApi {
  final StorageBackend backend;

  _StorageBase(this.backend);

  void _validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('Key cannot be empty');
    if (key.trim().isEmpty) throw ArgumentError('Key cannot be only whitespace');
  }

  void _validateKeys(Iterable<String>? keys) {
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      _validateKey(key);
    }
  }

  @override
  Future<bool> containsKey(String key) {
    _validateKey(key);
    return backend.containsKey(key);
  }

  @override
  Future<E?> get<E>(String key) {
    _validateKey(key);
    return backend.get<E>(key);
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) {
    _validateKeys(allowList);
    return backend.getAll(allowList);
  }

  @override
  Future<bool?> getBool(String key) {
    _validateKey(key);
    return backend.getBool(key);
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) {
    _validateKey(key);
    return backend.getDateTime(key, isUtc: isUtc);
  }

  @override
  Future<double?> getDouble(String key) {
    _validateKey(key);
    return backend.getDouble(key);
  }

  @override
  Future<Duration?> getDuration(String key) {
    _validateKey(key);
    return backend.getDuration(key);
  }

  @override
  Future<int?> getInt(String key) {
    _validateKey(key);
    return backend.getInt(key);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) {
    _validateKey(key);
    return backend.getJson(key);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) {
    _validateKey(key);
    return backend.getJsonList(key);
  }

  @override
  Future<Set<String>> getKeys() => backend.getKeys();

  @override
  Future<String?> getString(String key) {
    _validateKey(key);
    return backend.getString(key);
  }

  @override
  Future<List<String>?> getStringList(String key) {
    _validateKey(key);
    return backend.getStringList(key);
  }

  @override
  Future<bool> get isEmpty => backend.isEmpty;

  @override
  Future<bool> get isNotEmpty => backend.isNotEmpty;

  @override
  Future<void> remove(String key) async {
    _validateKey(key);
    await backend.remove(key);
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    _validateKeys(keys);
    await backend.removeAll(keys);
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> set<E>(String key, E value) async {
    _validateKey(key);
    await backend.set<E>(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    _validateKeys(values.keys);
    await backend.setAll(values);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _validateKey(key);
    await backend.setBool(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    _validateKey(key);
    await backend.setDateTime(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _validateKey(key);
    await backend.setDouble(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    _validateKey(key);
    await backend.setDuration(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    _validateKey(key);
    await backend.setInt(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _validateKey(key);
    await backend.setJson(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    _validateKey(key);
    await backend.setJsonList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _validateKey(key);
    await backend.setString(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _validateKey(key);
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

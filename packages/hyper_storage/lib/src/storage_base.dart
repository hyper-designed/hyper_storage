part of 'hyper_storage.dart';

abstract class _StorageBase implements StorageOperationsApi {
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
  Future<void> remove(String key) => backend.remove(key);

  @override
  Future<void> removeAll(Iterable<String> keys) => backend.removeAll(keys);

  @override
  Future<void> set<E>(String key, E value) => backend.set<E>(key, value);

  @override
  Future<void> setAll(Map<String, dynamic> values) => backend.setAll(values);

  @override
  Future<void> setBool(String key, bool value) => backend.setBool(key, value);

  @override
  Future<void> setDateTime(String key, DateTime value) => backend.setDateTime(key, value);

  @override
  Future<void> setDouble(String key, double value) => backend.setDouble(key, value);

  @override
  Future<void> setDuration(String key, Duration value) => backend.setDuration(key, value);

  @override
  Future<void> setInt(String key, int value) => backend.setInt(key, value);

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) => backend.setJson(key, value);

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) => backend.setJsonList(key, value);

  @override
  Future<void> setString(String key, String value) => backend.setString(key, value);

  @override
  Future<void> setStringList(String key, List<String> value) => backend.setStringList(key, value);

  @override
  Future<void> clear() => backend.clear();

  @override
  Future<void> close() => backend.close();
}

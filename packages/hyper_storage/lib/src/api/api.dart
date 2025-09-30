import 'package:meta/meta.dart';

abstract interface class SerializableStorageOperationsApi<E> {
  @protected
  String serialize(E value);

  @protected
  E deserialize(String value);

  @protected
  String generateId();

  @protected
  String getId(E value);

  Future<bool> get isEmpty;

  Future<bool> get isNotEmpty;

  Future<void> set(String key, E value);

  Future<void> setAll(Map<String, E> items);

  Future<void> add(E value);

  Future<void> addAll(Iterable<E> values);

  Future<void> update(E value);

  Future<void> updateAll(Iterable<E> values);

  Future<E?> get(String? key);

  Future<Map<String, E>> getAll([Iterable<String>? allowList]);

  Future<List<E>> getValues();

  Future<Set<String>> getKeys();

  Future<bool> containsKey(String key);

  Future<void> remove(String key);

  Future<void> removeAll(Iterable<String> keys);

  Future<void> removeItem(E item);

  Future<void> removeAllItems(Iterable<E> items);

  Future<void> clear();

  Future<void> close();
}

abstract interface class ItemHolderApi<E> {
  Future<bool> get exists;

  Future<E?> get();

  Future<void> set(E value);

  Future<void> remove();
}

abstract interface class StorageOperationsApi {
  Future<bool> get isEmpty;

  Future<bool> get isNotEmpty;

  Future<bool> containsKey(String key);

  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<int?> getInt(String key);

  Future<void> setInt(String key, int value);

  Future<double?> getDouble(String key);

  Future<void> setDouble(String key, double value);

  Future<bool?> getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]);

  Future<void> setAll(Map<String, dynamic> values);

  Future<void> setStringList(String key, List<String> value);

  Future<List<String>?> getStringList(String key);

  Future<void> setJson(String key, Map<String, dynamic> value);

  Future<Map<String, dynamic>?> getJson(String key);

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value);

  Future<List<Map<String, dynamic>>?> getJsonList(String key);

  Future<DateTime?> getDateTime(String key, {bool isUtc = false});

  Future<void> setDateTime(String key, DateTime value);

  Future<Duration?> getDuration(String key);

  Future<void> setDuration(String key, Duration value);

  Future<E?> get<E>(String key);

  Future<void> set<E>(String key, E value);

  Future<void> remove(String key);

  Future<void> removeAll(Iterable<String> keys);

  Future<Set<String>> getKeys();

  Future<void> clear();

  Future<void> close();
}

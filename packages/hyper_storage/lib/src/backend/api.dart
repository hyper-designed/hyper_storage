abstract interface class DataAPI implements DataAPIBase {
  Future<void> setString(String key, String value);

  Future<String?> getString(String key);

  Future<void> setInt(String key, int value);

  Future<int?> getInt(String key);

  Future<void> setDouble(String key, double value);

  Future<double?> getDouble(String key);

  Future<void> setBool(String key, bool value);

  Future<bool?> getBool(String key);

  Future<void> setAll(Map<String, dynamic> values);

  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]);
}

abstract interface class DataAPIBase {
  Future<bool> containsKey(String key);

  Future<void> remove(String key);

  Future<void> removeAll(Iterable<String> keys);

  Future<Set<String>> getKeys();

  Future<void> close();

  /// Clear all keys and values in this storage.
  ///
  /// If name is provided, it only clears keys under that namespace.
  Future<void> clear();
}

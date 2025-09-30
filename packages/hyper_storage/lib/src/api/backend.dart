import 'dart:convert';

import '../hyper_storage_container.dart';
import '../utils.dart';
import 'api.dart';

/// Base class for local storage implementations.
abstract class StorageBackend with GenericStorageOperationsMixin implements StorageOperationsApi {
  Future<void> init() async {}

  Future<HyperStorageContainer> container(String name) async => HyperStorageContainer(backend: this, name: name);

  @override
  Future<bool> get isEmpty async {
    final keys = await getKeys();
    return keys.isEmpty;
  }

  @override
  Future<bool> get isNotEmpty async {
    final keys = await getKeys();
    return keys.isNotEmpty;
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    for (final MapEntry(:key, :value) in values.entries) {
      set(key, value);
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) => setString(key, jsonEncode(value));

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! List) return null;
    return List<String>.from(decoded);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) => setString(key, jsonEncode(value));

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) => setString(key, jsonEncode(value));

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! List) return null;
    return List<Map<String, dynamic>>.from(decoded);
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    final value = await getInt(key);
    if (value == null) return null;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    if (isUtc) return dateTime;
    return dateTime.toLocal();
  }

  @override
  Future<void> setDateTime(String key, DateTime value) =>
      setInt(key, value.isUtc ? value.millisecondsSinceEpoch : value.toUtc().millisecondsSinceEpoch);

  @override
  Future<Duration?> getDuration(String key) async {
    final value = await getInt(key);
    if (value == null) return null;
    return Duration(milliseconds: value);
  }

  @override
  Future<void> setDuration(String key, Duration value) => setInt(key, value.inMilliseconds);
}

mixin GenericStorageOperationsMixin implements StorageOperationsApi {
  @override
  Future<bool> get isEmpty async {
    final keys = await getKeys();
    return keys.isEmpty;
  }

  @override
  Future<bool> get isNotEmpty async {
    final keys = await getKeys();
    return keys.isNotEmpty;
  }

  @override
  Future<E?> get<E>(String key) async {
    return switch (E) {
      const (String) => getString(key) as E?,
      const (int) => getInt(key) as E?,
      const (double) => getDouble(key) as E?,
      const (bool) => getBool(key) as E?,
      const (DateTime) => getDateTime(key) as E?,
      const (Duration) => getDuration(key) as E?,
      const (List<String>) => getStringList(key) as E?,
      const (Map<String, dynamic>) => getJson(key) as E?,
      const (List<Map<String, dynamic>>) => getJsonList(key) as E?,
      _ => throw UnsupportedError('Type $E is not supported'),
    };
  }

  @override
  Future<void> set<E>(String key, E value) async {
    await switch (value) {
      String value => setString(key, value),
      int value => setInt(key, value),
      double value => setDouble(key, value),
      bool value => setBool(key, value),
      DateTime value => setDateTime(key, value),
      Duration value => setDuration(key, value),
      List<String> value => setStringList(key, value),
      Map<String, dynamic> value => setJson(key, value),
      List<Map<String, dynamic>> value => setJsonList(key, value),
      _ => throw UnsupportedError('Type ${value.runtimeType} is not supported'),
    };
  }
}

// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'api/backend.dart';
import 'hyper_storage_container.dart';

/// A volatile storage backend that stores all data in memory.
///
/// [InMemoryBackend] implements the [StorageBackend] interface using a simple
/// [Map] for data storage. All operations are synchronous in nature but wrapped
/// in [Future]s to match the backend interface contract.
class InMemoryBackend extends StorageBackend {
  /// The internal map that stores all data.
  ///
  /// Keys are strings (storage keys), and values can be any type supported
  /// by the storage operations (String, int, bool, double, DateTime, Duration,
  /// Map, List).
  final Map<String, dynamic> _data;

  /// Creates a new empty [InMemoryBackend].
  ///
  /// The backend starts with no data and is ready to use immediately without
  /// requiring initialization (though calling [init] is still supported for
  /// interface compatibility).
  InMemoryBackend() : _data = {};

  /// Creates a new [InMemoryBackend] pre-populated with initial data.
  ///
  /// This constructor is particularly useful for testing scenarios where you
  /// want to start with a known data state. The [initialData] map is copied,
  /// so modifications to the backend won't affect the original map.
  ///
  /// Parameters:
  ///   * [initialData] - Optional map of initial key-value pairs. The map is
  ///     shallow-copied into the backend. Keys should be strings, and values
  ///     should be types supported by the storage operations.
  InMemoryBackend.withData({Map<String, dynamic>? initialData}) : _data = {...?initialData};

  @override
  Future<InMemoryBackend> init() async => this;

  @override
  Future<HyperStorageContainer> container(String name) async {
    final backend = InMemoryBackend();
    await backend.init();
    return HyperStorageContainer(backend: backend, name: name);
  }

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;

  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<void> setDouble(String key, double value) async => _data[key] = value;

  @override
  Future<double?> getDouble(String key) async => _data[key] as double?;

  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;

  @override
  Future<int?> getInt(String key) async => _data[key] as int?;

  @override
  Future<void> setAll(Map<String, dynamic> values) async => _data.addAll(values);

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    if (allowList != null) {
      if (allowList.isEmpty) return {};
      final data = <String, dynamic>{..._data};
      data.removeWhere((key, value) => !allowList.contains(key));
      return data;
    }
    return <String, dynamic>{..._data};
  }

  @override
  Future<Set<String>> getKeys() async => _data.keys.toSet();

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> close() async => _data.clear();

  @override
  Future<void> removeAll(Iterable<String> key) {
    for (final k in key) {
      _data.remove(k);
    }
    return Future.value();
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    final dateTime = _data[key] as DateTime?;
    if (dateTime == null) return null;
    return isUtc ? dateTime.toUtc() : dateTime.toLocal();
  }

  @override
  Future<Duration?> getDuration(String key) async => _data[key] as Duration?;

  @override
  Future<Map<String, dynamic>?> getJson(String key) async => _data[key] as Map<String, dynamic>?;

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final value = _data[key];
    if (value == null) return null;
    if (value is! List) return null;
    return List<Map<String, dynamic>>.from(value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _data[key];
    if (value == null) return null;
    if (value is! List) return null;
    return List<String>.from(value);
  }

  @override
  Future<bool> get isEmpty => Future.value(_data.isEmpty);

  @override
  Future<bool> get isNotEmpty => Future.value(_data.isNotEmpty);

  @override
  Future<void> setDateTime(String key, DateTime value) async => _data[key] = value;

  @override
  Future<void> setDuration(String key, Duration value) async => _data[key] = value;

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async => _data[key] = value;

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async => _data[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async => _data[key] = value;
}

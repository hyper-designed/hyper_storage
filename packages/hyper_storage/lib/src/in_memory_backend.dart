import 'package:meta/meta.dart';

import 'api/backend.dart';
import 'hyper_storage_container.dart';

class InMemoryBackend extends StorageBackend {
  final Map<String, dynamic> _data;

  /// In memory storage backend for testing or temporary storage.
  InMemoryBackend() : _data = {};

  @visibleForTesting
  InMemoryBackend.mocked({Map<String, dynamic>? initialData}) : _data = {...?initialData};

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
    final data = <String, dynamic>{..._data};
    if (allowList != null && allowList.isNotEmpty) {
      data.removeWhere((key, value) => !allowList.contains(key));
    }
    return data;
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
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) => _data[key];

  @override
  Future<Duration?> getDuration(String key) => _data[key];

  @override
  Future<Map<String, dynamic>?> getJson(String key) => _data[key];

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) => _data[key];

  @override
  Future<List<String>?> getStringList(String key) => _data[key];

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

import 'package:hive_ce/hive.dart';
import 'package:hyper_storage/hyper_storage.dart';

class HiveBackend extends StorageBackend {
  final String name;

  Box? _box;

  Box get box {
    return _box ??
        (throw StateError('HiveBackend not initialized. Call init() first.'));
  }

  /// Hive backend for local storage, using Hive as the underlying storage mechanism.
  /// [name] is used for opening a box with that name.
  HiveBackend({String? boxName}) : name = boxName ?? '';

  @override
  Future<HiveBackend> init() async {
    _box ??= await Hive.openBox<String>(name);
    return this;
  }

  @override
  Future<HyperStorageContainer> container(String name) async {
    final backend = HiveBackend(boxName: name);
    await backend.init();
    return HyperStorageContainer(backend: backend, name: name);
  }

  @override
  Future<void> setString(String key, String value) => box.put(key, value);

  @override
  Future<String?> getString(String key) => box.get(key);

  @override
  Future<void> setBool(String key, bool value) => box.put(key, value);

  @override
  Future<bool?> getBool(String key) => box.get(key);

  @override
  Future<void> setDouble(String key, double value) => box.put(key, value);

  @override
  Future<double?> getDouble(String key) => box.get(key);

  @override
  Future<void> setInt(String key, int value) => box.put(key, value);

  @override
  Future<int?> getInt(String key) => box.get(key);

  @override
  Future<void> setAll(Map<String, dynamic> values) => box.putAll(values);

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    final data = <String, dynamic>{...box.toMap()};
    if (allowList != null && allowList.isNotEmpty) {
      data.removeWhere((key, value) => !allowList.contains(key));
    }
    return data;
  }

  @override
  Future<Set<String>> getKeys() async =>
      box.keys.map((key) => key.toString()).toSet();

  @override
  Future<void> remove(String key) => box.delete(key);

  @override
  Future<void> removeAll(Iterable<String> keys) async =>
      await box.deleteAll(keys);

  @override
  Future<void> clear() => box.clear();

  @override
  Future<bool> containsKey(String key) async => box.containsKey(key);

  @override
  Future<void> close() async {
    await box.close();
    _box = null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../backend/api.dart';
import '../backend/listenable.dart';
import '../generate_id.dart';
import 'storage_container_base.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T object);
typedef IdGetter<T> = String Function(T object);

class SerializableStorageContainer<T> extends StorageContainerBase with ListenableStorage {
  final ToJson<T> toJson;
  final FromJson<T> fromJson;
  final IdGetter<T>? idGetter;

  late final _random = Random(backend.hashCode);

  SerializableStorageContainer({
    required super.backend,
    required this.toJson,
    required this.fromJson,
    this.idGetter,
    required super.name,
  });

  Future<bool> get isEmpty => getKeys().then((keys) => keys.isEmpty);

  Future<bool> get isNotEmpty => getKeys().then((keys) => keys.isNotEmpty);

  Future<void> set(String key, T value) async {
    final String jsonString = jsonEncode(toJson(value));
    await backend.setString(encodeKey(key), jsonString);
    notifyListeners(key);
  }

  String _idFor(T value) => idGetter?.call(value) ?? generateId(_random);

  Future<void> setAll(Map<String, T> items) async {
    await backend.setAll(items.map((key, value) => MapEntry(encodeKey(key), jsonEncode(toJson(value)))));
    for (final key in items.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  Future<void> add(T value) => set(_idFor(value), value);

  Future<void> addAll(Iterable<T> values) async {
    final Map<String, T> items = <String, T>{for (final value in values) _idFor(value): value};
    await setAll(items);
  }

  Future<void> update(T value) async {
    final String id = _idFor(value);
    if (await containsKey(id)) {
      await set(id, value);
    } else {
      throw StateError('Item with id $id does not exist and cannot be updated.');
    }
  }

  Future<void> updateAll(Iterable<T> values) async {
    final Map<String, T> items = <String, T>{};
    for (final value in values) {
      final String id = _idFor(value);
      if (await containsKey(id)) {
        items[id] = value;
      } else {
        throw StateError('Item with id $id does not exist and cannot be updated.');
      }
    }
    await setAll(items);
  }

  Future<T?> get(String? key) async {
    if (key == null) return null;
    if (!await containsKey(key)) return null;
    final String? jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return fromJson(json);
  }

  Future<Map<String, T>> getAll([Iterable<String>? allowList]) async {
    final Map<String, dynamic> allData = await backend.getAll(allowList?.map(encodeKey) ?? await getEncodedKeys());
    return <String, T>{
      for (final MapEntry(:key, :value) in allData.entries) decodeKey(key): fromJson(jsonDecode(value)),
    };
  }

  Future<List<T>> getValues() async {
    final allData = await getAll();
    return allData.values.toList();
  }

  @override
  Future<bool> containsKey(String key) async => backend.containsKey(encodeKey(key));

  @override
  Future<void> clear() async {
    final encodedKeys = await getEncodedKeys();
    await backend.removeAll(encodedKeys);

    final decodedKeys = encodedKeys.map(decodeKey);
    for (final key in decodedKeys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
    removeAllListeners();
  }

  @override
  Future<void> close() async {
    removeAllListeners();
    await backend.close();
  }

  @override
  Future<Set<String>> getKeys() => getDecodedKeys();

  @override
  Future<void> remove(String key) async {
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  Future<void> removeItem(T item) async {
    final String key = _idFor(item);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  Future<void> removeAllItems(Iterable<T> items) async {
    final keys = items.map(_idFor);
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }
}

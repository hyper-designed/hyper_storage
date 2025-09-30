import 'dart:math';

import 'package:meta/meta.dart';

import '../generate_id.dart' as generator;
import 'api.dart';
import 'storage_container.dart';

typedef IdGetter<E> = String Function(E object);

abstract class SerializableStorageContainer<E> extends StorageContainer implements SerializableStorageOperationsApi<E> {
  final IdGetter<E>? idGetter;

  final Random _random;

  SerializableStorageContainer({
    this.idGetter,
    required super.backend,
    required super.name,
    super.delimiter,
    Random? random,
    int? seed,
  }) : _random = random ?? Random(seed ?? backend.hashCode);

  @protected
  @override
  String serialize(E value);

  @protected
  @override
  E deserialize(String value);

  @protected
  @override
  String generateId() => generator.generateId(_random);

  @protected
  @override
  String getId(E value) => idGetter?.call(value) ?? generateId();

  @override
  Future<void> set(String key, E value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), serialize(value));
    notifyListeners(key);
  }

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
  Future<void> setAll(Map<String, E> items) async {
    validateKeys(items.keys);
    await backend.setAll(items.map((key, value) => MapEntry(encodeKey(key), serialize(value))));
    for (final key in items.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> add(E value) => set(getId(value), value);

  @override
  Future<void> addAll(Iterable<E> values) async {
    final Map<String, E> items = <String, E>{for (final value in values) getId(value): value};
    await setAll(items);
  }

  @override
  Future<void> update(E value) async {
    final String id = getId(value);
    if (await containsKey(id)) {
      await set(id, value);
    } else {
      throw StateError('Item with id $id does not exist and cannot be updated.');
    }
  }

  @override
  Future<void> updateAll(Iterable<E> values) async {
    final Map<String, E> items = <String, E>{};
    for (final value in values) {
      final String id = getId(value);
      if (await containsKey(id)) {
        items[id] = value;
      } else {
        throw StateError('Item with id $id does not exist and cannot be updated.');
      }
    }
    await setAll(items);
  }

  @override
  Future<E?> get(String? key) async {
    if (key == null) return null;
    validateKey(key);
    if (!await containsKey(key)) return null;
    final String? value = await backend.getString(encodeKey(key));
    if (value == null) return null;
    return deserialize(value);
  }

  @override
  Future<Map<String, E>> getAll([Iterable<String>? allowList]) async {
    validateKeys(allowList);
    final Map<String, dynamic> allData = await backend.getAll(allowList?.map(encodeKey) ?? await getEncodedKeys());
    return <String, E>{
      for (final MapEntry(:key, :value) in allData.entries) decodeKey(key): deserialize(value.toString()),
    };
  }

  @override
  Future<List<E>> getValues() async {
    final allData = await getAll();
    return allData.values.toList();
  }

  @override
  Future<bool> containsKey(String key) async {
    validateKey(key);
    return backend.containsKey(encodeKey(key));
  }

  @override
  Future<Set<String>> getKeys() => getDecodedKeys();

  @override
  Future<void> remove(String key) async {
    validateKey(key);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  @override
  Future<void> removeItem(E item) async {
    final String key = getId(item);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    validateKeys(keys);
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> removeAllItems(Iterable<E> items) async {
    final keys = items.map(getId);
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

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
}

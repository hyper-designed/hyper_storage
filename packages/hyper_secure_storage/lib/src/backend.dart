import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hyper_storage/hyper_storage.dart';

class SecureStorageBackend extends StorageBackend {
  final FlutterSecureStorage storage;

  SecureStorageBackend({String name = '', FlutterSecureStorage? storage})
    : storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(encryptedSharedPreferences: true),
            iOptions: const IOSOptions(
              accessibility: KeychainAccessibility.unlocked,
            ),
          );

  @override
  Future<void> init() async {}

  @override
  Future<HyperStorageContainer> container(String name) async =>
      HyperStorageContainer(backend: this, name: name);

  @override
  Future<void> setString(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<String?> getString(String key) => storage.read(key: key);

  @override
  Future<void> setBool(String key, bool value) =>
      storage.write(key: key, value: value.toString());

  @override
  Future<bool?> getBool(String key) async =>
      bool.tryParse(await storage.read(key: key) ?? '');

  @override
  Future<void> setDouble(String key, double value) =>
      storage.write(key: key, value: value.toString());

  @override
  Future<double?> getDouble(String key) async =>
      double.tryParse(await storage.read(key: key) ?? '');

  @override
  Future<void> setInt(String key, int value) =>
      storage.write(key: key, value: value.toString());

  @override
  Future<int?> getInt(String key) async =>
      int.tryParse(await storage.read(key: key) ?? '');

  Future<void> setStringList(String key, List<String> value) =>
      storage.write(key: key, value: jsonEncode(value));

  Future<List<String>?> getStringList(String key) async {
    final value = await storage.read(key: key);
    if (value == null) return null;
    return List<String>.from(jsonDecode(value));
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    for (final MapEntry(:key, :value) in values.entries) {
      final encodedKey = key;
      await switch (value) {
        String value => storage.write(key: encodedKey, value: value),
        int value => storage.write(key: encodedKey, value: value.toString()),
        double value => storage.write(key: encodedKey, value: value.toString()),
        bool value => storage.write(key: encodedKey, value: value.toString()),
        List<String> value => storage.write(
          key: encodedKey,
          value: jsonEncode(value),
        ),
        _ => throw ArgumentError(
          'Unsupported value type: ${value.runtimeType}',
        ),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    // decoded keys associated with this container.
    final all = await storage.readAll();
    final Map<String, dynamic> data = {};
    for (final entry in all.entries) {
      final key = entry.key;
      if (allowList != null &&
          allowList.isNotEmpty &&
          !allowList.contains(key)) {
        continue;
      }
      final value = entry.value;
      data[key] = _parseValue(value);
    }
    return data;
  }

  Object? _parseValue(String value) =>
      bool.tryParse(value) ??
      int.tryParse(value) ??
      double.tryParse(value) ??
      _tryJsonDecode(value) ??
      value;

  @override
  Future<Set<String>> getKeys() async {
    final all = await storage.readAll();
    return all.keys.toSet();
  }

  @override
  Future<void> remove(String key) => storage.delete(key: key);

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    final List<Future> futures = keys.map((key) => remove(key)).toList();
    await Future.wait(futures);
  }

  @override
  Future<void> clear() => storage.deleteAll();

  @override
  Future<bool> containsKey(String key) => storage.containsKey(key: key);

  @override
  Future<void> close() async {
    // Nothing to close
  }
}

Object? _tryJsonDecode(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

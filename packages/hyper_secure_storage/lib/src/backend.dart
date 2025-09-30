import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hyper_storage/hyper_storage.dart';

import 'utils.dart';

class SecureStorageBackend extends StorageBackend {
  final FlutterSecureStorage storage;

  SecureStorageBackend({FlutterSecureStorage? storage})
    : storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(encryptedSharedPreferences: true),
            iOptions: const IOSOptions(accessibility: KeychainAccessibility.unlocked),
          );

  @override
  Future<void> init() async {}

  @override
  Future<void> setString(String key, String value) => storage.write(key: key, value: value);

  @override
  Future<String?> getString(String key) => storage.read(key: key);

  @override
  Future<void> setBool(String key, bool value) => storage.write(key: key, value: value.toString());

  @override
  Future<bool?> getBool(String key) async => bool.tryParse(await storage.read(key: key) ?? '');

  @override
  Future<void> setDouble(String key, double value) => storage.write(key: key, value: value.toString());

  @override
  Future<double?> getDouble(String key) async => double.tryParse(await storage.read(key: key) ?? '');

  @override
  Future<void> setInt(String key, int value) => storage.write(key: key, value: value.toString());

  @override
  Future<int?> getInt(String key) async => int.tryParse(await storage.read(key: key) ?? '');

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    // decoded keys associated with this container.
    final Map<String, String> all = await storage.readAll();
    final Map<String, dynamic> data = {};
    for (final MapEntry(:key, :value) in all.entries) {
      if (allowList != null && allowList.isNotEmpty && !allowList.contains(key)) {
        continue;
      }
      data[key] = _parseValue(value);
    }
    return data;
  }

  Object? _parseValue(String value) =>
      bool.tryParse(value) ?? int.tryParse(value) ?? double.tryParse(value) ?? tryJsonDecode(value) ?? value;

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
  Future<bool> containsKey(String key) => storage.containsKey(key: key);

  @override
  Future<void> clear() => storage.deleteAll();

  @override
  Future<void> close() async {
    // Nothing to close
  }
}

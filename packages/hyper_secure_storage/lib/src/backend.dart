import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hyper_storage/hyper_storage.dart';

import 'utils.dart';

/// A secure storage backend implementation that leverages platform-specific
/// secure storage mechanisms to protect sensitive data.
class SecureStorageBackend extends StorageBackend {
  /// The underlying [FlutterSecureStorage] instance that handles platform-specific
  /// secure storage operations.
  ///
  /// This instance is configured with platform-specific options for optimal
  /// security on each supported platform.
  final FlutterSecureStorage storage;

  /// Creates a new [SecureStorageBackend] with optional custom storage configuration.
  ///
  /// Parameters:
  ///   * [storage] - Optional custom [FlutterSecureStorage] instance. If not
  ///     provided, a default instance will be created with security-optimized
  ///     settings for each platform.
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

  /// Parses a string value to its most appropriate type.
  ///
  /// Attempts to parse the value as boolean, integer, double, JSON, or
  /// returns the original string if none of these apply.
  ///
  /// Parameters:
  ///   * [value] - The string value to parse.
  ///
  /// Returns the parsed value in priority order:
  /// 1. [bool] if the value is "true" or "false" (case-insensitive)
  /// 2. [int] if the value is a valid integer
  /// 3. [double] if the value is a valid decimal number
  /// 4. [Map] or [List] if the value is valid JSON
  /// 5. [String] as fallback for all other cases
  ///
  /// This is an internal utility method used by [getAll] for automatic type
  /// inference.
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

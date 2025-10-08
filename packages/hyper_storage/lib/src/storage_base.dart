// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

part of 'hyper_storage.dart';

/// An internal base class that implements storage operations with validation and listener support.
///
/// [_HyperStorageImpl] provides the foundational implementation of
/// [StorageOperationsApi] with automatic key validation and change notifications.
/// This class serves as the base for [HyperStorage], delegating actual storage
/// operations to a [StorageBackend] while handling cross-cutting concerns like
/// validation and event notifications.
abstract class _HyperStorageImpl extends BaseStorage
    with ItemHolderMixin, GenericStorageOperationsMixin
    implements StorageOperationsApi {
  /// Creates a new [_HyperStorageImpl] with the specified backend.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend to delegate operations to. This
  ///     backend should already be initialized before creating this instance.
  _HyperStorageImpl({required super.backend});

  @internal
  @protected
  @override
  void validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('Key cannot be empty');
    if (key.trim().isEmpty) throw ArgumentError('Key cannot be only whitespace');
  }

  @internal
  @protected
  @override
  @visibleForTesting
  String encodeKey(String key) => key;

  /// Validates that all keys in a collection are acceptable for storage operations.
  ///
  /// This method validates multiple keys using [validateKey]. If the iterable
  /// is null or empty, no validation is performed (this is not an error). If
  /// any key in the iterable fails validation, an [ArgumentError] is thrown.
  ///
  /// Parameters:
  ///   * [keys] - Optional iterable of keys to validate. Can be null or empty.
  ///
  /// Throws:
  ///   * [ArgumentError] if any key is empty or consists only of whitespace.
  ///
  /// Example:
  /// ```dart
  /// _validateKeys(['key1', 'key2']);       // OK
  /// _validateKeys(null);                   // OK - no validation needed
  /// _validateKeys([]);                     // OK - no validation needed
  /// _validateKeys(['valid', '']);          // Throws ArgumentError
  /// _validateKeys(['valid', '   ']);       // Throws ArgumentError
  /// ```
  void _validateKeys(Iterable<String>? keys) {
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      validateKey(key);
    }
  }

  @override
  Future<bool> containsKey(String key) {
    validateKey(key);
    return backend.containsKey(key);
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    _validateKeys(allowList);
    if (allowList != null && allowList.isEmpty) return Future.value(<String, dynamic>{});
    return backend.getAll(allowList?.toSet() ?? await getKeys());
  }

  @override
  Future<bool?> getBool(String key) {
    validateKey(key);
    return backend.getBool(key);
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) {
    validateKey(key);
    return backend.getDateTime(key, isUtc: isUtc);
  }

  @override
  Future<double?> getDouble(String key) {
    validateKey(key);
    return backend.getDouble(key);
  }

  @override
  Future<Duration?> getDuration(String key) {
    validateKey(key);
    return backend.getDuration(key);
  }

  @override
  Future<int?> getInt(String key) {
    validateKey(key);
    return backend.getInt(key);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) {
    validateKey(key);
    return backend.getJson(key);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) {
    validateKey(key);
    return backend.getJsonList(key);
  }

  @override
  Future<Set<String>> getKeys() => backend.getKeys();

  @override
  Future<String?> getString(String key) {
    validateKey(key);
    return backend.getString(key);
  }

  @override
  Future<List<String>?> getStringList(String key) {
    validateKey(key);
    return backend.getStringList(key);
  }

  @override
  Future<bool> get isEmpty => backend.isEmpty;

  @override
  Future<bool> get isNotEmpty => backend.isNotEmpty;

  @override
  Future<void> remove(String key) async {
    validateKey(key);
    await backend.remove(key);
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    _validateKeys(keys);
    await backend.removeAll(keys);
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    _validateKeys(values.keys);
    await backend.setAll(values);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setBool(String key, bool value) async {
    validateKey(key);
    await backend.setBool(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    validateKey(key);
    await backend.setDateTime(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    validateKey(key);
    await backend.setDouble(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    validateKey(key);
    await backend.setDuration(key, value);
    notifyListeners(key);
  }

  @override
  Future<E?> getEnum<E extends Enum>(String key, List<E> values) async {
    validateKey(key);
    final String? enumName = await backend.getString(key);
    if (enumName == null) return null;
    for (final enumValue in values) {
      if (enumValue.name == enumName) return enumValue;
    }
    return null;
  }

  @override
  Future<void> setEnum<E extends Enum>(String key, E value) async {
    validateKey(key);
    await backend.setString(key, value.name);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    validateKey(key);
    await backend.setInt(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    validateKey(key);
    await backend.setJson(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    validateKey(key);
    await backend.setJsonList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    validateKey(key);
    await backend.setString(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    validateKey(key);
    await backend.setStringList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setBytes(String key, Uint8List bytes) async {
    validateKey(key);
    await backend.setString(key, base64Encode(bytes));
    notifyListeners(key);
  }

  @override
  Future<Uint8List?> getBytes(String key) async {
    validateKey(key);
    final String? base64String = await backend.getString(key);
    if (base64String == null) return null;
    return base64Decode(base64String);
  }
}

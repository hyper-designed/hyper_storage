// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart' show protected;

import '../hyper_storage.dart';
import 'api/backend.dart';
import 'api/storage_container.dart';
import 'utils.dart';

/// A concrete implementation of [StorageContainer] for storing key-value pairs.
///
/// [HyperStorageContainer] provides a complete, production-ready implementation
/// of the storage container API. It handles all primitive data types,
/// collections, and special types like [DateTime] and [Duration]. The container
/// manages key encoding/decoding, notification of listeners, and validation of
/// all operations.
///
/// ## Key Validation
///
/// All keys are validated before operations:
/// - Keys cannot be empty
/// - Keys cannot contain only whitespace
/// - Keys are checked by [validateKey] before any operation
///
/// See also:
/// - [StorageContainer] for the base class and abstract interface
/// {@category Containers}
final class HyperStorageContainer extends StorageContainer with ItemHolderMixin, GenericStorageOperationsMixin {
  /// Creates a new [HyperStorageContainer] instance.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend that handles actual persistence.
  ///   * [name] - The name of the container, used as a prefix for all keys.
  ///   * [delimiter] - Optional. The character(s) used to separate the
  ///     container name from keys. If not provided, uses the default delimiter.
  @protected
  HyperStorageContainer({
    required super.backend,
    required super.name,
    super.delimiter,
  });

  @override
  Future<Set<String>> getKeys() => getDecodedKeys();

  @override
  Future<void> remove(String key) async {
    validateKey(key);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  @override
  Future<bool> containsKey(String key) {
    validateKey(key);
    return backend.containsKey(encodeKey(key));
  }

  @override
  Future<String?> getString(String key) {
    validateKey(key);
    return backend.getString(encodeKey(key));
  }

  @override
  Future<int?> getInt(String key) {
    validateKey(key);
    return backend.getInt(encodeKey(key));
  }

  @override
  Future<double?> getDouble(String key) {
    validateKey(key);
    return backend.getDouble(encodeKey(key));
  }

  @override
  Future<bool?> getBool(String key) {
    validateKey(key);
    return backend.getBool(encodeKey(key));
  }

  @override
  Future<void> setString(String key, String value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    validateKey(key);
    await backend.setInt(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    validateKey(key);
    await backend.setDouble(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    validateKey(key);
    await backend.setBool(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    validateKeys(allowList);
    final keys = allowList?.map(encodeKey).toSet() ?? await getEncodedKeys();
    if (keys.isEmpty) return {};
    final map = await backend.getAll(keys);
    return {for (final entry in map.entries) decodeKey(entry.key): entry.value};
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    validateKeys(values.keys);
    final mapWithEncodedKeys = {
      for (final entry in values.entries) encodeKey(entry.key): entry.value,
    };
    await backend.setAll(mapWithEncodedKeys);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    validateKey(key);
    final String? dataString = await backend.getString(encodeKey(key));
    if (dataString == null) return null;
    return List<String>.from(jsonDecode(dataString) as List<dynamic>);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    validateKey(key);
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    validateKey(key);
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    validateKey(key);
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return null;
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return isUtc ? dateTime : dateTime.toLocal();
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    validateKey(key);
    await backend.setInt(
      encodeKey(key),
      value.isUtc ? value.millisecondsSinceEpoch : value.toUtc().millisecondsSinceEpoch,
    );
    notifyListeners(key);
  }

  @override
  Future<Duration?> getDuration(String key) async {
    validateKey(key);
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return null;
    return Duration(milliseconds: millis);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    validateKey(key);
    await backend.setInt(encodeKey(key), value.inMilliseconds);
    notifyListeners(key);
  }

  @override
  Future<E?> getEnum<E extends Enum>(String key, List<E> values) async {
    validateKey(key);
    final String? enumName = await backend.getString(encodeKey(key));
    if (enumName == null) return null;
    for (final enumValue in values) {
      if (enumValue.name == enumName) return enumValue;
    }
    return null;
  }

  @override
  Future<void> setEnum<E extends Enum>(String key, E value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), value.name);
    notifyListeners(key);
  }

  @override
  Future<Uint8List?> getBytes(String key) async {
    validateKey(key);
    final value = await backend.getString(encodeKey(key));
    if (value == null) return null;
    return base64Decode(value);
  }

  @override
  Future<void> setBytes(String key, Uint8List bytes) {
    validateKey(key);
    return backend.setString(encodeKey(key), base64Encode(bytes));
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

  /// Provides a [Stream] of values for the given [key].
  /// The stream will emit the current value of the key and will update
  /// whenever the value changes.
  ///
  /// If an error occurs during value retrieval (either initial or on updates),
  /// the error will be emitted to the stream. Listeners should provide an
  /// [onError] callback to handle such errors gracefully.
  ///
  /// It is important to close the stream when it is no longer needed
  /// to avoid memory leaks. This can be done by cancelling the subscription
  /// to the stream.
  ///
  /// Note that only supported types are allowed for [E].
  /// Supported types are:
  ///   - String
  ///   - int
  ///   - double
  ///   - bool
  ///   - List of String
  ///   - JSON Map
  ///   - List of JSON Map
  ///   - DateTime
  ///   - Duration
  ///   - Uint8List
  ///   - Enum (requires providing [enumValues])
  Stream<E?> stream<E extends Object>(String key, {List<Enum>? enumValues}) async* {
    if (enumValues != null) checkEnumType<E>(enumValues);

    final controller = StreamController<E?>();

    Future<void> retrieveAndAdd() async {
      if (controller.isClosed) return;
      try {
        final E? value = await get<E>(key, enumValues: enumValues);
        if (!controller.isClosed) controller.add(value);
      } catch (error, stacktrace) {
        if (!controller.isClosed) controller.addError(error, stacktrace);
        return;
      }
    }

    addKeyListener(key, retrieveAndAdd);

    try {
      // Reads and emits the initial value.
      await retrieveAndAdd();
      yield* controller.stream;
    } finally {
      removeKeyListener(key, retrieveAndAdd);
      await controller.close();
    }
  }

  @override
  Future<void> close() async {
    removeAllListeners();
    await backend.close();
    await super.close();
  }

  @override
  Future<void> clear() async {
    final encodedKeys = await getEncodedKeys();
    final decodedKeys = encodedKeys.map(decodeKey).toList();
    await backend.removeAll(encodedKeys);
    for (final key in decodedKeys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
    removeAllListeners();
  }
}

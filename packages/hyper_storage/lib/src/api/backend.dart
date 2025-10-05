// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../hyper_storage_container.dart';
import '../utils.dart';
import 'api.dart';

/// An abstract class that defines the contract for a storage backend.
///
/// This class provides a base implementation for creating custom storage solutions
/// that can persist data to various storage mechanisms (files, databases, etc.).
/// It includes default implementations for common operations like handling JSON,
/// lists, and date/time objects, reducing the boilerplate needed when implementing
/// a new backend.
abstract class StorageBackend with GenericStorageOperationsMixin implements StorageOperationsApi {
  /// Initializes the storage backend.
  ///
  /// This method will be called before any other operations are performed on
  /// the storage backend. It provides an opportunity to set up necessary resources,
  /// open database connections, create files, or perform any other initialization
  /// logic required by the backend.
  ///
  /// The default implementation is a no-op, but subclasses can override this to
  /// perform custom initialization.
  ///
  /// Returns a [Future] that completes when initialization is finished.
  Future<void> init() async {}

  /// Creates a new [HyperStorageContainer] with the given [name].
  ///
  /// A container provides a sandboxed, namespaced environment for storing
  /// key-value pairs. Each container has its own isolated key space, allowing
  /// you to organize data into logical groups without key collisions.
  ///
  /// Parameters:
  /// * [name] - The unique name for the container. This is used to namespace
  ///   all keys within the container.
  ///
  /// Returns a [Future] that completes with a new [HyperStorageContainer]
  /// instance configured to use this backend.
  ///
  /// Throws:
  /// * [ArgumentError] if the name is empty, contains only whitespace, or
  ///   contains invalid characters.
  Future<HyperStorageContainer> container(String name) async => HyperStorageContainer(backend: this, name: name);

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
  Future<void> setAll(Map<String, dynamic> values) async {
    for (final MapEntry(:key, :value) in values.entries) {
      set(key, value);
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) => setString(key, jsonEncode(value));

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! List) return null;
    return List<String>.from(decoded);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) => setString(key, jsonEncode(value));

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) => setString(key, jsonEncode(value));

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    final decoded = tryJsonDecode(value);
    if (decoded is! List) return null;
    return List<Map<String, dynamic>>.from(decoded);
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    final value = await getInt(key);
    if (value == null) return null;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    if (isUtc) return dateTime;
    return dateTime.toLocal();
  }

  @override
  Future<void> setDateTime(String key, DateTime value) =>
      setInt(key, value.isUtc ? value.millisecondsSinceEpoch : value.toUtc().millisecondsSinceEpoch);

  @override
  Future<Duration?> getDuration(String key) async {
    final value = await getInt(key);
    if (value == null) return null;
    return Duration(milliseconds: value);
  }

  @override
  Future<void> setDuration(String key, Duration value) => setInt(key, value.inMilliseconds);
}

/// A mixin that provides generic implementations for storage operations.
///
/// This mixin implements the generic `get<E>` and `set<E>` methods that dispatch
/// to the appropriate type-specific methods based on the runtime type.
///
/// This mixin reduces the amount of boilerplate code required when implementing
/// a storage backend by providing type-aware routing logic.
///
/// Supported types:
/// * [String] - Routes to [getString] / [setString]
/// * [int] - Routes to [getInt] / [setInt]
/// * [double] - Routes to [getDouble] / [setDouble]
/// * [bool] - Routes to [getBool] / [setBool]
/// * [DateTime] - Routes to [getDateTime] / [setDateTime]
/// * [Duration] - Routes to [getDuration] / [setDuration]
/// * [List<String>] - Routes to [getStringList] / [setStringList]
/// * [Map<String, dynamic>] - Routes to [getJson] / [setJson]
/// * [List<Map<String, dynamic>>] - Routes to [getJsonList] / [setJsonList]
@internal
mixin GenericStorageOperationsMixin implements StorageOperationsApi {
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
  Future<E?> get<E extends Object>(String key) async {
    return switch (E) {
      const (String) => await getString(key) as E?,
      const (int) => await getInt(key) as E?,
      const (double) => await getDouble(key) as E?,
      const (bool) => await getBool(key) as E?,
      const (DateTime) => await getDateTime(key) as E?,
      const (Duration) => await getDuration(key) as E?,
      const (List<String>) => await getStringList(key) as E?,
      const (Map<String, dynamic>) => await getJson(key) as E?,
      const (List<Map<String, dynamic>>) => await getJsonList(key) as E?,
      _ => throw UnsupportedError('Type $E is not supported'),
    };
  }

  @override
  Future<void> set<E extends Object>(String key, E value) async {
    await switch (value) {
      String value => setString(key, value),
      int value => setInt(key, value),
      double value => setDouble(key, value),
      bool value => setBool(key, value),
      DateTime value => setDateTime(key, value),
      Duration value => setDuration(key, value),
      List<String> value => setStringList(key, value),
      Map<String, dynamic> value => setJson(key, value),
      List<Map<String, dynamic>> value => setJsonList(key, value),
      _ => throw UnsupportedError('Type ${value.runtimeType} is not supported'),
    };
  }
}

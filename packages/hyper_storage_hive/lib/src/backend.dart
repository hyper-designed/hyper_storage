// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'package:hive_ce/hive.dart';
import 'package:hyper_storage/hyper_storage.dart';

/// A [StorageBackend] implementation using Hive for persistent key-value storage.
///
/// See also:
///   [LazyHiveBackend]: A variant that uses Hive's lazy boxes for on-demand loading.
class HiveBackend extends StorageBackend {
  /// The name of the Hive box used by this backend.
  ///
  /// This name determines which Hive box file will be used for storage.
  /// 'default' represents the default unnamed box. Each unique
  /// name creates a separate, isolated storage space on disk.
  final String name;

  Box? _box;

  /// The active Hive [Box] instance used for storage operations.
  Box get box => _box ?? (throw StateError('HiveBackend not initialized. Call init() first.'));

  /// Creates a new [HiveBackend] instance with optional named box support.
  ///
  /// The backend can operate on either the default Hive box or a
  /// specifically named box for isolated storage. Named boxes are useful
  /// for organizing data into logical groups or creating separate storage
  /// spaces for different parts of your application.
  ///
  /// Parameters:
  /// * [boxName] - Optional name for the Hive box. If not provided or null,
  ///   'default' is used, representing the default box.
  ///   Valid box names can contain letters, numbers, and underscores.
  ///
  /// Note: The backend is not usable until [init] is called. Creating the
  /// instance only stores the configuration; the box is opened lazily.
  HiveBackend({String? boxName}) : name = boxName ?? 'default' {
    if (boxName?.toLowerCase() == 'default') {
      throw ArgumentError('boxName cannot be "default". Use null or omit to use the default box.');
    }
  }

  @override
  Future<void> init() async => _box ??= await Hive.openBox(name);

  @override
  Future<HyperStorageContainer> container(String name, {String? delimiter}) async {
    final backend = HiveBackend(boxName: name);
    await backend.init();
    return HyperStorageContainer(backend: backend, name: name, delimiter: delimiter);
  }

  @override
  Future<void> setString(String key, String value) => box.put(key, value);

  @override
  Future<String?> getString(String key) async => box.get(key);

  @override
  Future<void> setBool(String key, bool value) => box.put(key, value);

  @override
  Future<bool?> getBool(String key) async => box.get(key);

  @override
  Future<void> setDouble(String key, double value) => box.put(key, value);

  @override
  Future<double?> getDouble(String key) async => box.get(key);

  @override
  Future<void> setInt(String key, int value) => box.put(key, value);

  @override
  Future<int?> getInt(String key) async => await box.get(key);

  @override
  Future<Map<String, dynamic>> getAll(Set<String> allowList) async {
    final data = <String, dynamic>{...box.toMap()};
    if (allowList.isEmpty) return {};
    return data..removeWhere((key, value) => !allowList.contains(key));
  }

  @override
  Future<Set<String>> getKeys() async => box.keys.map((key) => key.toString()).toSet();

  @override
  Future<void> remove(String key) => box.delete(key);

  @override
  Future<void> removeAll(Iterable<String> keys) => box.deleteAll(keys);

  @override
  Future<bool> containsKey(String key) async => box.containsKey(key);

  @override
  Future<void> clear() => Hive.deleteFromDisk();

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

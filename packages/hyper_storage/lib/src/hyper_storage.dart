import 'dart:math';

import 'package:meta/meta.dart';

import 'api/api.dart';
import 'api/backend.dart';
import 'api/serializable_container.dart';
import 'api/storage_container.dart';
import 'in_memory_backend.dart';
import 'json_storage_container.dart';

part 'storage_base.dart';

class HyperStorage extends _StorageBase {
  final Map<String, StorageContainer> _containers = {};
  final Map<String, SerializableStorageContainer> _objectContainers = {};

  HyperStorage._(super.backend);

  static HyperStorage? _instance;

  static HyperStorage get instance {
    if (_instance == null) throw StateError('LocalStorage not initialized. Call LocalStorage.init() first.');
    return _instance!;
  }

  static Future<HyperStorage> init({required StorageBackend backend}) async {
    await backend.init();
    _instance = HyperStorage._(backend);
    return _instance!;
  }

  /// Uses in-memory backend which is easier to test.
  @visibleForTesting
  static Future<HyperStorage> initMocked({Map<String, dynamic>? initialData}) async {
    // ignore: invalid_use_of_visible_for_testing_member
    final backend = InMemoryBackend.mocked(initialData: initialData);
    await backend.init();
    final HyperStorage storage = HyperStorage._(backend);
    return storage;
  }

  static Future<StorageContainer> container(String name) async {
    if (instance._containers.containsKey(name)) return instance._containers[name]!;
    return await instance.backend.container(name);
  }

  static Future<JsonStorageContainer<E>> jsonContainer<E>(
    String name, {
    required ToJson<E> toJson,
    required FromJson<E> fromJson,
    IdGetter<E>? idGetter,
    Random? random,
    int? seed,
    String? delimiter,
  }) async {
    if (instance._containers.containsKey(name)) {
      if (instance._containers[name] case JsonStorageContainer<E> container) return container;

      throw StateError('Container with name $name already exists with different type.');
    }
    final container = JsonStorageContainer<E>(
      backend: instance.backend,
      name: name,
      fromJson: fromJson,
      toJson: toJson,
      idGetter: idGetter,
      delimiter: delimiter,
      random: random,
      seed: seed,
    );
    return instance._objectContainers[name] = container;
  }

  static Future<F> objectContainer<E, F extends SerializableStorageContainer<E>>(
    String name, {
    required F Function() factory,
  }) async {
    if (instance._containers.containsKey(name)) {
      if (instance._containers[name] case F container) return container;
      throw StateError('Container with name $name already exists with different type.');
    }
    final F container = factory();
    return instance._objectContainers[name] = container;
  }

  /// Closes all containers and the backend.
  @override
  Future<void> close() async {
    final List<Future<void>> futures = [
      for (final storage in _containers.values) storage.close(),
      for (final storage in _objectContainers.values) storage.close(),
    ];
    await Future.wait(futures);

    _containers.clear();
    _objectContainers.clear();

    _instance = null;
    await backend.close();
  }
}

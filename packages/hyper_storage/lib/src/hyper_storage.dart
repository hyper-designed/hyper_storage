import 'dart:math';

import 'package:meta/meta.dart';

import 'api/api.dart';
import 'api/backend.dart';
import 'api/listenable.dart';
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
    if (_instance == null) throw StateError('HyperStorage not initialized. Call HyperStorage.init() first.');
    return _instance!;
  }

  static Future<HyperStorage> init({required StorageBackend backend}) async {
    if (_instance case var instance?) {
      if (backend.runtimeType != instance.backend.runtimeType) {
        throw StateError(
          'HyperStorage already initialized with different backend type: ${instance.backend.runtimeType}. Call HyperStorage.close() before reinitializing with a different backend.',
        );
      }
      return instance;
    }
    await backend.init();
    return _instance = HyperStorage._(backend);
  }

  /// Uses in-memory backend which is easier to test.
  @visibleForTesting
  static Future<HyperStorage> initMocked({Map<String, dynamic>? initialData}) async {
    if (_instance case var instance?) return instance;

    final backend = InMemoryBackend.withData(initialData: initialData);
    await backend.init();
    return _instance = HyperStorage._(backend);
  }

  static Future<StorageContainer> container(String name) async {
    if (instance._containers.containsKey(name)) return instance._containers[name]!;
    final container = await instance.backend.container(name);
    return instance._containers[name] = container;
  }

  static Future<JsonStorageContainer<E>> jsonSerializableContainer<E>(
    String name, {
    required ToJson<E> toJson,
    required FromJson<E> fromJson,
    IdGetter<E>? idGetter,
    Random? random,
    int? seed,
    String? delimiter,
  }) async {
    if (instance._objectContainers.containsKey(name)) {
      final existing = instance._objectContainers[name]!;
      if (existing case JsonStorageContainer<E>()) return existing;

      throw StateError('Container with name $name already exists with different type: ${existing.runtimeType}.');
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
    if (instance._objectContainers.containsKey(name)) {
      final existing = instance._objectContainers[name]!;
      if (existing is F) return existing;
      throw StateError('Container with name $name already exists with different type: ${existing.runtimeType}.');
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

    removeAllListeners();
    _instance = null;
    await backend.close();
  }
}

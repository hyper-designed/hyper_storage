import 'package:meta/meta.dart';

import 'backend/backend.dart';
import 'backend/in_memory_backend.dart';
import 'container/serializable_container.dart';
import 'container/storage_container.dart';

final Map<String, HyperStorageContainer> _containers = {};
final Map<String, SerializableStorageContainer> _objectContainers = {};

class HyperStorage extends HyperStorageContainer {
  static HyperStorage? _instance;

  static HyperStorage get instance {
    if (_instance == null) throw StateError('LocalStorage not initialized. Call LocalStorage.init() first.');
    return _instance!;
  }

  HyperStorage._(StorageBackend backend) : super(backend: backend, name: '');

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

  static Future<HyperStorageContainer> container(String name) async {
    if (_containers.containsKey(name)) return _containers[name]!;
    return await instance.backend.container(name);
  }

  static Future<SerializableStorageContainer<T>> objectContainer<T>(
    String name, {
    required ToJson<T> toJson,
    required FromJson<T> fromJson,
    IdGetter<T>? idGetter,
  }) async {
    if (_containers.containsKey(name)) return _objectContainers[name]! as SerializableStorageContainer<T>;
    return SerializableStorageContainer<T>(
      backend: instance.backend,
      name: name,
      fromJson: fromJson,
      toJson: toJson,
      idGetter: idGetter,
    );
  }

  /// Closes all containers and the backend.
  @override
  Future<void> close() async {
    final List<Future<void>> futures = [];
    for (final storage in _containers.values) {
      futures.add(storage.close());
    }
    _containers.clear();

    for (final storage in _objectContainers.values) {
      futures.add(storage.close());
    }
    await Future.wait(futures);
    _instance = null;
    await super.close();
  }

  @override
  Future<void> clear() => backend.clear();
}

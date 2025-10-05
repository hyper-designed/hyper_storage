// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:meta/meta.dart';

import '../hyper_storage.dart';
import 'api/api.dart';
import 'api/backend.dart';
import 'api/storage_container.dart';

part 'storage_base.dart';

/// The main entry point for the HyperStorage library, providing centralized
/// storage management with a singleton pattern.
///
/// [HyperStorage] serves as the primary interface for all storage operations,
/// managing containers and providing direct access to storage functionality.
/// It implements a singleton pattern to ensure consistent access to storage
/// across your application while supporting multiple storage backends.
///
/// Before using [HyperStorage], you must initialize it with a backend.
///
/// Container-Based Storage: Containers provide namespaced storage for better organization:
///
/// JSON Serializable Containers: Store custom objects with automatic JSON serialization:
///
/// Supports Custom Serializable Containers: For advanced use cases, create custom container implementations.
///
/// [HyperStorage] uses a singleton pattern which is safe for concurrent access
/// within a single isolate. For multi-isolate access, ensure your backend
/// supports it or implement proper synchronization.
///
/// ## Container Caching
///
/// Containers are cached by name. Requesting the same container multiple times
/// returns the same instance.
///
/// See also:
/// - [StorageContainer] for basic container functionality
/// - [JsonStorageContainer] for JSON serialization
/// - [SerializableStorageContainer] for custom object storage
/// - [StorageBackend] for implementing custom backends
class HyperStorage extends _HyperStorageImpl {
  /// Cache of basic storage containers indexed by name.
  ///
  /// This map stores [StorageContainer] instances created through the
  /// [container] method. Containers are cached to ensure the same instance
  /// is returned for repeated requests with the same name, maintaining
  /// consistency of listeners and state.
  final Map<String, StorageContainer> _containers = {};

  /// Cache of serializable object containers indexed by name.
  ///
  /// This map stores [SerializableStorageContainer] instances created through
  /// [jsonSerializableContainer] or [objectContainer] methods. Containers are
  /// cached to ensure the same instance is returned for repeated requests with
  /// the same name, maintaining consistency of listeners and state.
  final Map<String, SerializableStorageContainer> _objectContainers = {};

  /// Private constructor for creating the singleton instance.
  ///
  /// This constructor is private to enforce the singleton pattern. Instances
  /// should only be created through [init] or [initMocked] methods.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend to use for all operations.
  HyperStorage._({required super.backend});

  /// Creates a new instance of [HyperStorage] with the specified backend.
  static Future<HyperStorage> newInstance({required StorageBackend backend}) async {
    await backend.init();
    return HyperStorage._(backend: backend);
  }

  /// The singleton instance of [HyperStorage].
  ///
  /// This field holds the single instance of [HyperStorage] that is created
  /// during initialization. It is null before initialization and set by
  /// [init] or [initMocked] methods.
  static HyperStorage? _instance;

  /// Returns the singleton instance of [HyperStorage].
  ///
  /// This getter provides access to the initialized [HyperStorage] instance.
  /// The instance must be initialized using [init] or [initMocked] before
  /// accessing this property.
  ///
  /// Returns:
  ///   The singleton [HyperStorage] instance.
  ///
  /// Throws:
  ///   * [StateError] if [HyperStorage] has not been initialized. You must
  ///     call [init] or [initMocked] before accessing this property.
  static HyperStorage get instance {
    if (_instance == null) throw StateError('HyperStorage not initialized. Call HyperStorage.init() first.');
    return _instance!;
  }

  /// Initializes the HyperStorage singleton with the specified backend.
  ///
  /// This method must be called before any storage operations can be performed.
  /// It sets up the storage system with the provided backend, which handles
  /// the actual data persistence. If [HyperStorage] is already initialized with
  /// the same backend type, the existing instance is returned. If initialized
  /// with a different backend type, a [StateError] is thrown.
  ///
  /// The method is idempotent for the same backend type - calling it multiple
  /// times with the same backend type will return the existing instance without
  /// re-initialization.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend to use. This determines where and how
  ///     data is persisted (e.g., Hive, SharedPreferences, etc.). The backend
  ///     will be initialized as part of this call.
  ///
  /// Returns:
  ///   A [Future] that completes with the initialized [HyperStorage] instance.
  ///
  /// Throws:
  ///   * [StateError] if [HyperStorage] is already initialized with a different
  ///     backend type. You must call [close] before reinitializing with a
  ///     different backend.
  ///
  /// See also:
  /// - [initMocked] for testing with an in-memory backend
  /// - [close] for proper cleanup when done
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
    return _instance = HyperStorage._(backend: backend);
  }

  /// Initializes HyperStorage with an in-memory backend for testing purposes.
  ///
  /// This method is designed for unit and integration tests, providing a
  /// lightweight in-memory storage backend that doesn't persist data to disk.
  /// The backend can be pre-populated with initial data for testing scenarios.
  ///
  /// If [HyperStorage] is already initialized, the existing instance is returned
  /// regardless of the [initialData] parameter.
  ///
  /// Parameters:
  ///   * [initialData] - Optional initial data to populate the storage with.
  ///     The map keys are storage keys and values are their corresponding data.
  ///     This is useful for testing scenarios that require pre-existing data.
  ///
  /// Returns:
  ///   A [Future] that completes with the initialized [HyperStorage] instance
  ///   using an in-memory backend.
  ///
  /// See also:
  /// - [init] for production initialization
  /// - [InMemoryBackend] for the underlying test backend
  @visibleForTesting
  static Future<HyperStorage> initMocked({Map<String, dynamic>? initialData}) async {
    if (_instance case var instance?) return instance;

    final backend = InMemoryBackend.withData(initialData: initialData);
    await backend.init();
    return _instance = HyperStorage._(backend: backend);
  }

  /// Retrieves or creates a basic storage container with the specified name.
  ///
  /// Containers provide namespaced storage for organizing related data. This
  /// method returns a [StorageContainer] that can store primitive types
  /// (strings, integers, booleans, etc.) and collections. Containers are
  /// cached, so repeated calls with the same name return the same instance.
  ///
  /// Container names are used as prefixes for storage keys, ensuring data
  /// isolation between containers even when using the same backend.
  ///
  /// Parameters:
  ///   * [name] - The name of the container. This serves as a namespace for
  ///     all keys stored in the container. The name should be unique across
  ///     your application to avoid conflicts.
  ///
  /// Returns:
  ///   A [Future] that completes with the [StorageContainer] instance. If a
  ///   container with this name already exists, the cached instance is returned.
  ///   Otherwise, a new container is created and cached.
  ///
  /// See also:
  /// - [jsonSerializableContainer] for storing custom objects with JSON
  /// - [objectContainer] for custom serialization logic
  /// - [StorageContainer] for available operations
  Future<StorageContainer> container(String name) async {
    if (_containers.containsKey(name)) return _containers[name]!;
    final container = await backend.container(name);
    return _containers[name] = container;
  }

  /// Creates or retrieves a JSON-serializable storage container for custom objects.
  ///
  /// This method provides a convenient way to store and retrieve custom Dart
  /// objects by automatically handling JSON serialization and deserialization.
  /// The container manages object persistence, ID generation, and provides
  /// full CRUD operations for your custom types.
  ///
  /// Type parameter [E] specifies the type of objects to store. Containers are
  /// cached by name, so repeated calls with the same name and compatible type
  /// return the same instance.
  ///
  /// Parameters:
  ///   * [name] - The name of the container, used for namespacing storage keys.
  ///   * [toJson] - A function that converts an object of type [E] to a JSON
  ///     map. This is called when storing objects.
  ///   * [fromJson] - A function that converts a JSON map back to an object of
  ///     type [E]. This is called when retrieving objects.
  ///   * [idGetter] - Optional. A function that extracts the ID from an object.
  ///     If provided, this ID is used when adding objects with [add]. If not
  ///     provided, IDs are automatically generated.
  ///   * [random] - Optional. A custom random number generator for ID generation.
  ///     Useful for testing or when specific randomness characteristics are needed.
  ///   * [seed] - Optional. A seed value for the random number generator. If
  ///     neither [random] nor [seed] is provided, a deterministic seed based on
  ///     the backend is used.
  ///   * [delimiter] - Optional. The character(s) used to separate the container
  ///     name from keys. If not provided, uses the default delimiter.
  ///
  /// Returns:
  ///   A [Future] that completes with the [JsonStorageContainer] instance. If a
  ///   container with this name already exists with the same type, the cached
  ///   instance is returned.
  ///
  /// Throws:
  ///   * [StateError] if a container with the same name already exists but with
  ///     a different type.
  ///
  /// See also:
  /// - [container] for basic storage containers
  /// - [objectContainer] for custom serialization logic
  /// - [JsonStorageContainer] for available operations
  Future<JsonStorageContainer<E>> jsonSerializableContainer<E>(
    String name, {
    required ToJson<E> toJson,
    required FromJson<E> fromJson,
    IdGetter<E>? idGetter,
    Random? random,
    int? seed,
    String? delimiter,
  }) async {
    if (_objectContainers.containsKey(name)) {
      final existing = _objectContainers[name]!;
      if (existing case JsonStorageContainer<E>()) return existing;

      throw StateError('Container with name $name already exists with different type: ${existing.runtimeType}.');
    }
    final container = JsonStorageContainer<E>(
      backend: backend,
      name: name,
      fromJson: fromJson,
      toJson: toJson,
      idGetter: idGetter,
      delimiter: delimiter,
      random: random,
      seed: seed,
    );
    return _objectContainers[name] = container;
  }

  /// Creates or retrieves a custom serializable storage container.
  ///
  /// This method provides maximum flexibility for storing custom objects by
  /// allowing you to implement your own container class that extends
  /// [SerializableStorageContainer]. This is useful when you need custom
  /// serialization logic beyond JSON, or when you want to encapsulate
  /// container-specific behavior.
  ///
  /// Type parameters:
  ///   * [E] - The type of objects stored in the container
  ///   * [F] - The container type, which must extend [SerializableStorageContainer]
  ///
  /// Parameters:
  ///   * [name] - The name of the container, used for namespacing storage keys.
  ///     This should match the name used in your container implementation.
  ///   * [factory] - A factory function that creates a new instance of your
  ///     custom container. This is only called if the container doesn't exist
  ///     in the cache.
  ///
  /// Returns:
  ///   A [Future] that completes with the custom container instance. If a
  ///   container with this name already exists with the same type, the cached
  ///   instance is returned.
  ///
  /// Throws:
  ///   * [StateError] if a container with the same name already exists but with
  ///     a different type.
  ///
  /// See also:
  /// - [container] for basic storage containers
  /// - [jsonSerializableContainer] for JSON serialization
  /// - [SerializableStorageContainer] for the base container class
  Future<F> objectContainer<E, F extends SerializableStorageContainer<E>>(
    String name, {
    required F Function() factory,
  }) async {
    if (_objectContainers.containsKey(name)) {
      final existing = _objectContainers[name]!;
      if (existing is F) return existing;
      throw StateError('Container with name $name already exists with different type: ${existing.runtimeType}.');
    }
    final F container = factory();
    return _objectContainers[name] = container;
  }

  /// Destroys the HyperStorage instance and deletes all stored data.
  ///
  /// This method removes all data from the underlying storage backend, including
  /// all containers and their contents. It does not close the storage system;
  /// after calling this method, [HyperStorage] remains initialized and can be
  /// used to store new data.
  ///
  /// This method should be used with caution, as it irreversibly deletes all
  /// stored data. It is typically used in scenarios such as user logout, app
  /// reset, or when you need to clear all data for testing purposes.
  ///
  /// Call [HyperStorageContainer.clear] on individual containers if you only want to
  /// clear specific namespaces without affecting the entire storage.
  @override
  Future<void> clear() async {
    final List<Future<void>> futures = [
      for (final storage in _containers.values) storage.clear(),
      for (final storage in _objectContainers.values) storage.clear(),
    ];
    await Future.wait(futures);
    final keys = await backend.getKeys();
    await backend.clear();
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  /// Closes the HyperStorage instance and releases all resources.
  ///
  /// This method performs a complete cleanup of the storage system:
  /// 1. Closes all cached containers (both basic and object containers)
  /// 3. Removes all registered listeners
  /// 4. Resets the singleton instance to null
  /// 5. Closes the underlying storage backend
  ///
  /// After calling this method, [HyperStorage] must be re-initialized with
  /// [init] or [initMocked] before it can be used again. Any references to
  /// the old instance or its containers should be discarded.
  ///
  /// This method should be called when your application is shutting down or
  /// when you need to switch to a different storage backend. It ensures all
  /// pending operations are completed and resources are properly released.
  ///
  /// Returns:
  ///   A [Future] that completes when all cleanup operations have finished.
  ///
  /// See also:
  /// - [init] for reinitializing after close
  /// - [clear] for removing all data without closing
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

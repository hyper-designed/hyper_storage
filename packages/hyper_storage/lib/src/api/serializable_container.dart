// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';

import '../generate_id.dart' as generator;
import 'api.dart';
import 'storage_container.dart';

/// A function that takes an object of type [E] and returns its ID as a string.
///
/// This typedef is used to define how objects are identified within a storage
/// container. When provided, it allows the container to extract IDs from
/// objects rather than generating new IDs.
///
/// Parameters:
///   * [object] - The object from which to extract the ID.
///
/// Returns:
///   A string representing the unique identifier for the object.
typedef IdGetter<E> = String Function(E object);

/// A function that serializes an object of type [E] to a string.
///
/// This typedef is used to define the serialization logic for objects
/// stored in a [SerializableStorageContainer]. The function should convert
/// the object into a string format suitable for storage (e.g., JSON).
typedef SerializeCallback<E> = String Function(E value);

/// A function that deserializes a string back to an object of type [E].
///
/// This typedef is used to define the deserialization logic for objects
/// stored in a [SerializableStorageContainer]. The function should convert
/// the string representation back into an object of type [E].
typedef DeserializeCallback<E> = E Function(String value);

/// An abstract class that provides a container for storing serializable objects
/// of type [E].
///
/// This class extends [StorageContainer] and implements
/// [SerializableStorageOperationsApi], providing a comprehensive set of CRUD
/// operations for storing, retrieving, and managing serializable objects. Each
/// object is associated with a unique ID, which can either be extracted from
/// the object using an [IdGetter] or automatically generated.
///
/// ## Key Features
///
/// - **Object Storage**: Store and retrieve typed objects, not just primitives
/// - **Automatic Serialization**: Objects are automatically serialized to
///   strings for storage
/// - **ID Management**: Supports both custom ID extraction and automatic ID
///   generation
/// - **Batch Operations**: Efficiently handle multiple objects at once with
///   `setAll`, `addAll`, etc.
/// - **Type Safety**: Generic type parameter ensures type-safe operations
/// - **Full CRUD Support**: Complete create, read, update, delete functionality
///
/// ## Usage
///
/// To use this class, you must:
/// 1. Extend it and provide a type parameter
/// 2. Implement [serialize] to convert objects to strings
/// 3. Implement [deserialize] to convert strings back to objects
///
/// ## ID Management
///
/// The container supports two modes for managing object IDs:
///
/// ### Custom ID Extraction
/// Provide an [IdGetter] function to extract IDs from objects:
/// ```dart
/// SerializableStorageContainer<User>(
///   backend: backend,
///   name: 'users',
///   idGetter: (user) => user.id,  // Extract ID from object
/// );
/// ```
///
/// ### Automatic ID Generation
/// If no [IdGetter] is provided, IDs are automatically generated:
/// ```dart
/// SerializableStorageContainer<Note>(
///   backend: backend,
///   name: 'notes',
///   // No idGetter - IDs will be auto-generated
/// );
/// ```
///
/// Subclasses must implement:
/// - [serialize]: Convert an object of type [E] to a [String]
/// - [deserialize]: Convert a [String] back to an object of type [E]
///
/// See also:
/// - [StorageContainer] for the base container functionality
/// - [SerializableStorageOperationsApi] for the operation interface
/// - [IdGetter] for custom ID extraction
abstract class SerializableStorageContainer<E> extends StorageContainer implements SerializableStorageOperationsApi<E> {
  /// An optional function that extracts the ID from an object.
  ///
  /// When provided, this function is used to determine the ID of objects
  /// passed to methods like [add], [update], [removeItem], etc. If not
  /// provided, the container will automatically generate IDs using
  /// [generateId]. [generateId] generates a random, unique string ID.
  /// Random object can be configured via the constructor.
  ///
  /// The extracted ID must be a valid storage key and must not contain the
  /// container's delimiter. If the function returns an invalid ID, an
  /// [ArgumentError] will be thrown.
  final IdGetter<E>? idGetter;

  /// Internal random number generator used for ID generation.
  ///
  /// This is used by [generateId] to create unique identifiers when no
  /// [idGetter] is provided. The generator can be seeded for deterministic
  /// behavior in testing scenarios.
  final Random _random;

  /// Creates a new [SerializableStorageContainer].
  ///
  /// The constructor initializes a container for storing serializable objects
  /// with support for custom ID extraction or automatic ID generation. It
  /// sets up the random number generator for ID generation, using either a
  /// provided generator, a seeded generator, or one seeded with the backend's
  /// hash code for deterministic behavior.
  ///
  /// Parameters:
  ///   * [idGetter] - Optional. A function that extracts the ID from an object.
  ///     If not provided, IDs will be automatically generated using
  ///     [generateId]. The extracted ID must be a valid storage key.
  ///   * [backend] - The storage backend to use for persistence operations.
  ///   * [name] - The name of the container, used for namespacing keys.
  ///   * [delimiter] - Optional. The character(s) used to separate the
  ///     container name from keys. If not provided, uses the default delimiter.
  ///   * [random] - Optional. A custom random number generator for ID
  ///     generation. Useful for testing or when specific randomness
  ///     characteristics are needed.
  ///   * [seed] - Optional. A seed value for the random number generator. If
  ///     neither [random] nor [seed] is provided, the backend's hash code is
  ///     used as the seed for deterministic behavior across container
  ///     recreations.
  SerializableStorageContainer({
    this.idGetter,
    required super.backend,
    required super.name,
    super.delimiter,
    Random? random,
    int? seed,
  }) : _random = random ?? Random(seed ?? backend.hashCode);

  /// Serializes an object of type [E] to a string for storage.
  ///
  /// This abstract method must be implemented by subclasses to define how
  /// objects are converted to strings for persistence. The serialization
  /// format is up to the implementation (JSON, XML, binary encoding, etc.),
  /// but it must be reversible by the [deserialize] method.
  ///
  /// Parameters:
  ///   * [value] - The object to serialize.
  ///
  /// Returns:
  ///   A string representation of the object that can be stored and later
  ///   deserialized.
  ///
  /// See also:
  /// - [deserialize] for the reverse operation
  @protected
  @override
  String serialize(E value);

  /// Deserializes a string back to an object of type [E].
  ///
  /// This abstract method must be implemented by subclasses to define how
  /// strings from storage are converted back to objects. The implementation
  /// must be able to reverse the serialization performed by [serialize].
  ///
  /// Parameters:
  ///   * [value] - The string to deserialize, as returned by [serialize].
  ///
  /// Returns:
  ///   An object of type [E] reconstructed from the string.
  ///
  /// See also:
  /// - [serialize] for the reverse operation
  @protected
  @override
  E deserialize(String value);

  /// Generates a new unique ID for an object.
  ///
  /// This method is used internally when no [idGetter] is provided. It
  /// generates a random, unique string identifier using the internal random
  /// number generator. The generated IDs are guaranteed to be valid storage
  /// keys (non-empty and not containing delimiters).
  ///
  /// Returns:
  ///   A newly generated unique ID string.
  ///
  /// See also:
  /// - [getId] which uses this method when no idGetter is available
  @protected
  @override
  String generateId() => generator.generateId(_random);

  /// Gets the ID for the given object.
  ///
  /// This method determines the appropriate ID for an object based on whether
  /// an [idGetter] was provided during construction:
  /// - If [idGetter] is available, it extracts the ID from the object and
  ///   validates it
  /// - If [idGetter] is not available, it generates a new random ID
  ///
  /// Parameters:
  ///   * [value] - The object for which to get or generate an ID.
  ///
  /// Returns:
  ///   The ID for the object, either extracted or generated.
  ///
  /// Throws:
  ///   * [ArgumentError] if the [idGetter] returns an invalid ID (empty, only
  ///     whitespace, or containing the delimiter)
  ///
  /// See also:
  /// - [generateId] which is called when no idGetter is available
  /// - [validateKey] which validates extracted IDs
  @protected
  @override
  String getId(E value) {
    if (idGetter case var idGetter?) {
      final id = idGetter(value);
      validateKey(id);
      return id;
    }
    return generateId();
  }

  /// Stores an object with the specified key.
  ///
  /// This method serializes the [value] and stores it in the backend with the
  /// given [key]. The key is validated and encoded with the container's
  /// namespace before storage. After storing, all global listeners and
  /// key-specific listeners for this key are notified.
  ///
  /// Parameters:
  ///   * [key] - The key under which to store the object. Must be non-empty,
  ///     not only whitespace, and not contain the delimiter.
  ///   * [value] - The object to store.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is invalid (see [validateKey] for rules)
  ///
  /// See also:
  /// - [add] for storing an object using its ID
  /// - [setAll] for storing multiple objects at once
  @override
  Future<void> set(String key, E value) async {
    validateKey(key);
    await backend.setString(encodeKey(key), serialize(value));
    notifyListeners(key);
  }

  /// Returns `true` if the container has no stored objects.
  ///
  /// This property retrieves all keys from the container and checks if the
  /// set is empty. It's a convenience property for checking whether the
  /// container contains any data.
  ///
  /// Returns:
  ///   A future that completes with `true` if the container is empty, `false`
  ///   otherwise.
  ///
  /// See also:
  /// - [isNotEmpty] for the inverse check
  /// - [getKeys] which is used internally
  @override
  Future<bool> get isEmpty async {
    final keys = await getKeys();
    return keys.isEmpty;
  }

  /// Returns `true` if the container has at least one stored object.
  ///
  /// This property retrieves all keys from the container and checks if the
  /// set is non-empty. It's a convenience property for checking whether the
  /// container contains any data.
  ///
  /// Returns:
  ///   A future that completes with `true` if the container is not empty,
  ///   `false` otherwise.
  ///
  /// See also:
  /// - [isEmpty] for the inverse check
  /// - [getKeys] which is used internally
  @override
  Future<bool> get isNotEmpty async {
    final keys = await getKeys();
    return keys.isNotEmpty;
  }

  /// Stores multiple objects with their associated keys.
  ///
  /// This method serializes all objects in the [items] map and stores them
  /// in the backend in a single batch operation. All keys are validated and
  /// encoded before storage. After storing, key-specific listeners for each
  /// key are notified, followed by all global listeners.
  ///
  /// Parameters:
  ///   * [items] - A map of keys to objects. Each key must be valid (see
  ///     [validateKey] for rules).
  ///
  /// Throws:
  ///   * [ArgumentError] if any key is invalid
  ///
  /// See also:
  /// - [set] for storing a single object
  /// - [addAll] for adding multiple objects using their IDs
  @override
  Future<void> setAll(Map<String, E> items) async {
    validateKeys(items.keys);
    await backend.setAll(items.map((key, value) => MapEntry(encodeKey(key), serialize(value))));
    for (final key in items.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  /// Adds an object to the container using its ID.
  ///
  /// This method determines the object's ID using [getId] (either by calling
  /// [idGetter] or generating a new ID), then stores the object with that ID.
  /// This is a convenience method that combines ID extraction/generation with
  /// storage.
  ///
  /// Parameters:
  ///   * [value] - The object to add.
  ///
  /// Throws:
  ///   * [ArgumentError] if the extracted/generated ID is invalid
  ///
  /// See also:
  /// - [addAll] for adding multiple objects
  /// - [set] for storing with an explicit key
  /// - [getId] which determines the ID
  @override
  Future<void> add(E value) => set(getId(value), value);

  /// Adds multiple objects to the container using their IDs.
  ///
  /// This method determines each object's ID using [getId], creates a map
  /// of IDs to objects, and stores them all in a single batch operation. This
  /// is more efficient than calling [add] multiple times.
  ///
  /// If multiple objects have the same ID, only the last one will be stored
  /// (due to map semantics).
  ///
  /// Parameters:
  ///   * [values] - The objects to add.
  ///
  /// Throws:
  ///   * [ArgumentError] if any extracted/generated ID is invalid
  ///
  /// See also:
  /// - [add] for adding a single object
  /// - [setAll] for storing with explicit keys
  @override
  Future<void> addAll(Iterable<E> values) async {
    final Map<String, E> items = <String, E>{for (final value in values) getId(value): value};
    await setAll(items);
  }

  /// Updates an existing object in the container.
  ///
  /// This method determines the object's ID using [getId], checks if an
  /// object with that ID exists, and updates it if found. If no object with
  /// the ID exists, a [StateError] is thrown to prevent accidental creation
  /// of new objects.
  ///
  /// Parameters:
  ///   * [value] - The object to update. Its ID must already exist in the
  ///     container.
  ///
  /// Throws:
  ///   * [StateError] if no object with the extracted ID exists
  ///   * [ArgumentError] if the extracted/generated ID is invalid
  ///
  /// See also:
  /// - [updateAll] for updating multiple objects
  /// - [add] which doesn't require the object to exist
  /// - [set] for unconditional storage
  @override
  Future<void> update(E value) async {
    final String id = getId(value);
    if (await containsKey(id)) {
      await set(id, value);
    } else {
      throw StateError('Item with id $id does not exist and cannot be updated.');
    }
  }

  /// Updates multiple existing objects in the container.
  ///
  /// This method checks that all objects exist before updating any of them.
  /// If any object's ID doesn't exist, a [StateError] is thrown and no
  /// objects are updated. This ensures atomicity - either all objects are
  /// updated or none are.
  ///
  /// Parameters:
  ///   * [values] - The objects to update. All their IDs must already exist
  ///     in the container.
  ///
  /// Throws:
  ///   * [StateError] if any object's ID doesn't exist
  ///   * [ArgumentError] if any extracted/generated ID is invalid
  ///
  /// See also:
  /// - [update] for updating a single object
  /// - [addAll] which doesn't require objects to exist
  @override
  Future<void> updateAll(Iterable<E> values) async {
    final Map<String, E> items = <String, E>{};
    for (final value in values) {
      final String id = getId(value);
      if (await containsKey(id)) {
        items[id] = value;
      } else {
        throw StateError('Item with id $id does not exist and cannot be updated.');
      }
    }
    await setAll(items);
  }

  /// Retrieves an object by its key.
  ///
  /// This method fetches the object associated with the given [key] from
  /// storage, deserializes it, and returns it. If the key is null, doesn't
  /// exist, or the stored value is null, this method returns null.
  ///
  /// Parameters:
  ///   * [key] - The key of the object to retrieve. Can be null, in which
  ///     case null is returned. Must be valid if non-null.
  ///
  /// Returns:
  ///   A future that completes with the object if found, or null if the key
  ///   is null, doesn't exist, or has a null value.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is non-null but invalid
  ///
  /// See also:
  /// - [getAll] for retrieving multiple objects
  /// - [getValues] for retrieving all objects as a list
  /// - [containsKey] to check existence without retrieving
  @override
  Future<E?> get(String? key) async {
    if (key == null) return null;
    validateKey(key);
    if (!await containsKey(key)) return null;
    final String? value = await backend.getString(encodeKey(key));
    if (value == null) return null;
    return deserialize(value);
  }

  /// Retrieves multiple objects from the container.
  ///
  /// This method fetches objects from storage, optionally filtered by an
  /// [allowList] of keys. If no allowList is provided, all objects in the
  /// container are returned. Objects are deserialized and returned in a map
  /// with decoded keys.
  ///
  /// Parameters:
  ///   * [allowList] - Optional. A list of keys to retrieve. If provided,
  ///     only objects with these keys are returned. If null or not provided,
  ///     all objects in the container are returned. All keys must be valid.
  ///
  /// Returns:
  ///   A future that completes with a map of keys to objects. Keys are in
  ///   their decoded form (without container prefix).
  ///
  /// Throws:
  ///   * [ArgumentError] if any key in the allowList is invalid
  ///
  /// See also:
  /// - [get] for retrieving a single object
  /// - [getValues] for getting objects as a list without keys
  /// - [getKeys] for getting just the keys
  @override
  Future<Map<String, E>> getAll([Iterable<String>? allowList]) async {
    validateKeys(allowList);
    final keys = allowList?.map(encodeKey).toSet() ?? await getEncodedKeys();
    if (keys.isEmpty) return {};
    final Map<String, dynamic> allData = await backend.getAll(keys);
    return <String, E>{
      for (final MapEntry(:key, :value) in allData.entries) decodeKey(key): deserialize(value.toString()),
    };
  }

  /// Retrieves all objects from the container as a list.
  ///
  /// This method fetches all objects from the container and returns them as
  /// a list, without their associated keys. The order of objects in the list
  /// is not guaranteed.
  ///
  /// Returns:
  ///   A future that completes with a list of all objects in the container.
  ///
  /// See also:
  /// - [getAll] for getting objects with their keys
  /// - [get] for retrieving a single object
  /// - [getKeys] for getting just the keys
  @override
  Future<List<E>> getValues() async {
    final allData = await getAll();
    return allData.values.toList();
  }

  /// Checks if an object with the given key exists in the container.
  ///
  /// This method validates the key and checks if the backend contains a value
  /// for the encoded key. It does not retrieve or deserialize the object.
  ///
  /// Parameters:
  ///   * [key] - The key to check. Must be non-empty, not only whitespace,
  ///     and not contain the delimiter.
  ///
  /// Returns:
  ///   A future that completes with `true` if an object with the key exists,
  ///   `false` otherwise.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is invalid
  ///
  /// See also:
  /// - [get] which also checks existence while retrieving
  /// - [getKeys] for getting all keys
  @override
  Future<bool> containsKey(String key) async {
    validateKey(key);
    return backend.containsKey(encodeKey(key));
  }

  /// Returns all keys (IDs) of objects stored in the container.
  ///
  /// This method retrieves all keys belonging to this container from the
  /// backend, decodes them by removing the container prefix, and returns
  /// them as a set.
  ///
  /// Returns:
  ///   A future that completes with a set of all keys in the container. Keys
  ///   are in their decoded form (without container prefix).
  ///
  /// See also:
  /// - [getAll] for getting objects with their keys
  /// - [getValues] for getting just the objects
  /// - [isEmpty] for checking if there are any keys
  @override
  Future<Set<String>> getKeys() => getDecodedKeys();

  /// Removes an object by its key.
  ///
  /// This method validates the key, removes the object from the backend
  /// storage, and notifies all global listeners and key-specific listeners
  /// for this key. If the key doesn't exist, no error is thrown (the
  /// operation is idempotent).
  ///
  /// Parameters:
  ///   * [key] - The key of the object to remove. Must be non-empty, not
  ///     only whitespace, and not contain the delimiter.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is invalid
  ///
  /// See also:
  /// - [removeItem] for removing by object
  /// - [removeAll] for removing multiple objects by key
  /// - [clear] for removing all objects
  @override
  Future<void> remove(String key) async {
    validateKey(key);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  /// Removes an object from the container.
  ///
  /// This method extracts the ID from the [item] using [getId], then removes
  /// the object with that ID from storage. After removal, all global
  /// listeners and key-specific listeners for this key are notified.
  ///
  /// Parameters:
  ///   * [item] - The object to remove. Its ID is extracted using [getId].
  ///
  /// Throws:
  ///   * [ArgumentError] if the extracted ID is invalid
  ///
  /// See also:
  /// - [remove] for removing by key
  /// - [removeAllItems] for removing multiple objects
  @override
  Future<void> removeItem(E item) async {
    final String key = getId(item);
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  /// Removes multiple objects by their keys.
  ///
  /// This method validates all keys and removes all corresponding objects
  /// from the backend in a single batch operation. After removal, key-specific
  /// listeners for each key are notified, followed by all global listeners.
  ///
  /// Parameters:
  ///   * [keys] - The keys of objects to remove. All keys must be valid.
  ///
  /// Throws:
  ///   * [ArgumentError] if any key is invalid
  ///
  /// See also:
  /// - [remove] for removing a single object by key
  /// - [removeAllItems] for removing multiple objects by object reference
  /// - [clear] for removing all objects
  @override
  Future<void> removeAll(Iterable<String> keys) async {
    validateKeys(keys);
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  /// Removes multiple objects from the container.
  ///
  /// This method extracts the ID from each item using [getId], then removes
  /// all corresponding objects from the backend in a single batch operation.
  /// After removal, key-specific listeners for each key are notified,
  /// followed by all global listeners.
  ///
  /// Parameters:
  ///   * [items] - The objects to remove. IDs are extracted using [getId].
  ///
  /// Throws:
  ///   * [ArgumentError] if any extracted ID is invalid
  ///
  /// See also:
  /// - [removeItem] for removing a single object
  /// - [removeAll] for removing multiple objects by key
  /// - [clear] for removing all objects
  @override
  Future<void> removeAllItems(Iterable<E> items) async {
    final keys = items.map(getId).toList();
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  /// Removes all objects from the container.
  ///
  /// This method retrieves all keys belonging to this container, removes all
  /// corresponding objects from the backend, notifies all listeners (both
  /// key-specific and global), and then removes all listeners. After calling
  /// this method, the container is empty and has no listeners.
  ///
  /// This operation only affects objects in this container - objects in other
  /// containers using the same backend are not affected.
  ///
  /// See also:
  /// - [remove] for removing a single object
  /// - [removeAll] for removing specific objects
  /// - [close] which also clears listeners but doesn't remove data
  @override
  Future<void> clear() async {
    final encodedKeys = await getEncodedKeys();
    await backend.removeAll(encodedKeys);

    final decodedKeys = encodedKeys.map(decodeKey).toList();
    for (final key in decodedKeys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
    removeAllListeners();
  }

  /// Closes the container and releases all resources.
  ///
  /// This method removes all listeners (both global and key-specific) and
  /// closes the backend. After calling this method, the container should not
  /// be used. Any data stored in the container remains in the backend and can
  /// be accessed by creating a new container with the same name.
  ///
  /// This is the standard cleanup method that should be called when the
  /// container is no longer needed.
  ///
  /// See also:
  /// - [clear] which removes all data but also clears listeners
  /// - [removeAllListeners] for removing listeners without closing
  @override
  Future<void> close() async {
    removeAllListeners();
    await backend.close();
  }

  /// Provides a [Stream] of values for the given [key].
  /// The stream will emit the current value of the key and will update
  /// whenever the value changes.
  ///
  /// It is important to close the stream when it is no longer needed
  /// to avoid memory leaks.
  ///
  /// This can be done by cancelling the subscription to the stream.
  Stream<E?> stream(String key) async* {
    final E? itemValue = await get(key);
    yield itemValue;

    late final void Function() retrieveAndAdd;
    final controller = StreamController<E?>(
      onCancel: () => removeKeyListener(key, retrieveAndAdd),
    );

    retrieveAndAdd = () async {
      if (controller.isClosed) return;
      final E? value = await get(key);
      if (!controller.isClosed) {
        controller.add(value);
      }
    };

    addKeyListener(key, retrieveAndAdd);

    yield* controller.stream;
    await controller.close(); // coverage:ignore-line
  }

  /// Provides a [Stream] of values for all items in the container.
  /// The stream will emit the current values and will update
  /// whenever any value changes.
  ///
  /// It is important to close the stream when it is no longer needed
  /// to avoid memory leaks.
  ///
  /// This can be done by cancelling the subscription to the stream.
  Stream<List<E>> streamAll() async* {
    final List<E> values = await getValues();
    yield values;

    late final void Function() retrieveAndAdd;
    final controller = StreamController<List<E>>(
      onCancel: () => removeListener(retrieveAndAdd),
    );

    retrieveAndAdd = () async {
      if (controller.isClosed) return;
      final List<E> values = await getValues();
      if (!controller.isClosed) {
        controller.add(values);
      }
    };

    addListener(retrieveAndAdd);

    yield* controller.stream;
    await controller.close(); // coverage:ignore-line
  }
}

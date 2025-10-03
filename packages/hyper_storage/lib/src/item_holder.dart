import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../hyper_storage.dart';
import 'api/api.dart';

/// Function type definition for getting an item from the storage backend.
typedef ItemGetter<E extends Object> = Future<E?> Function(StorageBackend backend, String key);

/// Function type definition for setting an item in the storage backend.
typedef ItemSetter<E extends Object> = Future<void> Function(StorageBackend backend, String key, E value);

/// A basic implementation of [ItemHolderApi] for simple types.
///
/// This class provides a straightforward way to manage individual items
/// in a storage backend. It requires custom setter and getter functions
/// to handle the specific type [E]. This is useful for types that do not
/// require complex serialization, or when you want to manage the serialization
class ItemHolder<E extends Object> implements BaseListenable, ItemHolderApi<E> {
  BaseStorage? _parent;
  final String _key;

  /// Custom getter function to retrieve the item from the backend.
  ///
  /// If not provided, the default backend's get method will be used.
  /// This allows for flexibility in how items are retrieved.
  ///
  /// If either getter or setter is provided, both must be provided.
  /// This ensures that the item can be both retrieved and stored correctly.
  final ItemGetter<E>? getter;

  /// Custom setter function to store the item in the backend.
  ///
  /// If not provided, the default backend's set method will be used.
  /// This allows for flexibility in how items are stored.
  ///
  /// If either getter or setter is provided, both must be provided.
  /// This ensures that the item can be both retrieved and stored correctly.
  final ItemSetter<E>? setter;

  /// Creates a new [ItemHolder] instance.
  ItemHolder(BaseStorage this._parent, this._key, {this.getter, this.setter});

  @override
  Future<bool> get exists => _parent?.backend.containsKey(_key) ?? Future.value(false);

  @override
  Future<E?> get() async {
    if (_parent case BaseStorage(:final backend)) {
      if (getter case var getter?) return getter(backend, _key);
      final E? value = await backend.get(_key);
      return value;
    }
    return Future.value(null);
  }

  @override
  Future<void> remove() async {
    if (_parent case BaseStorage(:final backend)) {
      await backend.remove(_key);
      notifyListeners();
    }
  }

  @override
  Future<void> set(E value) async {
    if (_parent case BaseStorage(:final backend)) {
      if (setter case var setter?) {
        await setter(backend, _key, value);
      } else {
        await backend.set(_key, value);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    removeAllListeners();
    _parent = null;
  }

  @override
  void addListener(ListenableCallback listener) => _parent?.addKeyListener(_key, listener);

  @override
  bool get hasListeners => _parent?.hasKeyListeners(_key) == true;

  @override
  @internal
  @protected
  // ignore: invalid_use_of_protected_member
  void notifyListeners() => _parent?.notifyKeyListeners(_key);

  @override
  void removeAllListeners() => _parent?.removeAllKeyListeners(_key);

  @override
  void removeListener(ListenableCallback listener) => _parent?.removeKeyListener(_key, listener);
}

/// A base class for item holders that manage serialization and deserialization.
///
/// This abstract class provides common functionality for item holders that need to
/// serialize and deserialize items of type [E]. It implements the [ItemHolderApi]
/// interface and extends [BaseListenable] to support change notifications.
///
/// Subclasses must provide the necessary serialization and deserialization logic
/// through the [serialize] and [deserialize] callbacks.
///
/// Type parameter:
///  - [E] - The type of the item being stored. Must be serializable and deserializable
///          using the provided callbacks.
class SerializableItemHolder<E extends Object> extends ItemHolder<E> {
  /// Converter function to deserialize data into type [E].
  ///
  /// This function is called when retrieving the item from storage to convert
  /// the stored [String] representation back into a Dart object of type [E].
  ///
  /// The function should:
  /// - Accept a `String` representing the data
  /// - Return an instance of [E]
  /// - Handle any necessary validation or default values
  /// - Throw an exception if the data is invalid
  final DeserializeCallback<E> deserialize;

  /// Converter function to serialize type [E] into JSON.
  ///
  /// This function is called when storing the item to convert the Dart object
  /// into a [String] representation that can be persisted.
  ///
  /// The function should:
  /// - Accept an instance of [E]
  /// - Return a [String] representing the data
  /// - Include all necessary data for deserialization
  final SerializeCallback<E> serialize;

  /// Creates a new [SerializableItemHolder] instance.
  SerializableItemHolder(
    super._backend,
    super._key, {
    required this.deserialize,
    required this.serialize,
  }) : super(
         getter: (backend, key) async {
           final value = await backend.getString(key);
           if (value == null) return null;
           return deserialize(value);
         },
         setter: (backend, key, value) => backend.setString(key, serialize(value)),
       );
}

/// A JSON-based item holder for managing serialized items.
///
/// This class extends [SerializableItemHolder] to provide a convenient way to
/// store and retrieve items of type [E] using JSON serialization. It requires
/// custom `fromJson` and `toJson` functions to handle the conversion between
/// the Dart object and its JSON representation.
///
/// Type parameter:
///   - [E] - The type of the item being stored. Must be serializable to and from JSON.
final class JsonItemHolder<E extends Object> extends SerializableItemHolder<E> {
  /// Creates a new [JsonItemHolder] instance.
  JsonItemHolder(
    super._backend,
    super._key, {
    required FromJson<E> fromJson,
    required ToJson<E> toJson,
  }) : super(
         serialize: (value) => jsonEncode(toJson(value)),
         deserialize: (value) => fromJson(jsonDecode(value) as Map<String, dynamic>),
       );
}

/// A mixin that provides item holder creation methods for a storage and containers.
///
/// This mixin is intended to be used with classes that implement [ListenableStorage]
/// and have a [StorageBackend]. It provides methods to create various types of
/// item holders, including JSON-serializable, generic serializable, and primitive
/// type holders. Each item holder is automatically linked to the container's
/// change notification system.
mixin ItemHolderMixin on BaseStorage {
  /// Stub method for encoding keys. Can be overridden by subclasses.
  String encodeKey(String key) => key;

  /// Stub method for validating keys. Can be overridden by subclasses.
  void validateKey(String key) {}

  /// Creates an item holder for storing a single serializable object at the specified key.
  ///
  /// [JsonItemHolder] provides a convenient API for managing a single
  /// object stored under a specific key. This is useful for storing individual
  /// settings, preferences, or any other single-value data that needs
  /// serialization. The holder automatically handles JSON encoding/decoding and
  /// integrates with the container's change notification system.
  ///
  /// Type parameter [T] specifies the type of object to store. The object must
  /// be serializable to/from JSON using the provided [toJson] and [fromJson]
  /// functions.
  ///
  /// Parameters:
  ///   - [key]: The key under which to store the object. Must be non-empty and
  ///     not only whitespace. This key is relative to the container (not
  ///     encoded).
  ///   - [fromJson]: A function that converts a JSON map back to an object of
  ///     type [T]. This is called when retrieving the stored object.
  ///   - [toJson]: A function that converts an object of type [T] to a JSON
  ///     map. This is called when storing the object.
  ///
  /// Returns:
  ///   A [Future] that completes with a [JsonItemHolder] configured to
  ///   manage the object at the specified key.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is invalid (empty or only whitespace)
  ///
  /// See also:
  /// - [serializableItemHolder] for generic/other serialization.
  /// - [itemHolder] for primitive and basic types without serialization.
  JsonItemHolder<E> jsonItemHolder<E extends Object>(
    String key, {
    required FromJson<E> fromJson,
    required ToJson<E> toJson,
  }) {
    validateKey(key);
    return JsonItemHolder<E>(this, encodeKey(key), fromJson: fromJson, toJson: toJson);
  }

  /// Creates an item holder for storing a single serializable object at the specified key.
  ///
  /// [SerializableItemHolder] provides a convenient API for managing a single
  /// object stored under a specific key. This is useful for storing individual
  /// settings, preferences, or any other single-value data that needs
  /// serialization. The holder automatically handles serialization/deserialization and
  /// integrates with the container's change notification system.
  ///
  /// Type parameter [E] specifies the type of object to store. The object must
  /// be serializable using the provided [serialize] and [deserialize]
  /// functions.
  ///
  /// Parameters:
  ///   - [key]: The key under which to store the object. Must be non-empty and not only whitespace.
  ///     This key is relative to the container.
  ///   - [serialize]: A function that converts an object of type [E] to a [String].
  ///     This is called when storing the object.
  ///   - [deserialize]: A function that converts a [String] back to an object of type [E].
  ///     This is called when retrieving the stored object.
  ///
  /// Returns:
  ///   A [SerializableItemHolder] configured to manage the object at the specified key.
  ///
  /// Throws:
  ///   - [ArgumentError] if the key is invalid.
  ///
  /// See also:
  /// - [jsonItemHolder] for JSON-specific serialization.
  /// - [itemHolder] for primitive and basic types without serialization.
  SerializableItemHolder<E> serializableItemHolder<E extends Object>(
    String key, {
    required SerializeCallback<E> serialize,
    required DeserializeCallback<E> deserialize,
  }) {
    validateKey(key);
    return SerializableItemHolder<E>(this, encodeKey(key), serialize: serialize, deserialize: deserialize);
  }

  /// Creates an item holder for storing a single primitive value at the specified key.
  ///
  /// [ItemHolder] provides a convenient API for managing a single item/key in the storage/container.
  /// This makes it easier to pass around a fragment of the storage (without needing to reference
  /// the entire storage/container) that knows how perform operations on that specific key.
  ///
  /// Type parameter [E] specifies the type of item to store. Supported types include:
  /// - String
  /// - int
  /// - double
  /// - bool
  /// - DateTime
  /// - Duration
  /// - List of String
  /// - JSON Map
  /// - List of JSON Maps
  ///
  /// Parameters:
  ///   - [key]: The key under which to store the item. Must be non-empty and not only whitespace.
  ///   This key is relative to the container (not encoded).
  ///   - [get]: Optional custom getter function. If provided, this function will be used
  ///   to retrieve the item instead of the default backend method.
  ///   - [set]: Optional custom setter function. If provided, this function will be used
  ///   to store the item instead of the default backend method.
  ///
  /// Returns:
  ///   A [ItemHolder] configured to manage the item at the specified key.
  ///
  /// Throws:
  ///   - [ArgumentError] if the key is invalid.
  ///
  /// See also:
  ///   - [jsonItemHolder] for JSON-specific serialization.
  ///   - [serializableItemHolder] for generic/other serialization.
  ItemHolder<E> itemHolder<E extends Object>(String key, {ItemGetter<E>? get, ItemSetter<E>? set}) {
    validateKey(key);
    if ((get == null && set != null) || (get != null && set == null)) {
      throw ArgumentError('Both getter and setter must be provided together, or neither.');
    }
    // Only run generic type validation if custom getter/setter are not provided.
    if (set == null || get == null) _validateGenericType<E>();
    return ItemHolder<E>(this, encodeKey(key), setter: set, getter: get);
  }

  /// Creates a custom item holder using the provided factory function.
  ///
  /// This method allows you to create an [ItemHolder] of any type by providing
  /// a factory function that constructs the holder. This is useful for creating
  /// specialized holders that may have custom behavior or serialization logic.
  ///
  /// Parameters:
  ///   - [key]: The key under which to store the item. Must be non-empty and not only whitespace.
  ///   This key is relative to the container (not encoded).
  ///   - [create]: A factory function that takes the [StorageBackend] and encoded key,
  ///   and returns an instance of [H], where [H] extends [ItemHolder<E>].
  ///   This function is responsible for creating the item holder.
  ///
  /// Returns:
  ///   An [ItemHolder] of type [H] configured to manage the item at the specified key.
  ///
  /// Throws:
  ///   - [ArgumentError] if the key is invalid.
  ///
  /// See also:
  ///   - [jsonItemHolder] for JSON-specific serialization.
  ///   - [serializableItemHolder] for generic/other serialization.
  ///   - [itemHolder] for primitive and basic types without serialization.
  H customItemHolder<H extends ItemHolder<E>, E extends Object>(
    String key, {
    required H Function(StorageBackend backend, String key) create,
  }) {
    validateKey(key);
    return create(backend, encodeKey(key));
  }

  bool _validateGenericType<E>() {
    return switch (E) {
      const (String) => true,
      const (int) => true,
      const (double) => true,
      const (bool) => true,
      const (DateTime) => true,
      const (Duration) => true,
      const (List<String>) => true,
      const (Map<String, dynamic>) => true,
      const (List<Map<String, dynamic>>) => true,
      _ => throw UnsupportedError('Type $E is not supported'),
    };
  }
}

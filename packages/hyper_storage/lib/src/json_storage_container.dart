// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

/// @docImport 'hyper_storage.dart';
library;

import 'dart:convert';

import 'api/serializable_container.dart';

/// A function that converts a JSON map to an object of type [E].
///
/// This typedef defines the signature for deserialization functions used by
/// JSON storage containers. The function receives a JSON map (typically
/// obtained from [jsonDecode]) and returns an instance of type [E].
///
/// Parameters:
///   * [json] - A map representing the JSON structure of the object. Keys are
///     strings and values can be any JSON-compatible type (String, num, bool,
///     List, Map, or null).
///
/// Returns:
///   An instance of type [E] constructed from the JSON data.
typedef FromJson<E> = E Function(Map<String, dynamic> json);

/// A function that converts an object of type [E] to a JSON map.
///
/// This typedef defines the signature for serialization functions used by
/// JSON storage containers. The function receives an object of type [E] and
/// returns a JSON-serializable map that can be passed to [jsonEncode].
///
/// Parameters:
///   * [object] - The object to convert to JSON format.
///
/// Returns:
///   A map with string keys and JSON-compatible values representing the object.
///   Values must be JSON-serializable types (String, num, bool, List, Map, or
///   null).
typedef ToJson<E> = Map<String, dynamic> Function(E object);

/// A final implementation of [SerializableStorageContainer] for JSON-serializable objects.
///
/// [JsonStorageContainer] provides a complete, ready-to-use container for
/// storing custom Dart objects using JSON serialization. It automatically
/// handles the conversion between objects and their JSON string representation,
/// making it easy to persist complex data structures.
///
/// ## Purpose
///
/// This class bridges the gap between Dart objects and storage by:
/// - **Automatic Serialization**: Converting objects to JSON strings for storage
/// - **Automatic Deserialization**: Converting JSON strings back to objects
/// - **Type Safety**: Ensuring type-safe operations through generics
/// - **ID Management**: Supporting both custom ID extraction and automatic generation
/// - **Full CRUD**: Providing complete create, read, update, delete operations
///
/// See also:
/// - [SerializableStorageContainer] for the base class
/// - [HyperStorage.jsonContainer] for creating instances
/// - [FromJson] and [ToJson] typedefs for serialization functions
/// - [IdGetter] for custom ID extraction
final class JsonStorageContainer<E extends Object> extends SerializableStorageContainer<E> {
  /// The function used to convert objects of type [E] to JSON maps.
  ///
  /// This function is called internally whenever an object needs to be
  /// serialized for storage. The resulting map is encoded to a JSON string
  /// using [jsonEncode] before being passed to the backend.
  ///
  /// The function should return a map containing only JSON-serializable
  /// values (String, num, bool, List, Map, or null).
  final ToJson<E> toJson;

  /// The function used to convert JSON maps back to objects of type [E].
  ///
  /// This function is called internally whenever a stored object needs to be
  /// retrieved. The JSON string from storage is first decoded using
  /// [jsonDecode], and the resulting map is passed to this function to
  /// reconstruct the object.
  ///
  /// The function should handle all fields present in the JSON map and
  /// construct a valid object of type [E].
  final FromJson<E> fromJson;

  /// Creates a new [JsonStorageContainer] for storing objects of type [E].
  ///
  /// This constructor sets up a container that automatically handles JSON
  /// serialization and deserialization of objects. The container can either
  /// use custom ID extraction (via [idGetter]) or generate random IDs
  /// automatically.
  ///
  /// Type parameter [E] specifies the type of objects to store. The type must
  /// be serializable to/from JSON using the provided [toJson] and [fromJson]
  /// functions.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend that handles actual persistence.
  ///   * [toJson] - A function that converts objects of type [E] to JSON maps.
  ///     Called when storing objects.
  ///   * [fromJson] - A function that converts JSON maps back to objects of
  ///     type [E]. Called when retrieving objects.
  ///   * [idGetter] - Optional. A function that extracts the ID from an object.
  ///     If provided, this ID is used when adding objects. If not provided,
  ///     random IDs are generated.
  ///   * [name] - The name of the container, used for namespacing storage keys.
  ///   * [random] - Optional. A custom random number generator for ID
  ///     generation. Useful for testing or when specific randomness
  ///     characteristics are needed.
  ///   * [delimiter] - Optional. The character(s) used to separate the
  ///     container name from keys. If not provided, uses the default delimiter.
  ///   * [seed] - Optional. A seed value for the random number generator. If
  ///     neither [random] nor [seed] is provided, a deterministic seed based
  ///     on the backend is used.
  ///
  /// Note: Typically, you would create containers using
  /// [HyperStorage.jsonContainer] rather than calling this
  /// constructor directly, as that method handles caching and ensures
  /// singleton behavior per container name.
  JsonStorageContainer({
    required super.backend,
    required this.toJson,
    required this.fromJson,
    super.idGetter,
    required super.name,
    super.random,
    super.delimiter,
    super.seed,
  });

  @override
  E deserialize(String value) => fromJson(jsonDecode(value));

  @override
  String serialize(E value) => jsonEncode(toJson(value));
}

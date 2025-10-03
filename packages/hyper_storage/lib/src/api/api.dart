import 'package:meta/meta.dart';

import 'backend.dart';
import 'listenable.dart';

/// Defines the interface for storage operations on serializable objects of
/// type [E].
///
/// This interface provides a contract for performing CRUD (Create, Read, Update,
/// Delete) operations on objects that can be serialized and deserialized to
/// and from string representations.
///
/// Type parameters:
/// * [E] - The type of objects stored in the container.
abstract interface class SerializableStorageOperationsApi<E> {
  /// Serializes an object of type [E] into a [String] representation.
  ///
  /// This method is used internally to convert objects into a storable format. Implement this method
  /// to define how objects of type [E] should be serialized.
  ///
  /// Parameters:
  /// * [value] - The object to serialize.
  ///
  /// Returns a string representation of the object.
  @protected
  String serialize(E value);

  /// Deserializes a [String] representation into an object of type [E].
  ///
  /// This method is used internally to convert stored string data back into
  /// objects of type [E]. Implement this method to define how to reconstruct objects
  /// of type [E] from their string representations.
  ///
  /// Parameters:
  /// * [value] - The string representation to deserialize.
  ///
  /// Returns the deserialized object of type [E].
  @protected
  E deserialize(String value);

  /// Generates a unique ID for a new object.
  ///
  /// This method is called internally when adding new objects without explicit
  /// keys. It should return a string that is unique within the storage context.
  ///
  /// Returns a unique identifier string.
  @protected
  @internal
  String generateId();

  /// Gets the ID of an existing object.
  ///
  /// This method extracts or generates the identifier for a given object. It's
  /// used internally when storing objects to determine their storage key.
  ///
  /// Parameters:
  /// * [value] - The object to get the ID for.
  ///
  /// Returns the identifier string for the object.
  @protected
  @internal
  String getId(E value);

  /// Returns `true` if the storage contains no objects.
  Future<bool> get isEmpty;

  /// Returns `true` if the storage contains one or more objects.
  Future<bool> get isNotEmpty;

  /// Saves an object with the given [key].
  ///
  /// If an object with the same key already exists, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the object.
  /// * [value] - The object to store.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  ///
  /// Returns a [Future] that completes when the operation is finished.
  Future<void> set(String key, E value);

  /// Saves multiple objects from a [Map] of key-value pairs.
  ///
  /// This is a batch operation that stores multiple objects at once. Existing
  /// objects with matching keys will be replaced.
  ///
  /// Parameters:
  /// * [items] - A map where keys are unique identifiers and values are objects
  ///   to store.
  ///
  /// Throws:
  /// * [ArgumentError] if any key is empty, contains only whitespace, or contains
  ///   invalid characters.
  ///
  /// Returns a [Future] that completes when all objects have been stored.
  Future<void> setAll(Map<String, E> items);

  /// Adds a new object to the storage, generating a new ID for it.
  ///
  /// The ID is generated using [generateId] or extracted using [getId] depending
  /// on the implementation.
  ///
  /// Parameters:
  /// * [value] - The object to add.
  ///
  /// Returns a [Future] that completes when the object has been added.
  Future<void> add(E value);

  /// Adds multiple new objects to the storage, generating new IDs for them.
  ///
  /// This is a batch operation that adds multiple objects at once. IDs are
  /// generated using [generateId] or extracted using [getId] depending on the
  /// implementation.
  ///
  /// Parameters:
  /// * [values] - The objects to add.
  ///
  /// Returns a [Future] that completes when all objects have been added.
  Future<void> addAll(Iterable<E> values);

  /// Updates an existing object in the storage.
  ///
  /// The object's ID is extracted using [getId] to locate the existing object.
  ///
  /// Parameters:
  /// * [value] - The object with updated data.
  ///
  /// Throws:
  /// * [StateError] if no object with the extracted ID exists in storage.
  ///
  /// Returns a [Future] that completes when the object has been updated.
  Future<void> update(E value);

  /// Updates multiple existing objects in the storage.
  ///
  /// This is a batch operation that updates multiple objects at once. Each
  /// object's ID is extracted using [getId] to locate existing objects.
  ///
  /// Parameters:
  /// * [values] - The objects with updated data.
  ///
  /// Throws:
  /// * [StateError] if any object's ID doesn't exist in storage.
  ///
  /// Returns a [Future] that completes when all objects have been updated.
  Future<void> updateAll(Iterable<E> values);

  /// Retrieves an object by its [key].
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the object to retrieve. Can be `null`.
  ///
  /// Returns a [Future] that completes with the object if found, or `null` if
  /// the key is null or no object with the given key exists.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<E?> get(String? key);

  /// Retrieves all objects from the storage.
  ///
  /// Parameters:
  /// * [allowList] - Optional. If provided, only objects whose keys are in this
  ///   list will be returned. If not provided or `null`, all objects are returned.
  ///
  /// Returns a [Future] that completes with a map where keys are object
  /// identifiers and values are the objects themselves.
  ///
  /// Throws:
  /// * [ArgumentError] if any key in the allow list is invalid.
  Future<Map<String, E>> getAll([Iterable<String>? allowList]);

  /// Retrieves all objects from the storage as a list.
  ///
  /// Returns a [Future] that completes with a list of all stored objects.
  /// The order of objects in the list is not guaranteed.
  Future<List<E>> getValues();

  /// Returns a set of all keys in the storage.
  ///
  /// Returns a [Future] that completes with a set containing all object
  /// identifiers currently in storage.
  Future<Set<String>> getKeys();

  /// Returns `true` if an object with the given [key] exists in the storage.
  ///
  /// Parameters:
  /// * [key] - The unique identifier to check.
  ///
  /// Returns a [Future] that completes with `true` if an object with the key
  /// exists, `false` otherwise.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<bool> containsKey(String key);

  /// Removes an object by its [key].
  ///
  /// If no object with the given key exists, this method completes without error.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the object to remove.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  ///
  /// Returns a [Future] that completes when the object has been removed.
  Future<void> remove(String key);

  /// Removes multiple objects by their keys.
  ///
  /// This is a batch operation that removes multiple objects at once. Keys that
  /// don't exist in storage are silently ignored.
  ///
  /// Parameters:
  /// * [keys] - The unique identifiers of the objects to remove.
  ///
  /// Throws:
  /// * [ArgumentError] if any key is invalid.
  ///
  /// Returns a [Future] that completes when all specified objects have been removed.
  Future<void> removeAll(Iterable<String> keys);

  /// Removes an object from the storage.
  ///
  /// The object's ID is extracted using [getId] to locate and remove it.
  ///
  /// Parameters:
  /// * [item] - The object to remove.
  ///
  /// Returns a [Future] that completes when the object has been removed.
  Future<void> removeItem(E item);

  /// Removes multiple objects from the storage.
  ///
  /// This is a batch operation that removes multiple objects at once. Each
  /// object's ID is extracted using [getId] to locate and remove it.
  ///
  /// Parameters:
  /// * [items] - The objects to remove.
  ///
  /// Returns a [Future] that completes when all objects have been removed.
  Future<void> removeAllItems(Iterable<E> items);

  /// Removes all objects from the storage.
  ///
  /// This operation clears the entire storage, removing every object.
  ///
  /// Returns a [Future] that completes when all objects have been removed.
  Future<void> clear();

  /// Closes the storage and releases any resources.
  ///
  /// After calling this method, no further operations should be performed on
  /// the storage. This method should be called when the storage is no longer
  /// needed to free up resources.
  ///
  /// Returns a [Future] that completes when the storage has been closed and
  /// all resources have been released.
  Future<void> close();
}

/// Defines the interface for a holder of a single item of type [E].
///
/// This interface provides a wrapper API for managing a single item in
/// storage. This allows to manage a single key in isolation from other stored data.
///
/// Type parameters:
/// * [E] - The type of the item to store.
abstract interface class ItemHolderApi<E extends Object> {
  /// Returns `true` if the item exists in the storage.
  ///
  /// Returns a [Future] that completes with `true` if an item is stored,
  /// `false` if no item has been set or it has been removed.
  Future<bool> get exists;

  /// Retrieves the item from the storage.
  ///
  /// Returns a [Future] that completes with the stored item if it exists,
  /// or `null` if no item has been set or it has been removed.
  Future<E?> get();

  /// Saves the item to the storage.
  ///
  /// If an item already exists, it will be replaced with the new value.
  ///
  /// Parameters:
  /// * [value] - The item to store.
  ///
  /// Returns a [Future] that completes when the item has been saved.
  Future<void> set(E value);

  /// Removes the item from the storage.
  ///
  /// If no item exists, this method completes without error.
  ///
  /// Returns a [Future] that completes when the item has been removed.
  Future<void> remove();

  /// Disposes any resources held by the item holder.
  void dispose();
}

/// Defines the interface for basic storage operations.
///
/// This interface provides a contract for performing CRUD (Create, Read, Update,
/// Delete) operations on primitive data types and simple data structures such as
/// strings, integers, doubles, booleans, lists, and JSON objects.
///
/// All storage operations are asynchronous and return [Future] values. Keys must be valid.
abstract interface class StorageOperationsApi {
  /// Returns `true` if the storage contains no key-value pairs.
  ///
  /// This getter checks whether the storage is completely empty with no stored
  /// values. It's useful for determining if the storage needs initialization or
  /// has been cleared.
  ///
  /// Returns a [Future] that completes with `true` if the storage is empty,
  /// `false` otherwise.
  Future<bool> get isEmpty;

  /// Returns `true` if the storage contains one or more key-value pairs.
  ///
  /// This getter is the inverse of [isEmpty] and checks whether the storage has
  /// at least one stored value.
  ///
  /// Returns a [Future] that completes with `true` if the storage has at least
  /// one key-value pair, `false` otherwise.
  Future<bool> get isNotEmpty;

  /// Returns `true` if a value with the given [key] exists in the storage.
  ///
  /// This method checks for the presence of a key without retrieving its value,
  /// which can be more efficient than checking if a get operation returns null.
  ///
  /// Parameters:
  /// * [key] - The unique identifier to check for existence.
  ///
  /// Returns a [Future] that completes with `true` if a value with the specified
  /// key exists in storage, `false` otherwise.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<bool> containsKey(String key);

  /// Retrieves a [String] value by its [key].
  ///
  /// This method fetches a string value previously stored using [setString].
  /// If no value exists for the given key, or the stored value is not a string,
  /// this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the string value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored string value if found,
  /// or `null` if the key doesn't exist or the value is not a string.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<String?> getString(String key);

  /// Saves a [String] value with the given [key].
  ///
  /// This method stores a string value in the storage, associating it with the
  /// specified key. If a value already exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the string value.
  /// * [value] - The string value to store.
  ///
  /// Returns a [Future] that completes when the string has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key invalid.
  Future<void> setString(String key, String value);

  /// Retrieves an [int] value by its [key].
  ///
  /// This method fetches an integer value previously stored using [setInt].
  /// If no value exists for the given key, or the stored value is not an integer,
  /// this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the integer value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored integer value if found,
  /// or `null` if the key doesn't exist or the value is not an integer.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<int?> getInt(String key);

  /// Saves an [int] value with the given [key].
  ///
  /// This method stores an integer value in the storage, associating it with the
  /// specified key. If a value already exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the integer value.
  /// * [value] - The integer value to store.
  ///
  /// Returns a [Future] that completes when the integer has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setInt(String key, int value);

  /// Retrieves a [double] value by its [key].
  ///
  /// This method fetches a double-precision floating-point value previously
  /// stored using [setDouble]. If no value exists for the given key, or the
  /// stored value is not a double, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the double value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored double value if found,
  /// or `null` if the key doesn't exist or the value is not a double.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<double?> getDouble(String key);

  /// Saves a [double] value with the given [key].
  ///
  /// This method stores a double-precision floating-point value in the storage,
  /// associating it with the specified key. If a value already exists for this
  /// key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the double value.
  /// * [value] - The double value to store.
  ///
  /// Returns a [Future] that completes when the double has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setDouble(String key, double value);

  /// Retrieves a [bool] value by its [key].
  ///
  /// This method fetches a boolean value previously stored using [setBool].
  /// If no value exists for the given key, or the stored value is not a boolean,
  /// this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the boolean value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored boolean value if found,
  /// or `null` if the key doesn't exist or the value is not a boolean.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<bool?> getBool(String key);

  /// Saves a [bool] value with the given [key].
  ///
  /// This method stores a boolean value in the storage, associating it with the
  /// specified key. If a value already exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the boolean value.
  /// * [value] - The boolean value to store.
  ///
  /// Returns a [Future] that completes when the boolean has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setBool(String key, bool value);

  /// Retrieves all key-value pairs from the storage.
  ///
  /// This method fetches all stored key-value pairs and returns them as a map.
  /// If an [allowList] is provided, only the key-value pairs whose keys are
  /// present in the allow list will be included in the result.
  ///
  /// Parameters:
  /// * [allowList] - Optional. An iterable of keys to filter the results. If
  ///   provided, only key-value pairs with keys in this list will be returned.
  ///   If `null` or not provided, all key-value pairs are returned.
  ///
  /// Returns a [Future] that completes with a map containing the requested
  /// key-value pairs. The map will be empty if no values exist or if none of
  /// the keys in the allow list are found.
  ///
  /// Throws:
  /// * [ArgumentError] if any key in the allow list is invalid.
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]);

  /// Saves multiple key-value pairs from a [Map] in a single operation.
  ///
  /// This method performs a batch write operation, storing multiple key-value
  /// pairs at once. This is more efficient than calling individual set methods
  /// for each pair. If any key already exists in storage, its value will be
  /// replaced.
  ///
  /// Parameters:
  /// * [values] - A map containing key-value pairs to store. The values can be
  ///   of any type supported by the storage implementation (typically String,
  ///   int, double, bool, List of String, or JSON map).
  ///
  /// Returns a [Future] that completes when all key-value pairs have been
  /// successfully stored.
  ///
  /// Throws:
  /// * [ArgumentError] if any key is invalid.
  Future<void> setAll(Map<String, dynamic> values);

  /// Saves a list of strings with the given [key].
  ///
  /// This method stores a list of string values in the storage, associating it
  /// with the specified key. If a value already exists for this key, it will be
  /// replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the string list.
  /// * [value] - The list of strings to store.
  ///
  /// Returns a [Future] that completes when the string list has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setStringList(String key, List<String> value);

  /// Retrieves a list of strings by its [key].
  ///
  /// This method fetches a list of strings previously stored using [setStringList].
  /// If no value exists for the given key, or the stored value is not a list of
  /// strings, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the string list to retrieve.
  ///
  /// Returns a [Future] that completes with the stored list of strings if found,
  /// or `null` if the key doesn't exist or the value is not a list of strings.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<List<String>?> getStringList(String key);

  /// Saves a JSON object (Map) with the given [key].
  ///
  /// This method stores a JSON-serializable map in the storage, associating it
  /// with the specified key. The map should contain only JSON-compatible types
  /// (String, int, double, bool, List, Map, or null). If a value already exists
  /// for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the JSON object.
  /// * [value] - The JSON object to store as a map with string keys and dynamic
  ///   values.
  ///
  /// Returns a [Future] that completes when the JSON object has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setJson(String key, Map<String, dynamic> value);

  /// Retrieves a JSON object by its [key].
  ///
  /// This method fetches a JSON object previously stored using [setJson].
  /// If no value exists for the given key, or the stored value is not a valid
  /// JSON object, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the JSON object to retrieve.
  ///
  /// Returns a [Future] that completes with the stored JSON object as a map if
  /// found, or `null` if the key doesn't exist or the value is not a valid JSON
  /// object.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<Map<String, dynamic>?> getJson(String key);

  /// Saves a list of JSON objects with the given [key].
  ///
  /// This method stores a list of JSON-serializable maps in the storage,
  /// associating it with the specified key. Each map should contain only
  /// JSON-compatible types (String, int, double, bool, List, Map, or null).
  /// If a value already exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the JSON object list.
  /// * [value] - The list of JSON objects to store.
  ///
  /// Returns a [Future] that completes when the JSON object list has been
  /// successfully stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value);

  /// Retrieves a list of JSON objects by its [key].
  ///
  /// This method fetches a list of JSON objects previously stored using
  /// [setJsonList]. If no value exists for the given key, or the stored value
  /// is not a valid list of JSON objects, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the JSON object list to retrieve.
  ///
  /// Returns a [Future] that completes with the stored list of JSON objects if
  /// found, or `null` if the key doesn't exist or the value is not a valid list
  /// of JSON objects.
  ///
  /// Throws:
  /// * [ArgumentError] if the key invalid.
  Future<List<Map<String, dynamic>>?> getJsonList(String key);

  /// Retrieves a [DateTime] value by its [key].
  ///
  /// This method fetches a DateTime value previously stored using [setDateTime].
  /// The DateTime is stored as an ISO 8601 string and reconstructed when
  /// retrieved. If no value exists for the given key, or the stored value cannot
  /// be parsed as a DateTime, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the DateTime value to retrieve.
  /// * [isUtc] - Optional. If `true`, the returned DateTime will be in UTC
  ///   timezone. If `false` (default), it will be in the local timezone.
  ///
  /// Returns a [Future] that completes with the stored DateTime value if found,
  /// or `null` if the key doesn't exist or the value cannot be parsed as a
  /// DateTime.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<DateTime?> getDateTime(String key, {bool isUtc = false});

  /// Saves a [DateTime] value with the given [key].
  ///
  /// This method stores a DateTime value in the storage by converting it to milliseconds
  /// since epoch format, associating it with the specified key. If a value
  /// already exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the DateTime value.
  /// * [value] - The DateTime value to store.
  ///
  /// Returns a [Future] that completes when the DateTime has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> setDateTime(String key, DateTime value);

  /// Retrieves a [Duration] value by its [key].
  ///
  /// This method fetches a Duration value previously stored using [setDuration].
  /// The Duration is stored as milliseconds and reconstructed when retrieved.
  /// If no value exists for the given key, or the stored value cannot be parsed
  /// as a Duration, this method returns `null`.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the Duration value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored Duration value if found,
  /// or `null` if the key doesn't exist or the value cannot be parsed as a
  /// Duration.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<Duration?> getDuration(String key);

  /// Saves a [Duration] value with the given [key].
  ///
  /// This method stores a Duration value in the storage by converting it to
  /// milliseconds, associating it with the specified key. If a value already
  /// exists for this key, it will be replaced.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the Duration value.
  /// * [value] - The Duration value to store.
  ///
  /// Returns a [Future] that completes when the Duration has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key invalid.
  Future<void> setDuration(String key, Duration value);

  /// Retrieves a value of type [E] by its [key].
  ///
  /// This is a generic method that attempts to retrieve a value and cast it to
  /// the specified type [E]. The actual behavior depends on the storage
  /// implementation, but typically it will return the value if it can be safely
  /// cast to type [E], or `null` otherwise.
  ///
  /// Type parameters:
  /// * [E] - The expected type of the value to retrieve.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the value to retrieve.
  ///
  /// Returns a [Future] that completes with the stored value cast to type [E] if
  /// found and the cast is successful, or `null` if the key doesn't exist or the
  /// value cannot be cast to type [E].
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<E?> get<E extends Object>(String key);

  /// Saves a value of type [E] with the given [key].
  ///
  /// This is a generic method that stores a value of any type [E] supported by
  /// the storage implementation. The actual supported types depend on the
  /// implementation, but typically include String, int, double, bool, List, and
  /// Map types. If a value already exists for this key, it will be replaced.
  ///
  /// Type parameters:
  /// * [E] - The type of the value to store.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the value.
  /// * [value] - The value to store.
  ///
  /// Returns a [Future] that completes when the value has been successfully
  /// stored.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> set<E extends Object>(String key, E value);

  /// Removes a value by its [key].
  ///
  /// This method deletes the key-value pair associated with the specified key
  /// from the storage. If no value exists for the given key, this method
  /// completes without error.
  ///
  /// Parameters:
  /// * [key] - The unique identifier of the value to remove.
  ///
  /// Returns a [Future] that completes when the value has been removed from
  /// storage.
  ///
  /// Throws:
  /// * [ArgumentError] if the key is invalid.
  Future<void> remove(String key);

  /// Removes multiple values by their keys in a single operation.
  ///
  /// This method performs a batch delete operation, removing all key-value pairs
  /// whose keys are in the provided iterable. This is more efficient than calling
  /// [remove] individually for each key. Keys that don't exist in storage are
  /// silently ignored.
  ///
  /// Parameters:
  /// * [keys] - An iterable of unique identifiers for the values to remove.
  ///
  /// Returns a [Future] that completes when all specified values have been
  /// removed from storage.
  ///
  /// Throws:
  /// * [ArgumentError] if any key is invalid.
  Future<void> removeAll(Iterable<String> keys);

  /// Returns a set of all keys currently stored in the storage.
  ///
  /// This method retrieves all the keys (identifiers) of values currently in
  /// storage. The returned set can be used to iterate over all stored values or
  /// to check which keys exist without retrieving the values themselves.
  ///
  /// Returns a [Future] that completes with a set containing all keys in storage.
  /// The set will be empty if the storage is empty.
  Future<Set<String>> getKeys();

  /// Removes all values from the storage.
  ///
  /// This method deletes all key-value pairs from the storage, effectively
  /// resetting it to an empty state. This operation is irreversible and should
  /// be used with caution.
  ///
  /// Returns a [Future] that completes when all values have been removed and
  /// the storage has been cleared.
  Future<void> clear();

  /// Closes the storage and releases any associated resources.
  ///
  /// This method should be called when the storage is no longer needed. It allows
  /// the implementation to clean up resources such as file handles, database
  /// connections, or cached data. After calling this method, no further operations
  /// should be performed on this storage instance.
  ///
  /// Returns a [Future] that completes when the storage has been closed and all
  /// resources have been released.
  Future<void> close();
}

/// A base class for storage implementations that use a [StorageBackend].
///
/// This class provides common functionality for storage classes that interact
/// with a backend storage system. It implements the [ListenableStorage] interface
/// to allow listening for changes in the storage.
///
/// The [backend] is required and must be provided when creating an instance
/// of a subclass.
abstract class BaseStorage with ListenableStorage {
  /// The backend storage system used for actual data persistence.
  ///
  /// This backend is responsible for the low-level storage operations.
  /// Subclasses of [BaseStorage] will use this backend to perform their
  /// storage tasks.
  @internal
  final StorageBackend backend;

  /// Creates a new instance of [BaseStorage] with the given [backend].
  BaseStorage({required this.backend});
}

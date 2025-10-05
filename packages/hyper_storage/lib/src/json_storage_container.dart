// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

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
///
/// Example:
/// ```dart
/// class User {
///   final String id;
///   final String name;
///
///   User(this.id, this.name);
///
///   factory User.fromJson(Map<String, dynamic> json) => User(
///     json['id'] as String,
///     json['name'] as String,
///   );
/// }
///
/// // Define a FromJson function
/// FromJson<User> userFromJson = (json) => User.fromJson(json);
/// // Or simply: FromJson<User> userFromJson = User.fromJson;
/// ```
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
///
/// Example:
/// ```dart
/// class User {
///   final String id;
///   final String name;
///
///   User(this.id, this.name);
///
///   Map<String, dynamic> toJson() => {
///     'id': id,
///     'name': name,
///   };
/// }
///
/// // Define a ToJson function
/// ToJson<User> userToJson = (user) => user.toJson();
/// // Or extract inline: ToJson<User> userToJson = (user) => {'id': user.id, 'name': user.name};
/// ```
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
/// ## Basic Usage
///
/// Define your data class with JSON serialization:
///
/// ```dart
/// class User {
///   final String id;
///   final String name;
///   final String email;
///   final int age;
///
///   User(this.id, this.name, this.email, this.age);
///
///   Map<String, dynamic> toJson() => {
///     'id': id,
///     'name': name,
///     'email': email,
///     'age': age,
///   };
///
///   factory User.fromJson(Map<String, dynamic> json) => User(
///     json['id'] as String,
///     json['name'] as String,
///     json['email'] as String,
///     json['age'] as int,
///   );
/// }
///
/// // Create a container
/// final users = await HyperStorage.jsonSerializableContainer<User>(
///   'users',
///   toJson: (user) => user.toJson(),
///   fromJson: (json) => User.fromJson(json),
///   idGetter: (user) => user.id,
/// );
///
/// // Store users
/// await users.add(User('1', 'John Doe', 'john@example.com', 30));
/// await users.add(User('2', 'Jane Smith', 'jane@example.com', 25));
///
/// // Retrieve users
/// final john = await users.get('1');
/// final allUsers = await users.getAll();
/// final userList = await users.getValues();
///
/// // Update a user
/// final updatedJohn = User('1', 'John Updated', 'john@example.com', 31);
/// await users.update(updatedJohn);
///
/// // Remove a user
/// await users.remove('1');
/// ```
///
/// ## ID Management
///
/// ### With idGetter (Recommended)
/// Extract IDs from your objects for consistent identification:
///
/// ```dart
/// final users = await HyperStorage.jsonSerializableContainer<User>(
///   'users',
///   toJson: (user) => user.toJson(),
///   fromJson: User.fromJson,
///   idGetter: (user) => user.id, // Extract ID from object
/// );
///
/// final user = User('123', 'John', 'john@example.com', 30);
/// await users.add(user); // Stored with ID '123' from user.id
/// ```
///
/// ### Without idGetter (Auto-Generated IDs)
/// Let the container generate random IDs:
///
/// ```dart
/// final notes = await HyperStorage.jsonSerializableContainer<Note>(
///   'notes',
///   toJson: (note) => note.toJson(),
///   fromJson: Note.fromJson,
///   // No idGetter - IDs will be generated
/// );
///
/// final note = Note('Hello World');
/// await notes.add(note); // Stored with generated ID like 'abc123def456'
/// ```
///
/// ## Batch Operations
///
/// Efficiently handle multiple objects:
///
/// ```dart
/// // Add multiple users at once
/// await users.addAll([
///   User('1', 'John', 'john@example.com', 30),
///   User('2', 'Jane', 'jane@example.com', 25),
///   User('3', 'Bob', 'bob@example.com', 35),
/// ]);
///
/// // Update multiple users
/// await users.updateAll([
///   updatedJohn,
///   updatedJane,
/// ]);
///
/// // Remove multiple users
/// await users.removeAll(['1', '2']);
///
/// // Or remove by object
/// await users.removeAllItems([john, jane]);
/// ```
///
/// ## Query Operations
///
/// ```dart
/// // Get all users
/// final allUsers = await users.getAll();
/// print('Total users: ${allUsers.length}');
///
/// // Get specific users
/// final someUsers = await users.getAll(['1', '2', '3']);
///
/// // Get just the values
/// final userList = await users.getValues();
///
/// // Get just the keys (IDs)
/// final userIds = await users.getKeys();
///
/// // Check if user exists
/// if (await users.containsKey('1')) {
///   print('User 1 exists');
/// }
///
/// // Check if empty
/// if (await users.isEmpty) {
///   print('No users stored');
/// }
/// ```
///
/// ## Change Notifications
///
/// Listen for changes to the container:
///
/// ```dart
/// // Listen to all changes
/// users.listen(() {
///   print('Users container changed');
/// });
///
/// // Listen to specific key
/// users.listenKey('user-123', () {
///   print('User 123 changed');
/// });
///
/// // Operations trigger listeners
/// await users.add(newUser); // Triggers global listeners
/// await users.update(existingUser); // Triggers both global and key listeners
/// ```
///
/// ## Advanced Features
///
/// ### Custom Random for Testing
/// ```dart
/// final users = await HyperStorage.jsonSerializableContainer<User>(
///   'users',
///   toJson: (user) => user.toJson(),
///   fromJson: User.fromJson,
///   seed: 42, // Deterministic ID generation for tests
/// );
/// ```
///
/// ### Custom Delimiter
/// ```dart
/// final users = await HyperStorage.jsonSerializableContainer<User>(
///   'users',
///   toJson: (user) => user.toJson(),
///   fromJson: User.fromJson,
///   delimiter: '/', // Use '/' instead of default delimiter
/// );
/// ```
///
/// ## Performance Considerations
///
/// - JSON serialization/deserialization happens on every read/write
/// - Use batch operations ([addAll], [setAll]) for better performance
/// - Consider caching frequently accessed objects in memory
/// - The container caches encoded keys but not serialized objects
///
/// ## Type Safety
///
/// The container is type-safe and will only accept objects of type [T]:
///
/// ```dart
/// final users = await HyperStorage.jsonSerializableContainer<User>(...);
///
/// await users.add(user);        // OK
/// await users.add(product);     // Compile error - wrong type
/// ```
///
/// ## Error Handling
///
/// ```dart
/// try {
///   await users.update(nonExistentUser); // Throws StateError
/// } on StateError catch (e) {
///   print('User does not exist: $e');
/// }
///
/// try {
///   await users.set('', user); // Throws ArgumentError
/// } on ArgumentError catch (e) {
///   print('Invalid key: $e');
/// }
/// ```
///
/// See also:
/// - [SerializableStorageContainer] for the base class
/// - [HyperStorage.jsonSerializableContainer] for creating instances
/// - [FromJson] and [ToJson] typedefs for serialization functions
/// - [IdGetter] for custom ID extraction
final class JsonStorageContainer<T> extends SerializableStorageContainer<T> {
  /// The function used to convert objects of type [T] to JSON maps.
  ///
  /// This function is called internally whenever an object needs to be
  /// serialized for storage. The resulting map is encoded to a JSON string
  /// using [jsonEncode] before being passed to the backend.
  ///
  /// The function should return a map containing only JSON-serializable
  /// values (String, num, bool, List, Map, or null).
  final ToJson<T> toJson;

  /// The function used to convert JSON maps back to objects of type [T].
  ///
  /// This function is called internally whenever a stored object needs to be
  /// retrieved. The JSON string from storage is first decoded using
  /// [jsonDecode], and the resulting map is passed to this function to
  /// reconstruct the object.
  ///
  /// The function should handle all fields present in the JSON map and
  /// construct a valid object of type [T].
  final FromJson<T> fromJson;

  /// Creates a new [JsonStorageContainer] for storing objects of type [T].
  ///
  /// This constructor sets up a container that automatically handles JSON
  /// serialization and deserialization of objects. The container can either
  /// use custom ID extraction (via [idGetter]) or generate random IDs
  /// automatically.
  ///
  /// Type parameter [T] specifies the type of objects to store. The type must
  /// be serializable to/from JSON using the provided [toJson] and [fromJson]
  /// functions.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend that handles actual persistence.
  ///   * [toJson] - A function that converts objects of type [T] to JSON maps.
  ///     Called when storing objects.
  ///   * [fromJson] - A function that converts JSON maps back to objects of
  ///     type [T]. Called when retrieving objects.
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
  /// Example:
  /// ```dart
  /// // With ID extraction
  /// final users = JsonStorageContainer<User>(
  ///   backend: myBackend,
  ///   name: 'users',
  ///   toJson: (user) => user.toJson(),
  ///   fromJson: User.fromJson,
  ///   idGetter: (user) => user.id,
  /// );
  ///
  /// // With auto-generated IDs
  /// final notes = JsonStorageContainer<Note>(
  ///   backend: myBackend,
  ///   name: 'notes',
  ///   toJson: (note) => note.toJson(),
  ///   fromJson: Note.fromJson,
  /// );
  ///
  /// // With custom seed for testing
  /// final testContainer = JsonStorageContainer<User>(
  ///   backend: testBackend,
  ///   name: 'test_users',
  ///   toJson: (user) => user.toJson(),
  ///   fromJson: User.fromJson,
  ///   seed: 42, // Deterministic IDs
  /// );
  /// ```
  ///
  /// Note: Typically, you would create containers using
  /// [HyperStorage.jsonSerializableContainer] rather than calling this
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
  T deserialize(String value) => fromJson(jsonDecode(value));

  @override
  String serialize(T value) => jsonEncode(toJson(value));
}

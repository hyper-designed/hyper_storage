import 'package:meta/meta.dart';

import 'backend.dart';
import 'listenable.dart';

/// An abstract base class that provides a container for storing key-value pairs
/// with namespace isolation.
///
/// A [StorageContainer] creates a sandboxed environment for storing data,
/// ensuring that keys within one container don't conflict with keys in other
/// containers. Each container has a unique name and uses a delimiter to
/// separate the container namespace from the actual key.
///
/// - Each container operates in its own namespace, preventing key collisions between different containers.
///
/// ## Validation Rules
///
/// ### Container Names
/// - Must not be empty
/// - Must not be only whitespace
/// - Must not contain the delimiter character
///
/// ### Keys
/// - Must not be empty
/// - Must not be only whitespace
/// - Must not contain the delimiter character
///
/// ### Delimiters
/// - Must not be empty
/// - Must not be only whitespace
/// - Must match [allowedDelimiterRegex]
/// - Allowed characters: - _ / , = + | * & ^ % $ # @ !
///
/// See also:
/// - [StorageBackend] for the backend interface
/// - [ListenableStorage] for listener functionality
/// - [SerializableStorageContainer] for object storage
@protected
@internal
abstract class StorageContainer with ListenableStorage {
  /// The name of the storage container, used for namespacing keys.
  ///
  /// This name is prepended to all keys stored in this container, creating
  /// a namespace that isolates this container's data from other containers
  /// using the same backend.
  final String name;

  /// The character(s) used to separate the container name from the key.
  ///
  /// This delimiter is inserted between the container name and the actual key
  /// when encoding keys. It must be a character (or sequence) that won't
  /// appear in container names or keys to ensure proper isolation.
  final String delimiter;

  /// The storage backend used to persist data.
  ///
  /// This backend provides the actual storage implementation (e.g., shared
  /// preferences, Hive, in-memory storage). The container uses this backend
  /// to perform all read/write operations with properly encoded keys.
  @protected
  final StorageBackend backend;

  /// The default delimiter to use if one is not provided.
  ///
  /// When creating a container without specifying a delimiter, this default
  /// value ("___") is used. The dot character is chosen as it's commonly used
  /// for namespacing and is unlikely to appear in most keys.
  static const defaultDelimiter = '___';

  /// A regular expression that matches all allowed delimiter characters.
  ///
  /// Delimiters must match this pattern to be considered valid. This ensures
  /// delimiters are special characters that won't accidentally appear in
  /// container names or keys.
  ///
  /// Allowed characters: - _ / , = + | * & ^ % $ # @ !
  static final RegExp allowedDelimiterRegex = RegExp(r'^[-_/,=+|*&^%$#@!]+$');

  /// Creates a new [StorageContainer].
  ///
  /// The constructor initializes a storage container with the specified backend
  /// and name, optionally using a custom delimiter for key encoding. It
  /// automatically validates the delimiter and container name during
  /// construction.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend to use for persistence operations.
  ///   * [name] - The name of the container, used for namespacing keys. Must
  ///     be non-empty, not only whitespace, and must not contain the delimiter.
  ///   * [delimiter] - Optional. The character(s) used to separate the
  ///     container name from keys. If not provided, [defaultDelimiter] (".")
  ///     is used. Must match [allowedDelimiterRegex].
  ///
  /// Throws:
  ///   * [ArgumentError] if the delimiter is invalid (empty, whitespace-only,
  ///     or contains disallowed characters)
  ///   * [ArgumentError] if the name is invalid (empty, whitespace-only, or
  ///     contains the delimiter)
  StorageContainer({
    required this.backend,
    required this.name,
    String? delimiter,
  }) : delimiter = delimiter ?? defaultDelimiter {
    validateDelimiter(this.delimiter);
    validateName(name);
  }

  /// Validates the given [delimiter] to ensure it meets requirements.
  ///
  /// This method checks that the delimiter is not empty, not only whitespace,
  /// and contains only allowed characters. It's called automatically during
  /// container construction but can also be used for explicit validation.
  ///
  /// Parameters:
  ///   * [delimiter] - The delimiter string to validate (note: this parameter
  ///     is not used; the method validates `this.delimiter` instead).
  ///
  /// Throws:
  ///   * [ArgumentError] with message "Delimiter cannot be empty" if the
  ///     delimiter is an empty string
  ///   * [ArgumentError] with message "Delimiter cannot be only whitespace" if
  ///     the delimiter contains only whitespace characters
  ///   * [ArgumentError] with a descriptive message if the delimiter contains
  ///     characters not matching [allowedDelimiterRegex]
  @protected
  @visibleForTesting
  @internal
  void validateDelimiter(String delimiter) {
    if (this.delimiter.isEmpty) throw ArgumentError('Delimiter cannot be empty');
    if (this.delimiter.trim().isEmpty) throw ArgumentError('Delimiter cannot be only whitespace');
    if (!allowedDelimiterRegex.hasMatch(this.delimiter)) {
      throw ArgumentError(
        'Delimiter contains invalid characters: ${this.delimiter}. Allowed characters are: - _ / , = + | * & ^ % \$ # @ !',
      );
    }
  }

  /// Validates the given container [name] to ensure it meets requirements.
  ///
  /// This method checks that the container name is not empty, not only
  /// whitespace, and doesn't contain the delimiter character. It's called
  /// automatically during container construction but can also be used for
  /// explicit validation.
  ///
  /// Parameters:
  ///   * [name] - The container name to validate.
  ///
  /// Throws:
  ///   * [ArgumentError] with message "Container name cannot be empty" if the
  ///     name is an empty string
  ///   * [ArgumentError] with message "Container name cannot be only
  ///     whitespace" if the name contains only whitespace characters
  ///   * [ArgumentError] with a descriptive message if the name contains the
  ///     delimiter character
  ///
  @protected
  @visibleForTesting
  void validateName(String name) {
    if (name.isEmpty) throw ArgumentError('Container name cannot be empty');
    if (name.trim().isEmpty) throw ArgumentError('Container name cannot be only whitespace');
    if (name.contains(delimiter)) {
      throw ArgumentError('Container name cannot contain delimiter "$delimiter": $name');
    }
  }

  /// Validates the given storage [key] to ensure it meets requirements.
  ///
  /// This method checks that the key is not empty, not only whitespace, and
  /// doesn't contain the delimiter character. It's called automatically by
  /// methods that accept keys (like [encodeKey]) but can also be used for
  /// explicit validation.
  ///
  /// Parameters:
  ///   * [key] - The storage key to validate.
  ///
  /// Throws:
  ///   * [ArgumentError] with message "Key cannot be empty" if the key is an
  ///     empty string
  ///   * [ArgumentError] with message "Key cannot be only whitespace" if the
  ///     key contains only whitespace characters
  ///   * [ArgumentError] with a descriptive message if the key contains the
  ///     delimiter character
  ///
  /// See also:
  /// - [validateKeys] for validating multiple keys at once
  /// - [encodeKey] which calls this method automatically
  @protected
  @visibleForTesting
  @internal
  void validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('Key cannot be empty');
    if (key.trim().isEmpty) throw ArgumentError('Key cannot be only whitespace');
    if (key.contains(delimiter)) throw ArgumentError('Key cannot contain delimiter "$delimiter": $key');
  }

  /// Validates a collection of storage [keys] to ensure they all meet
  /// requirements.
  ///
  /// This method iterates through the provided keys and validates each one
  /// using [validateKey]. If the keys parameter is null or empty, the method
  /// returns without performing any validation.
  ///
  /// Parameters:
  ///   * [keys] - Optional. An iterable of storage keys to validate. If null
  ///     or empty, no validation is performed.
  ///
  /// Throws:
  ///   * [ArgumentError] if any key in the collection fails validation (see
  ///     [validateKey] for specific validation rules)
  ///
  /// See also:
  /// - [validateKey] which validates a single key
  @protected
  @visibleForTesting
  void validateKeys(Iterable<String>? keys) {
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      validateKey(key);
    }
  }

  /// Encodes a key by prepending the container name and delimiter.
  ///
  /// This method transforms a regular key into a namespaced key by adding the
  /// container name and delimiter as a prefix. This ensures that keys from
  /// different containers don't collide in the shared backend storage.
  ///
  /// Parameters:
  ///   * [key] - The key to encode. Must be non-empty, not only whitespace,
  ///     and must not contain the delimiter.
  ///
  /// Returns:
  ///   The encoded key in the format: `{name}{delimiter}{key}`
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is invalid (see [validateKey] for rules)
  ///
  /// See also:
  /// - [decodeKey] for the reverse operation
  /// - [validateKey] which is called automatically
  @protected
  @visibleForTesting
  @internal
  String encodeKey(String key) {
    validateKey(key);
    return '$name$delimiter$key';
  }

  /// Decodes a key by removing the container name and delimiter prefix.
  ///
  /// This method performs the reverse operation of [encodeKey], extracting the
  /// original key from an encoded key. If the provided key doesn't start with
  /// the expected prefix (`{name}{delimiter}`), it returns the key unchanged.
  ///
  /// Parameters:
  ///   * [key] - The encoded key to decode.
  ///
  /// Returns:
  ///   The decoded key with the container prefix removed, or the original key
  ///   if it doesn't have the expected prefix.
  ///
  /// See also:
  /// - [encodeKey] for the reverse operation
  /// - [_isAssociatedKey] for checking if a key belongs to this container
  @protected
  @visibleForTesting
  @internal
  String decodeKey(String key) =>
      key.startsWith('$name$delimiter') ? key.substring(name.length + delimiter.length) : key;

  /// Determines whether the given [rawKey] belongs to this container.
  ///
  /// This internal method checks if a raw key from the backend storage belongs
  /// to this container by verifying it starts with the container's name and
  /// delimiter prefix.
  ///
  /// Parameters:
  ///   * [rawKey] - The raw key from the backend to check.
  ///
  /// Returns:
  ///   `true` if the key belongs to this container, `false` otherwise.
  ///
  /// Throws:
  ///   * [StateError] if the container name is empty or only whitespace when
  ///     performing the check. This should never happen in normal operation as
  ///     the name is validated during construction.
  bool _isAssociatedKey(String rawKey) {
    if (name.isEmpty) throw StateError('Container name cannot be empty when checking associated keys.');
    if (name.trim().isEmpty) {
      throw StateError('Container name cannot be only whitespace when checking associated keys.');
    }
    return rawKey.startsWith('$name$delimiter');
  }

  /// Returns a set of all encoded keys in the container.
  ///
  /// This method retrieves all keys from the backend storage and filters them
  /// to include only keys that belong to this container (i.e., keys that start
  /// with the container's name and delimiter). The returned keys are still in
  /// their encoded form with the container prefix.
  ///
  /// Returns:
  ///   A future that completes with a set of encoded keys belonging to this
  ///   container. The keys are in the format: `{name}{delimiter}{key}`
  ///
  /// See also:
  /// - [getDecodedKeys] for getting keys without the container prefix
  /// - [_isAssociatedKey] which is used for filtering
  @protected
  Future<Set<String>> getEncodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(_isAssociatedKey).toSet();
  }

  /// Returns a set of all decoded keys in the container.
  ///
  /// This method retrieves all keys from the backend storage, filters them to
  /// include only keys belonging to this container, and decodes them by
  /// removing the container prefix. The returned keys are in their original
  /// form without the container namespace.
  ///
  /// Returns:
  ///   A future that completes with a set of decoded keys belonging to this
  ///   container. The keys have the container prefix removed.
  ///
  /// See also:
  /// - [getEncodedKeys] for getting keys with the container prefix
  /// - [decodeKey] which is used to decode each key
  /// - [_isAssociatedKey] which is used for filtering
  @protected
  Future<Set<String>> getDecodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(_isAssociatedKey).map(decodeKey).toSet();
  }

  /// Clears all data stored in this container.
  ///
  /// This only should remove keys associated with this container, leaving
  /// other containers' data intact.
  Future<void> clear();

  /// Closes the container and releases any resources.
  ///
  /// This abstract method must be implemented by subclasses to provide cleanup
  /// logic when the container is no longer needed. Implementations should:
  /// - Remove all listeners using [removeAllListeners]
  /// - Close the backend if appropriate
  /// - Release any other resources
  ///
  /// After calling this method, the container should not be used.
  ///
  /// Returns:
  ///   A future that completes when the container has been closed and all
  ///   resources have been released.
  Future<void> close();
}

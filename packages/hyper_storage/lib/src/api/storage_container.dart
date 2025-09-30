import 'package:meta/meta.dart';

import 'backend.dart';
import 'listenable.dart';

@protected
abstract class StorageContainer with ListenableStorage {
  /// The name of the storage backend, used for namespacing keys.
  final String name;
  final String delimiter;

  @protected
  final StorageBackend backend;

  static const defaultDelimiter = '.';

  static final RegExp allowedDelimiterRegex = RegExp(r'^[-_/,=+|*&^%$#@!]+$');

  StorageContainer({
    required this.backend,
    required this.name,
    String? delimiter,
  }) : delimiter = delimiter ?? defaultDelimiter {
    validateDelimiter(this.delimiter);
    validateName(name);
  }

  @protected
  @visibleForTesting
  void validateDelimiter(String delimiter) {
    if (this.delimiter.isEmpty) throw ArgumentError('Delimiter cannot be empty');
    if (this.delimiter.trim().isEmpty) throw ArgumentError('Delimiter cannot be only whitespace');
    if (!allowedDelimiterRegex.hasMatch(this.delimiter)) {
      throw ArgumentError(
        'Delimiter contains invalid characters: ${this.delimiter}. Allowed characters are: - _ / , = + | * & ^ % \$ # @ !',
      );
    }
  }

  @protected
  @visibleForTesting
  void validateName(String name) {
    if (name.isEmpty) throw ArgumentError('Container name cannot be empty');
    if (name.trim().isEmpty) throw ArgumentError('Container name cannot be only whitespace');
    if (name.contains(delimiter)) {
      throw ArgumentError('Container name cannot contain delimiter "$delimiter": $name');
    }
  }

  @protected
  @visibleForTesting
  void validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('Key cannot be empty');
    if (key.trim().isEmpty) throw ArgumentError('Key cannot be only whitespace');
    if (key.contains(delimiter)) throw ArgumentError('Key cannot contain delimiter "$delimiter": $key');
  }

  @protected
  @visibleForTesting
  void validateKeys(Iterable<String>? keys) {
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      validateKey(key);
    }
  }

  @protected
  @visibleForTesting
  String encodeKey(String key) {
    validateKey(key);
    return '$name$delimiter$key';
  }

  @protected
  @visibleForTesting
  String decodeKey(String key) =>
      key.startsWith('$name$delimiter') ? key.substring(name.length + delimiter.length) : key;

  /// Whether the given [rawKey] is associated with this container or not.
  bool _isAssociatedKey(String rawKey) {
    if (name.isEmpty) throw StateError('Container name cannot be empty when checking associated keys.');
    if (name.trim().isEmpty) {
      throw StateError('Container name cannot be only whitespace when checking associated keys.');
    }
    return rawKey.startsWith('$name$delimiter');
  }

  @protected
  Future<Set<String>> getEncodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(_isAssociatedKey).toSet();
  }

  @protected
  Future<Set<String>> getDecodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(_isAssociatedKey).map(decodeKey).toSet();
  }

  Future<void> close();
}

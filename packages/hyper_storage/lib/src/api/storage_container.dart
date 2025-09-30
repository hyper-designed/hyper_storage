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

  StorageContainer({
    required this.backend,
    required this.name,
    String? delimiter,
  }) : delimiter = delimiter ?? '.' {
    if (name.contains(this.delimiter)) {
      throw ArgumentError('Container name cannot contain delimiter "${this.delimiter}": $name');
    }
  }

  @protected
  String encodeKey(String key) {
    _validateKey(key);
    return name.isEmpty ? key : '$name$delimiter$key';
  }

  void _validateKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    if (key.length > 255) {
      throw ArgumentError('Key too long (max 255 characters): ${key.length}');
    }
    if (key.contains(delimiter)) {
      throw ArgumentError('Key cannot contain delimiter "$delimiter": $key');
    }
  }

  @protected
  String decodeKey(String key) =>
      key.startsWith('$name$delimiter') ? key.substring(name.length + delimiter.length) : key;

  /// Whether the given [rawKey] is associated with this container or not.
  @protected
  bool isAssociatedKey(String rawKey) {
    if (name == '') return !rawKey.contains(delimiter);
    return rawKey.startsWith('$name$delimiter');
  }

  @protected
  Future<Set<String>> getEncodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(isAssociatedKey).toSet();
  }

  @protected
  Future<Set<String>> getDecodedKeys() async {
    final allKeys = await backend.getKeys();
    return allKeys.where(isAssociatedKey).map(decodeKey).toSet();
  }

  Future<void> close();
}

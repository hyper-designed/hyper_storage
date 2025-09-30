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
  }) : delimiter = delimiter ?? '.';

  @protected
  String encodeKey(String key) => name.isEmpty ? key : '$name$delimiter$key';

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

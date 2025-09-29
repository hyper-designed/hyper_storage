import 'package:meta/meta.dart';

import '../backend/api.dart';
import '../backend/backend.dart';

@protected
abstract class StorageContainerBase implements DataAPIBase {
  /// The name of the storage backend, used for namespacing keys.
  final String name;
  final String delimiter;

  @protected
  final StorageBackend backend;

  StorageContainerBase({
    required this.backend,
    required this.name,
    this.delimiter = '.',
  });

  @protected
  String encodeKey(String key) => name.isEmpty ? key : '$name.$key';

  @protected
  String decodeKey(String key) => key.startsWith('$name.') ? key.substring(name.length + 1) : key;

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
}

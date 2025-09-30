import 'dart:convert';

import 'package:meta/meta.dart';

import 'api/api.dart';
import 'api/backend.dart';
import 'json_storage_container.dart';

class HyperStorageItemHolder<E> implements ItemHolderApi<E> {
  final String _encodedKey;
  final String key;
  final FromJson<E> fromJson;
  final ToJson<E> toJson;
  final StorageBackend _backend;
  final void Function() onChanged;

  @protected
  HyperStorageItemHolder(
    this._backend,
    this._encodedKey, {
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.onChanged,
  });

  @override
  Future<bool> get exists => _backend.containsKey(_encodedKey);

  @override
  Future<E?> get() async {
    final String? jsonString = await _backend.getString(_encodedKey);
    if (jsonString == null) return null;
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return fromJson(json);
  }

  @override
  Future<void> set(E value) async {
    final String jsonString = jsonEncode(toJson(value));
    await _backend.setString(_encodedKey, jsonString);
    onChanged();
  }

  @override
  Future<void> remove() async {
    await _backend.remove(_encodedKey);
    onChanged();
  }
}

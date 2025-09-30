import 'dart:convert';

import 'package:meta/meta.dart' show protected;

import 'api/backend.dart';
import 'api/storage_container.dart';
import 'item_holder.dart';
import 'json_storage_container.dart';

class HyperStorageContainer extends StorageContainer with GenericStorageOperationsMixin {
  @protected
  HyperStorageContainer({
    required super.backend,
    required super.name,
    super.delimiter,
  });

  @override
  Future<Set<String>> getKeys() => getDecodedKeys();

  @override
  Future<void> remove(String key) async {
    await backend.remove(encodeKey(key));
    notifyListeners(key);
  }

  @override
  Future<void> clear() async {
    final encodedKeys = await getEncodedKeys();
    final decodedKeys = encodedKeys.map(decodeKey);
    await backend.removeAll(encodedKeys);
    for (final key in decodedKeys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
    removeAllListeners();
  }

  @override
  Future<bool> containsKey(String key) => backend.containsKey(encodeKey(key));

  @override
  Future<String?> getString(String key) => backend.getString(encodeKey(key));

  @override
  Future<int?> getInt(String key) => backend.getInt(encodeKey(key));

  @override
  Future<double?> getDouble(String key) => backend.getDouble(encodeKey(key));

  @override
  Future<bool?> getBool(String key) => backend.getBool(encodeKey(key));

  @override
  Future<void> setString(String key, String value) async {
    await backend.setString(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await backend.setInt(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await backend.setDouble(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await backend.setBool(encodeKey(key), value);
    notifyListeners(key);
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    final map = await backend.getAll(allowList?.map(encodeKey) ?? await getEncodedKeys());
    return {for (final entry in map.entries) decodeKey(entry.key): entry.value};
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    final mapWithEncodedKeys = {
      for (final entry in values.entries) encodeKey(entry.key): entry.value,
    };
    await backend.setAll(mapWithEncodedKeys);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final String? dataString = await backend.getString(encodeKey(key));
    if (dataString == null) return null;
    return List<String>.from(jsonDecode(dataString) as List<dynamic>);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return null;
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return isUtc ? dateTime : dateTime.toLocal();
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    await backend.setInt(
      encodeKey(key),
      value.isUtc ? value.millisecondsSinceEpoch : value.toUtc().millisecondsSinceEpoch,
    );
    notifyListeners(key);
  }

  @override
  Future<Duration> getDuration(String key) async {
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return Duration.zero;
    return Duration(milliseconds: millis);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    await backend.setInt(encodeKey(key), value.inMilliseconds);
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    await backend.removeAll(keys.map(encodeKey));
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> close() async {
    removeAllListeners();
    await backend.close();
  }

  /// Allows to easily store and retrieve serializable objects in the storage for given key.
  Future<HyperStorageItemHolder<T>> keyHolder<T>(
    String key, {
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
  }) async => HyperStorageItemHolder<T>(
    backend,
    encodeKey(key),
    key: key,
    fromJson: fromJson,
    toJson: toJson,
    onChanged: () => notifyListeners(key),
  );
}

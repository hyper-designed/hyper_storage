import 'dart:convert';

import 'package:meta/meta.dart' show protected;

import '../../hyper_storage.dart';
import '../backend/api.dart';
import '../backend/listenable.dart';
import 'storage_container_base.dart';

class HyperStorageContainer extends StorageContainerBase with ListenableStorage implements DataAPI {
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

  Future<void> setStringList(String key, List<String> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  Future<List<String>?> getStringList(String key) async {
    final String? dataString = await backend.getString(encodeKey(key));
    if (dataString == null) return null;
    return List<String>.from(jsonDecode(dataString) as List<dynamic>);
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await backend.setString(encodeKey(key), jsonEncode(value));
    notifyListeners(key);
  }

  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final jsonString = await backend.getString(encodeKey(key));
    if (jsonString == null) return null;
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<E?> get<E>(String key) async {
    return switch (E) {
      const (String) => await getString(key) as E?,
      const (int) => await getInt(key) as E?,
      const (double) => await getDouble(key) as E?,
      const (num) => await getDouble(key) as E?,
      const (bool) => await getBool(key) as E?,
      const (List<String>) => await getStringList(key) as E?,
      const (Map<String, dynamic>) => await getJson(key) as E?,
      const (List<Map<String, dynamic>>) => await getJsonList(key) as E?,
      const (DateTime) => await getDateTime(key) as E?,
      const (Duration) => await getDuration(key) as E?,
      _ => throw UnsupportedError('Unsupported type: $E'),
    };
  }

  Future<void> set<E>(String key, E value) async {
    await switch (value) {
      String value => setString(key, value),
      int value => setInt(key, value),
      double value => setDouble(key, value),
      bool value => setBool(key, value),
      List<String> value => setStringList(key, value),
      Map<String, dynamic> value => setJson(key, value),
      List<Map<String, dynamic>> value => setJsonList(key, value),
      DateTime value => setDateTime(key, value),
      Duration value => setDuration(key, value),
      _ => throw UnsupportedError('Unsupported type: $E'),
    };
    notifyKeyListeners(key);
  }

  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) async {
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return null;
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return isUtc ? dateTime : dateTime.toLocal();
  }

  Future<void> setDateTime(String key, DateTime value) async {
    await backend.setInt(
      encodeKey(key),
      value.isUtc ? value.millisecondsSinceEpoch : value.toUtc().millisecondsSinceEpoch,
    );
    notifyListeners(key);
  }

  Future<Duration> getDuration(String key) async {
    final int? millis = await backend.getInt(encodeKey(key));
    if (millis == null) return Duration.zero;
    return Duration(milliseconds: millis);
  }

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

  /// Allows to easily store and retrieve serializable objects in the storage for given key.
  Future<LocalStorageItemHolder<T>> keyHolder<T>(
    String key, {
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
  }) async => LocalStorageItemHolder<T>._(
    backend,
    encodeKey(key),
    key: key,
    fromJson: fromJson,
    toJson: toJson,
    onChanged: () => notifyListeners(key),
  );

  @override
  Future<void> close() async {
    removeAllListeners();
    await backend.close();
  }
}

class LocalStorageItemHolder<T> {
  final String _encodedKey;
  final String key;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final StorageBackend _backend;
  final void Function() onChanged;

  LocalStorageItemHolder._(
    this._backend,
    this._encodedKey, {
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.onChanged,
  });

  Future<bool> get exists => _backend.containsKey(_encodedKey);

  Future<T?> get() async {
    final String? jsonString = await _backend.getString(_encodedKey);
    if (jsonString == null) return null;
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return fromJson(json);
  }

  Future<void> set(T value) async {
    final String jsonString = jsonEncode(toJson(value));
    await _backend.setString(_encodedKey, jsonString);
    onChanged();
  }

  Future<void> remove() async {
    await _backend.remove(_encodedKey);
    onChanged();
  }
}

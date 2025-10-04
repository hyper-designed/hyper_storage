import 'package:shared_preferences/shared_preferences.dart';

/// A mock implementation of SharedPreferencesAsync for testing purposes.
///
/// This class provides an in-memory implementation that mimics the behavior
/// of SharedPreferencesAsync without requiring platform channels.
class MockSharedPreferencesAsync implements SharedPreferencesAsync {
  final Map<String, Object> _data = {};

  @override
  Future<void> clear({Set<String>? allowList}) async {
    if (allowList == null || allowList.isEmpty) {
      _data.clear();
    } else {
      _data.removeWhere((key, value) => allowList.contains(key));
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    return _data.containsKey(key);
  }

  @override
  Future<bool?> getBool(String key) async {
    final value = _data[key];
    return value is bool ? value : null;
  }

  @override
  Future<double?> getDouble(String key) async {
    final value = _data[key];
    return value is double ? value : null;
  }

  @override
  Future<int?> getInt(String key) async {
    final value = _data[key];
    return value is int ? value : null;
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async {
    if (allowList == null || allowList.isEmpty) {
      return _data.keys.toSet();
    }
    return _data.keys.where((key) => allowList.contains(key)).toSet();
  }

  @override
  Future<String?> getString(String key) async {
    final value = _data[key];
    return value is String ? value : null;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _data[key];
    return value is List<String> ? value : null;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _data[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
  }

  @override
  Future<Map<String, Object>> getAll({Set<String>? allowList}) async {
    if (allowList == null || allowList.isEmpty) {
      return Map.from(_data);
    }
    return Map.fromEntries(
      _data.entries.where((entry) => allowList.contains(entry.key)),
    );
  }
}

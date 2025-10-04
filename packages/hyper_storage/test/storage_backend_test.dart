import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

/// A minimal backend that only implements the required abstract methods,
/// allowing us to test the default implementations in StorageBackend.
class MinimalBackend extends StorageBackend {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> close() async {
    _data.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<double?> getDouble(String key) async => _data[key] as double?;

  @override
  Future<int?> getInt(String key) async => _data[key] as int?;

  @override
  Future<Set<String>> getKeys() async => _data.keys.toSet();

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      _data.remove(key);
    }
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
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) async {
    if (allowList == null) return Map.from(_data);
    return {
      for (final key in allowList)
        if (_data.containsKey(key)) key: _data[key],
    };
  }
}

void main() {
  group('StorageBackend default implementations', () {
    late MinimalBackend backend;

    setUp(() async {
      backend = MinimalBackend();
      await backend.init();
    });

    tearDown(() async {
      await backend.close();
    });

    group('initialization', () {
      test('init() completes successfully', () async {
        final newBackend = MinimalBackend();
        await expectLater(newBackend.init(), completes);
        await newBackend.close();
      });
    });

    group('container creation', () {
      test('container() creates a container with the given name', () async {
        final container = await backend.container('test');
        expect(container.name, 'test');
        await container.close();
      });

      test('container() uses the backend', () async {
        final container = await backend.container('test');
        expect(container.backend, backend);
        await container.close();
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty returns true when no keys exist', () async {
        expect(await backend.isEmpty, true);
      });

      test('isEmpty returns false when keys exist', () async {
        await backend.setString('key', 'value');
        expect(await backend.isEmpty, false);
      });

      test('isNotEmpty returns false when no keys exist', () async {
        expect(await backend.isNotEmpty, false);
      });

      test('isNotEmpty returns true when keys exist', () async {
        await backend.setString('key', 'value');
        expect(await backend.isNotEmpty, true);
      });
    });

    group('setAll', () {
      test('stores multiple values', () async {
        await backend.setAll({'key1': 'value1', 'key2': 42, 'key3': true});

        expect(await backend.getString('key1'), 'value1');
        expect(await backend.getInt('key2'), 42);
        expect(await backend.getBool('key3'), true);
      });

      test('handles empty map', () async {
        await expectLater(backend.setAll({}), completes);
      });
    });

    group('StringList operations', () {
      test('setStringList stores list as JSON', () async {
        await backend.setStringList('list', ['a', 'b', 'c']);
        final stored = await backend.getString('list');
        expect(stored, isNotNull);
        expect(stored, contains('a'));
      });

      test('getStringList retrieves list', () async {
        await backend.setStringList('list', ['a', 'b', 'c']);
        final result = await backend.getStringList('list');
        expect(result, ['a', 'b', 'c']);
      });

      test('getStringList returns null for non-existent key', () async {
        expect(await backend.getStringList('missing'), null);
      });

      test('getStringList returns null for non-list value', () async {
        await backend.setString('notlist', 'just a string');
        expect(await backend.getStringList('notlist'), null);
      });
    });

    group('JSON operations', () {
      test('setJson stores map as JSON', () async {
        await backend.setJson('json', {'name': 'test', 'value': 42});
        final stored = await backend.getString('json');
        expect(stored, isNotNull);
        expect(stored, contains('test'));
      });

      test('getJson retrieves map', () async {
        await backend.setJson('json', {'name': 'test', 'value': 42});
        final result = await backend.getJson('json');
        expect(result, {'name': 'test', 'value': 42});
      });

      test('getJson returns null for non-existent key', () async {
        expect(await backend.getJson('missing'), null);
      });

      test('getJson returns null for non-map value', () async {
        await backend.setString('notmap', '["array"]');
        expect(await backend.getJson('notmap'), null);
      });
    });

    group('JsonList operations', () {
      test('setJsonList stores list of maps as JSON', () async {
        await backend.setJsonList('list', [
          {'id': 1, 'name': 'first'},
          {'id': 2, 'name': 'second'},
        ]);
        final stored = await backend.getString('list');
        expect(stored, isNotNull);
        expect(stored, contains('first'));
      });

      test('getJsonList retrieves list of maps', () async {
        await backend.setJsonList('list', [
          {'id': 1, 'name': 'first'},
          {'id': 2, 'name': 'second'},
        ]);
        final result = await backend.getJsonList('list');
        expect(result, [
          {'id': 1, 'name': 'first'},
          {'id': 2, 'name': 'second'},
        ]);
      });

      test('getJsonList returns null for non-existent key', () async {
        expect(await backend.getJsonList('missing'), null);
      });

      test('getJsonList returns null for non-list value', () async {
        await backend.setString('notlist', '{"not":"list"}');
        expect(await backend.getJsonList('notlist'), null);
      });
    });

    group('DateTime operations', () {
      test('setDateTime stores DateTime as milliseconds', () async {
        final now = DateTime.now();
        await backend.setDateTime('time', now);
        final stored = await backend.getInt('time');
        expect(stored, isNotNull);
      });

      test('getDateTime retrieves DateTime', () async {
        final now = DateTime.now();
        await backend.setDateTime('time', now);
        final result = await backend.getDateTime('time');
        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('getDateTime returns local time by default', () async {
        final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
        await backend.setDateTime('time', utcTime);
        final result = await backend.getDateTime('time');
        expect(result!.isUtc, false);
      });

      test('getDateTime returns UTC when isUtc=true', () async {
        final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
        await backend.setDateTime('time', utcTime);
        final result = await backend.getDateTime('time', isUtc: true);
        expect(result!.isUtc, true);
      });

      test('getDateTime returns null for non-existent key', () async {
        expect(await backend.getDateTime('missing'), null);
      });

      test('setDateTime converts local to UTC', () async {
        final localTime = DateTime(2024, 1, 1, 12, 0, 0);
        await backend.setDateTime('time', localTime);
        final stored = await backend.getInt('time');
        expect(stored, localTime.toUtc().millisecondsSinceEpoch);
      });
    });

    group('Duration operations', () {
      test('setDuration stores Duration as milliseconds', () async {
        final duration = Duration(hours: 2, minutes: 30);
        await backend.setDuration('duration', duration);
        final stored = await backend.getInt('duration');
        expect(stored, duration.inMilliseconds);
      });

      test('getDuration retrieves Duration', () async {
        final duration = Duration(hours: 2, minutes: 30);
        await backend.setDuration('duration', duration);
        final result = await backend.getDuration('duration');
        expect(result, duration);
      });

      test('getDuration returns null for non-existent key', () async {
        expect(await backend.getDuration('missing'), null);
      });
    });

    group('generic get method', () {
      test('get<String> retrieves string', () async {
        await backend.setString('key', 'value');
        expect(await backend.get<String>('key'), 'value');
      });

      test('get<int> retrieves int', () async {
        await backend.setInt('key', 42);
        expect(await backend.get<int>('key'), 42);
      });

      test('get<double> retrieves double', () async {
        await backend.setDouble('key', 3.14);
        expect(await backend.get<double>('key'), 3.14);
      });

      test('get<bool> retrieves bool', () async {
        await backend.setBool('key', true);
        expect(await backend.get<bool>('key'), true);
      });

      test('get<DateTime> retrieves DateTime', () async {
        final now = DateTime.now();
        await backend.setDateTime('key', now);
        final result = await backend.get<DateTime>('key');
        expect(result!.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('get<Duration> retrieves Duration', () async {
        final duration = Duration(hours: 1);
        await backend.setDuration('key', duration);
        expect(await backend.get<Duration>('key'), duration);
      });

      test('get<List<String>> retrieves string list', () async {
        await backend.setStringList('key', ['a', 'b']);
        expect(await backend.get<List<String>>('key'), ['a', 'b']);
      });

      test('get<Map<String, dynamic>> retrieves JSON', () async {
        await backend.setJson('key', {'test': true});
        expect(await backend.get<Map<String, dynamic>>('key'), {'test': true});
      });

      test('get<List<Map<String, dynamic>>> retrieves JSON list', () async {
        await backend.setJsonList('key', [
          {'id': 1},
        ]);
        expect(await backend.get<List<Map<String, dynamic>>>('key'), [
          {'id': 1},
        ]);
      });
    });

    group('generic set method', () {
      test('set with String value', () async {
        await backend.set('key', 'value');
        expect(await backend.getString('key'), 'value');
      });

      test('set with int value', () async {
        await backend.set('key', 42);
        expect(await backend.getInt('key'), 42);
      });

      test('set with double value', () async {
        await backend.set('key', 3.14);
        expect(await backend.getDouble('key'), 3.14);
      });

      test('set with bool value', () async {
        await backend.set('key', true);
        expect(await backend.getBool('key'), true);
      });

      test('set with DateTime value', () async {
        final now = DateTime.now();
        await backend.set('key', now);
        final result = await backend.getDateTime('key');
        expect(result!.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('set with Duration value', () async {
        final duration = Duration(minutes: 30);
        await backend.set('key', duration);
        expect(await backend.getDuration('key'), duration);
      });

      test('set with List<String> value', () async {
        await backend.set('key', ['a', 'b', 'c']);
        expect(await backend.getStringList('key'), ['a', 'b', 'c']);
      });

      test('set with Map<String, dynamic> value', () async {
        await backend.set('key', {'test': 42});
        expect(await backend.getJson('key'), {'test': 42});
      });

      test('set with List<Map<String, dynamic>> value', () async {
        await backend.set('key', [
          {'id': 1},
          {'id': 2},
        ]);
        expect(await backend.getJsonList('key'), [
          {'id': 1},
          {'id': 2},
        ]);
      });
    });

    group('unsupported types', () {
      test('get<E> throws UnsupportedError for custom class', () async {
        await backend.setString('key', 'some value');
        expect(
          () => backend.get<UnsupportedType>('key'),
          throwsUnsupportedError,
        );
      });

      test('get<E> throws UnsupportedError for List<int>', () async {
        await backend.setString('key', '[1,2,3]');
        expect(
          () => backend.get<List<int>>('key'),
          throwsUnsupportedError,
        );
      });

      test('get<E> throws UnsupportedError for Set<String>', () async {
        await backend.setString('key', 'value');
        expect(
          () => backend.get<Set<String>>('key'),
          throwsUnsupportedError,
        );
      });

      test('get<E> throws UnsupportedError for List<bool>', () async {
        await backend.setString('key', '[true, false]');
        expect(
          () => backend.get<List<bool>>('key'),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for custom class', () async {
        final obj = UnsupportedType('test', 42);
        expect(
          () => backend.set('key', obj),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for List<int>', () async {
        expect(
          () => backend.set('key', [1, 2, 3]),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for Set<String>', () async {
        expect(
          () => backend.set('key', {'a', 'b', 'c'}),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for List<bool>', () async {
        expect(
          () => backend.set('key', [true, false, true]),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for Map<int, String>', () async {
        expect(
          () => backend.set('key', {1: 'test'}),
          throwsUnsupportedError,
        );
      });

      test('set throws UnsupportedError for List<double>', () async {
        expect(
          () => backend.set('key', [1.1, 2.2, 3.3]),
          throwsUnsupportedError,
        );
      });
    });
  });
}

// Custom class for testing unsupported types
class UnsupportedType {
  final String name;
  final int value;

  UnsupportedType(this.name, this.value);
}

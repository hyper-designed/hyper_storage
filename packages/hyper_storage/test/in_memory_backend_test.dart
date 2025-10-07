import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

enum MemoryTestEnum { pending, completed, cancelled }

void main() {
  group('InMemoryBackend', () {
    late InMemoryBackend backend;

    setUp(() {
      backend = InMemoryBackend();
    });

    tearDown(() async {
      await backend.close();
    });

    group('initialization', () {
      test('creates empty backend', () async {
        final keys = await backend.getKeys();
        expect(keys, isEmpty);
      });

      test('creates backend with initial data', () async {
        final initialData = {'key1': 'value1', 'key2': 123};
        backend = InMemoryBackend.withData(initialData: initialData);

        final keys = await backend.getKeys();
        expect(keys, {'key1', 'key2'});
        expect(await backend.getString('key1'), 'value1');
        expect(await backend.getInt('key2'), 123);
      });

      test('init returns same instance', () async {
        final result = await backend.init();
        expect(result, same(backend));
      });
    });

    group('string operations', () {
      test('setString and getString', () async {
        await backend.setString('testKey', 'testValue');
        expect(await backend.getString('testKey'), 'testValue');
      });

      test('getString returns null for non-existent key', () async {
        expect(await backend.getString('nonExistent'), isNull);
      });

      test('setString overwrites existing value', () async {
        await backend.setString('key', 'value1');
        await backend.setString('key', 'value2');
        expect(await backend.getString('key'), 'value2');
      });
    });

    group('int operations', () {
      test('setInt and getInt', () async {
        await backend.setInt('count', 42);
        expect(await backend.getInt('count'), 42);
      });

      test('getInt returns null for non-existent key', () async {
        expect(await backend.getInt('nonExistent'), isNull);
      });

      test('setInt handles negative numbers', () async {
        await backend.setInt('negative', -100);
        expect(await backend.getInt('negative'), -100);
      });

      test('setInt handles zero', () async {
        await backend.setInt('zero', 0);
        expect(await backend.getInt('zero'), 0);
      });
    });

    group('double operations', () {
      test('setDouble and getDouble', () async {
        await backend.setDouble('price', 99.99);
        expect(await backend.getDouble('price'), 99.99);
      });

      test('getDouble returns null for non-existent key', () async {
        expect(await backend.getDouble('nonExistent'), isNull);
      });

      test('setDouble handles negative numbers', () async {
        await backend.setDouble('negative', -3.14);
        expect(await backend.getDouble('negative'), -3.14);
      });
    });

    group('bool operations', () {
      test('setBool and getBool for true', () async {
        await backend.setBool('isEnabled', true);
        expect(await backend.getBool('isEnabled'), true);
      });

      test('setBool and getBool for false', () async {
        await backend.setBool('isDisabled', false);
        expect(await backend.getBool('isDisabled'), false);
      });

      test('getBool returns null for non-existent key', () async {
        expect(await backend.getBool('nonExistent'), isNull);
      });
    });

    group('DateTime operations', () {
      test('setDateTime and getDateTime', () async {
        final now = DateTime.now();
        await backend.setDateTime('timestamp', now);
        final retrieved = await backend.getDateTime('timestamp');
        expect(retrieved, now);
      });

      test('getDateTime returns null for non-existent key', () async {
        expect(await backend.getDateTime('nonExistent'), isNull);
      });
    });

    group('Duration operations', () {
      test('setDuration and getDuration', () async {
        final duration = Duration(hours: 2, minutes: 30);
        await backend.setDuration('timeout', duration);
        expect(await backend.getDuration('timeout'), duration);
      });

      test('getDuration returns null for non-existent key', () async {
        expect(await backend.getDuration('nonExistent'), isNull);
      });
    });

    group('Enum operations', () {
      test('setEnum and getEnum', () async {
        await backend.setEnum('status', MemoryTestEnum.completed);
        final result = await backend.getEnum('status', MemoryTestEnum.values);
        expect(result, MemoryTestEnum.completed);
      });

      test('getEnum returns null for unknown value', () async {
        await backend.setString('status', 'unknown');
        final result = await backend.getEnum('status', MemoryTestEnum.values);
        expect(result, isNull);
      });

      test('generic get retrieves enum when values provided', () async {
        await backend.setEnum('status', MemoryTestEnum.pending);
        final result = await backend.get<MemoryTestEnum>('status', enumValues: MemoryTestEnum.values);
        expect(result, MemoryTestEnum.pending);
      });
    });

    group('StringList operations', () {
      test('setStringList and getStringList', () async {
        final list = ['a', 'b', 'c'];
        await backend.setStringList('items', list);
        expect(await backend.getStringList('items'), list);
      });

      test('getStringList returns null for non-existent key', () async {
        expect(await backend.getStringList('nonExistent'), isNull);
      });

      test('setStringList handles empty list', () async {
        await backend.setStringList('empty', []);
        expect(await backend.getStringList('empty'), []);
      });
    });

    group('JSON operations', () {
      test('setJson and getJson', () async {
        final json = {'name': 'John', 'age': 30};
        await backend.setJson('user', json);
        expect(await backend.getJson('user'), json);
      });

      test('getJson returns null for non-existent key', () async {
        expect(await backend.getJson('nonExistent'), isNull);
      });

      test('setJson handles nested objects', () async {
        final json = {
          'user': {'name': 'John', 'age': 30},
          'settings': {'theme': 'dark'},
        };
        await backend.setJson('data', json);
        expect(await backend.getJson('data'), json);
      });
    });

    group('JsonList operations', () {
      test('setJsonList and getJsonList', () async {
        final list = [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ];
        await backend.setJsonList('items', list);
        expect(await backend.getJsonList('items'), list);
      });

      test('getJsonList returns null for non-existent key', () async {
        expect(await backend.getJsonList('nonExistent'), isNull);
      });

      test('setJsonList handles empty list', () async {
        await backend.setJsonList('empty', []);
        expect(await backend.getJsonList('empty'), []);
      });
    });

    group('batch operations', () {
      test('setAll stores multiple values', () async {
        await backend.setAll({
          'key1': 'value1',
          'key2': 42,
          'key3': true,
        });

        expect(await backend.getString('key1'), 'value1');
        expect(await backend.getInt('key2'), 42);
        expect(await backend.getBool('key3'), true);
      });

      test('getAll returns all data when no allowList', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);

        final all = await backend.getAll({});
        expect(all, isEmpty);
      });

      test('getAll filters by allowList', () async {
        await backend.setString('key1', 'value1');
        await backend.setString('key2', 'value2');
        await backend.setString('key3', 'value3');

        final filtered = await backend.getAll({'key1', 'key3'});
        expect(filtered, {'key1': 'value1', 'key3': 'value3'});
      });

      test('getAll with empty allowList returns empty map', () async {
        await backend.setString('key1', 'value1');
        final filtered = await backend.getAll({});
        expect(filtered, isEmpty);
      });
    });

    group('key operations', () {
      test('getKeys returns all keys', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.setBool('key3', true);

        final keys = await backend.getKeys();
        expect(keys, {'key1', 'key2', 'key3'});
      });

      test('getKeys returns empty set for empty backend', () async {
        final keys = await backend.getKeys();
        expect(keys, isEmpty);
      });

      test('containsKey returns true for existing key', () async {
        await backend.setString('key', 'value');
        expect(await backend.containsKey('key'), true);
      });

      test('containsKey returns false for non-existent key', () async {
        expect(await backend.containsKey('nonExistent'), false);
      });
    });

    group('remove operations', () {
      test('remove deletes a key', () async {
        await backend.setString('key', 'value');
        await backend.remove('key');
        expect(await backend.getString('key'), isNull);
        expect(await backend.containsKey('key'), false);
      });

      test('remove is idempotent', () async {
        await backend.remove('nonExistent');
        expect(await backend.containsKey('nonExistent'), false);
      });

      test('removeAll deletes multiple keys', () async {
        await backend.setString('key1', 'value1');
        await backend.setString('key2', 'value2');
        await backend.setString('key3', 'value3');

        await backend.removeAll(['key1', 'key3']);

        expect(await backend.containsKey('key1'), false);
        expect(await backend.containsKey('key2'), true);
        expect(await backend.containsKey('key3'), false);
      });

      test('removeAll with empty list does nothing', () async {
        await backend.setString('key', 'value');
        await backend.removeAll([]);
        expect(await backend.getString('key'), 'value');
      });
    });

    group('clear and close', () {
      test('clear removes all data', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.clear();

        final keys = await backend.getKeys();
        expect(keys, isEmpty);
      });

      test('close clears all data', () async {
        await backend.setString('key1', 'value1');
        await backend.close();

        final keys = await backend.getKeys();
        expect(keys, isEmpty);
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty returns true for empty backend', () async {
        expect(await backend.isEmpty, true);
      });

      test('isEmpty returns false when data exists', () async {
        await backend.setString('key', 'value');
        expect(await backend.isEmpty, false);
      });

      test('isNotEmpty returns false for empty backend', () async {
        expect(await backend.isNotEmpty, false);
      });

      test('isNotEmpty returns true when data exists', () async {
        await backend.setString('key', 'value');
        expect(await backend.isNotEmpty, true);
      });
    });

    group('container creation', () {
      test('container creates a new HyperStorageContainer', () async {
        final container = await backend.container('testContainer');
        expect(container, isA<HyperStorageContainer>());
        expect(container.name, 'testContainer');
      });

      test('container creates isolated containers', () async {
        final container1 = await backend.container('container1');
        final container2 = await backend.container('container2');

        await container1.setString('key', 'value1');
        await container2.setString('key', 'value2');

        expect(await container1.getString('key'), 'value1');
        expect(await container2.getString('key'), 'value2');
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_storage_secure/hyper_storage_secure_backend.dart';

import 'mock_secure_storage.dart';

void main() {
  group('SecureStorageBackend', () {
    late SecureStorageBackend backend;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      mockStorage = MockFlutterSecureStorage();
      backend = SecureStorageBackend(storage: mockStorage);
      await backend.init();
    });

    group('initialization', () {
      test('creates backend with custom storage', () {
        expect(backend, isA<SecureStorageBackend>());
        expect(backend.storage, same(mockStorage));
      });

      test('creates backend with default storage when none provided', () {
        final defaultBackend = SecureStorageBackend();
        expect(defaultBackend, isA<SecureStorageBackend>());
        expect(defaultBackend.storage, isNotNull);
      });

      test('init completes successfully', () async {
        final newBackend = SecureStorageBackend(storage: MockFlutterSecureStorage());
        await expectLater(newBackend.init(), completes);
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

      test('setString handles empty string', () async {
        await backend.setString('empty', '');
        expect(await backend.getString('empty'), '');
      });

      test('setString handles special characters', () async {
        await backend.setString('special', 'hello\nworld\t!@#\$%');
        expect(await backend.getString('special'), 'hello\nworld\t!@#\$%');
      });

      test('setString handles unicode', () async {
        await backend.setString('unicode', '你好世界 🌍');
        expect(await backend.getString('unicode'), '你好世界 🌍');
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

      test('setInt handles large numbers', () async {
        await backend.setInt('large', 9223372036854775807);
        expect(await backend.getInt('large'), 9223372036854775807);
      });

      test('getInt returns null for non-numeric value', () async {
        await backend.setString('notNumber', 'abc');
        expect(await backend.getInt('notNumber'), isNull);
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

      test('setDouble handles zero', () async {
        await backend.setDouble('zero', 0.0);
        expect(await backend.getDouble('zero'), 0.0);
      });

      test('setDouble handles very small numbers', () async {
        await backend.setDouble('tiny', 0.000001);
        expect(await backend.getDouble('tiny'), closeTo(0.000001, 0.0000001));
      });

      test('getDouble returns null for non-numeric value', () async {
        await backend.setString('notNumber', 'abc');
        expect(await backend.getDouble('notNumber'), isNull);
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

      test('setBool overwrites existing value', () async {
        await backend.setBool('flag', true);
        await backend.setBool('flag', false);
        expect(await backend.getBool('flag'), false);
      });

      test('getBool returns null for non-boolean value', () async {
        await backend.setString('notBool', 'abc');
        expect(await backend.getBool('notBool'), isNull);
      });
    });

    group('key management', () {
      test('getKeys returns empty set for new backend', () async {
        expect(await backend.getKeys(), isEmpty);
      });

      test('getKeys returns all stored keys', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.setBool('key3', true);

        final keys = await backend.getKeys();
        expect(keys, containsAll(['key1', 'key2', 'key3']));
        expect(keys.length, 3);
      });

      test('containsKey returns true for existing key', () async {
        await backend.setString('exists', 'value');
        expect(await backend.containsKey('exists'), true);
      });

      test('containsKey returns false for non-existent key', () async {
        expect(await backend.containsKey('notExists'), false);
      });

      test('containsKey returns false after key is removed', () async {
        await backend.setString('temp', 'value');
        await backend.remove('temp');
        expect(await backend.containsKey('temp'), false);
      });
    });

    group('batch operations', () {
      test('getAll returns all data when no allowList provided', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.setBool('key3', true);

        final data = await backend.getAll(await backend.getKeys());
        expect(data, {
          'key1': 'value1',
          'key2': 42,
          'key3': true,
        });
      });

      test('getAll returns empty map for empty storage', () async {
        final data = await backend.getAll(await backend.getKeys());
        expect(data, isEmpty);
      });

      test('getAll filters by allowList when provided', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.setBool('key3', true);
        await backend.setDouble('key4', 3.14);

        final data = await backend.getAll({'key1', 'key3'});
        expect(data, {
          'key1': 'value1',
          'key3': true,
        });
        expect(data.containsKey('key2'), false);
        expect(data.containsKey('key4'), false);
      });

      test('getAll with empty allowList returns no data', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);

        final data = await backend.getAll({});
        expect(data, isEmpty);
      });

      test('getAll with non-existent keys in allowList', () async {
        await backend.setString('key1', 'value1');

        final data = await backend.getAll({'key1', 'nonExistent'});
        expect(data, {'key1': 'value1'});
      });
    });

    group('deletion operations', () {
      test('remove deletes specific key', () async {
        await backend.setString('toDelete', 'value');
        expect(await backend.containsKey('toDelete'), true);

        await backend.remove('toDelete');
        expect(await backend.containsKey('toDelete'), false);
        expect(await backend.getString('toDelete'), isNull);
      });

      test('remove does not affect other keys', () async {
        await backend.setString('key1', 'value1');
        await backend.setString('key2', 'value2');

        await backend.remove('key1');
        expect(await backend.getString('key1'), isNull);
        expect(await backend.getString('key2'), 'value2');
      });

      test('remove handles non-existent key gracefully', () async {
        await expectLater(backend.remove('nonExistent'), completes);
      });

      test('removeAll deletes multiple keys', () async {
        await backend.setString('key1', 'value1');
        await backend.setString('key2', 'value2');
        await backend.setString('key3', 'value3');

        await backend.removeAll({'key1', 'key3'});

        expect(await backend.containsKey('key1'), false);
        expect(await backend.containsKey('key2'), true);
        expect(await backend.containsKey('key3'), false);
      });

      test('removeAll handles empty list', () async {
        await backend.setString('key', 'value');
        await backend.removeAll({});
        expect(await backend.getString('key'), 'value');
      });

      test('removeAll handles non-existent keys', () async {
        await backend.setString('key1', 'value1');
        await expectLater(
          backend.removeAll({'key1', 'nonExistent'}),
          completes,
        );
        expect(await backend.containsKey('key1'), false);
      });

      test('clear removes all data', () async {
        await backend.setString('key1', 'value1');
        await backend.setInt('key2', 42);
        await backend.setBool('key3', true);

        await backend.clear();

        expect(await backend.getKeys(), isEmpty);
        expect(await backend.getString('key1'), isNull);
        expect(await backend.getInt('key2'), isNull);
        expect(await backend.getBool('key3'), isNull);
      });

      test('clear handles empty storage', () async {
        await expectLater(backend.clear(), completes);
        expect(await backend.getKeys(), isEmpty);
      });
    });

    group('lifecycle', () {
      test('close completes successfully', () async {
        await expectLater(backend.close(), completes);
      });

      test('close can be called multiple times', () async {
        await backend.close();
        await expectLater(backend.close(), completes);
      });
    });

    group('integration with GenericStorageOperationsMixin', () {
      test('DateTime operations work via mixin', () async {
        final now = DateTime.now();
        await backend.setDateTime('time', now);
        final result = await backend.getDateTime('time');
        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('Duration operations work via mixin', () async {
        final duration = Duration(hours: 2, minutes: 30);
        await backend.setDuration('duration', duration);
        expect(await backend.getDuration('duration'), duration);
      });

      test('JSON operations work via mixin', () async {
        final json = {
          'name': 'test',
          'value': 42,
          'nested': {'key': 'value'},
        };
        await backend.setJson('json', json);
        expect(await backend.getJson('json'), json);
      });

      test('StringList operations work via mixin', () async {
        final list = ['a', 'b', 'c'];
        await backend.setStringList('list', list);
        expect(await backend.getStringList('list'), list);
      });

      test('generic get<String> works', () async {
        await backend.setString('key', 'value');
        expect(await backend.get<String>('key'), 'value');
      });

      test('generic set with int works', () async {
        await backend.set('key', 42);
        expect(await backend.getInt('key'), 42);
      });
    });

    group('edge cases', () {
      test('handles rapid sequential writes to same key', () async {
        for (int i = 0; i < 100; i++) {
          await backend.setInt('counter', i);
        }
        expect(await backend.getInt('counter'), 99);
      });

      test('handles many different keys', () async {
        for (int i = 0; i < 50; i++) {
          await backend.setString('key$i', 'value$i');
        }

        final keys = await backend.getKeys();
        expect(keys.length, 50);
        expect(await backend.getString('key25'), 'value25');
      });

      test('handles overwriting different types on same key', () async {
        await backend.setString('multi', 'text');
        await backend.setInt('multi', 42);
        await backend.setDouble('multi', 3.14);

        // Last write wins
        expect(await backend.getDouble('multi'), 3.14);
      });

      test('handles long string values', () async {
        final longString = 'a' * 10000;
        await backend.setString('long', longString);
        expect(await backend.getString('long'), longString);
      });

      test('handles special key names', () async {
        await backend.setString('key-with-dashes', 'value1');
        await backend.setString('key_with_underscores', 'value2');
        await backend.setString('key.with.dots', 'value3');
        await backend.setString('key:with:colons', 'value4');

        expect(await backend.getString('key-with-dashes'), 'value1');
        expect(await backend.getString('key_with_underscores'), 'value2');
        expect(await backend.getString('key.with.dots'), 'value3');
        expect(await backend.getString('key:with:colons'), 'value4');
      });

      test('handles JSON arrays in getAll', () async {
        await backend.setString('array', '[1,2,3]');
        final data = await backend.getAll(await backend.getKeys());
        expect(data['array'], '[1,2,3]');
      });

      test('handles complex nested JSON', () async {
        final complex = {
          'users': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
          ],
          'meta': {'count': 2, 'page': 1},
        };
        await backend.setJson('complex', complex);
        expect(await backend.getJson('complex'), complex);
      });
    });
  });
}

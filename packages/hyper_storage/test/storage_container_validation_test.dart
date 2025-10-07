import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

enum ValidationEnum { first, second }

void main() {
  group('StorageContainer Validation', () {
    late InMemoryBackend backend;
    late HyperStorageContainer container;

    setUp(() async {
      backend = InMemoryBackend();
      await backend.init();
      container = HyperStorageContainer(backend: backend, name: 'testContainer');
    });

    tearDown(() async {
      await container.close();
      await backend.close();
    });

    group('delimiter validation', () {
      test('accepts valid delimiters', () {
        final validDelimiters = ['-', '_', '/', ',', '=', '+', '|', '*', '&', '^', '%', '\$', '#', '@', '!'];

        for (final delimiter in validDelimiters) {
          expect(
            () => HyperStorageContainer(backend: backend, name: 'test', delimiter: delimiter),
            returnsNormally,
            reason: 'Delimiter "$delimiter" should be valid',
          );
        }
      });

      test('accepts multi-character delimiters', () async {
        final container1 = HyperStorageContainer(backend: backend, name: 'test1', delimiter: '---');
        final container2 = HyperStorageContainer(backend: backend, name: 'test2', delimiter: '___');

        expect(container1.delimiter, '---');
        expect(container2.delimiter, '___');

        await container1.close();
        await container2.close();
      });

      test('throws on empty delimiter', () {
        expect(
          () => HyperStorageContainer(backend: backend, name: 'test', delimiter: ''),
          throwsArgumentError,
        );
      });

      test('throws on whitespace-only delimiter', () {
        expect(
          () => HyperStorageContainer(backend: backend, name: 'test', delimiter: '   '),
          throwsArgumentError,
        );
      });

      test('throws on invalid delimiter characters', () {
        final invalidDelimiters = ['.', ':', ';', '~', '`', '[', ']', '{', '}', '(', ')', '<', '>', '?', '"', "'"];

        for (final delimiter in invalidDelimiters) {
          expect(
            () => HyperStorageContainer(backend: backend, name: 'test', delimiter: delimiter),
            throwsArgumentError,
            reason: 'Delimiter "$delimiter" should be invalid',
          );
        }
      });

      test('uses default delimiter when not provided', () {
        final container = HyperStorageContainer(backend: backend, name: 'test');
        expect(container.delimiter, '___');
      });
    });

    group('container name validation', () {
      test('accepts valid names', () async {
        final c1 = HyperStorageContainer(backend: backend, name: 'users');
        final c2 = HyperStorageContainer(backend: backend, name: 'my-container');
        final c3 = HyperStorageContainer(backend: backend, name: 'container123');
        final c4 = HyperStorageContainer(backend: backend, name: 'a');

        expect(c1.name, 'users');
        expect(c2.name, 'my-container');
        expect(c3.name, 'container123');
        expect(c4.name, 'a');

        await c1.close();
        await c2.close();
        await c3.close();
        await c4.close();
      });

      test('throws on empty name', () {
        expect(
          () => HyperStorageContainer(backend: backend, name: ''),
          throwsArgumentError,
        );
      });

      test('throws on whitespace-only name', () {
        expect(
          () => HyperStorageContainer(backend: backend, name: '   '),
          throwsArgumentError,
        );
      });

      test('throws when name contains delimiter', () {
        expect(
          () => HyperStorageContainer(backend: backend, name: 'test___container'),
          throwsArgumentError,
        );

        expect(
          () => HyperStorageContainer(backend: backend, name: 'test-container', delimiter: '-'),
          throwsArgumentError,
        );
      });
    });

    group('key validation', () {
      test('accepts valid keys', () async {
        await container.setString('validKey', 'value');
        await container.setString('key-123', 'value');
        await container.setString('my_key', 'value');
        await container.setString('a', 'value');

        expect(await container.getString('validKey'), 'value');
      });

      test('throws on empty key', () async {
        expect(
          () => container.setString('', 'value'),
          throwsArgumentError,
        );

        expect(
          () => container.getString(''),
          throwsArgumentError,
        );

        expect(
          () => container.remove(''),
          throwsArgumentError,
        );
      });

      test('throws on whitespace-only key', () async {
        expect(
          () => container.setString('   ', 'value'),
          throwsArgumentError,
        );

        expect(
          () => container.getString('   '),
          throwsArgumentError,
        );
      });

      test('validates keys for enum operations', () async {
        expect(
          () => container.setEnum('', ValidationEnum.first),
          throwsArgumentError,
        );

        expect(
          () => container.getEnum('   ', ValidationEnum.values),
          throwsArgumentError,
        );
      });

      test('throws when key contains delimiter', () async {
        expect(
          () => container.setString('key___with___delimiter', 'value'),
          throwsArgumentError,
        );

        expect(
          () => container.getString('key___with___delimiter'),
          throwsArgumentError,
        );
      });

      test('validates keys in batch operations', () async {
        expect(
          () => container.setAll({'valid': 'value', '': 'invalid'}),
          throwsArgumentError,
        );

        expect(
          () => container.getAll(['valid', '']),
          throwsArgumentError,
        );

        expect(
          () => container.removeAll(['valid', '   ']),
          throwsArgumentError,
        );
      });
    });

    group('key encoding and storage', () {
      test('stores and retrieves keys correctly', () async {
        await container.setString('myKey', 'value');

        // Verify the key was stored and can be retrieved
        final keys = await container.getKeys();
        expect(keys, contains('myKey'));

        // Verify retrieval works
        final value = await container.getString('myKey');
        expect(value, 'value');
      });

      test('multiple keys are isolated', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');
        await container.setString('key3', 'value3');

        final keys = await container.getKeys();
        expect(keys, containsAll(['key1', 'key2', 'key3']));
      });

      test('keys work with special characters', () async {
        await container.setString('key-with-dash', 'value1');
        await container.setString('key_with_underscore', 'value2');
        await container.setString('key.with.dot', 'value3');

        expect(await container.getString('key-with-dash'), 'value1');
        expect(await container.getString('key_with_underscore'), 'value2');
        expect(await container.getString('key.with.dot'), 'value3');
      });
    });

    group('batch validation behavior', () {
      test('setAll validates all keys', () async {
        // Should work with valid keys
        await container.setAll({'key1': 'value1', 'key2': 'value2'});
        expect(await container.getString('key1'), 'value1');
        expect(await container.getString('key2'), 'value2');
      });

      test('setAll throws on any invalid key', () async {
        expect(
          () => container.setAll({'valid': 'value', '': 'invalid'}),
          throwsArgumentError,
        );

        expect(
          () => container.setAll({'valid': 'value', '   ': 'invalid'}),
          throwsArgumentError,
        );
      });

      test('getAll validates all keys', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');

        // Should work with valid keys
        final result = await container.getAll(['key1', 'key2']);
        expect(result['key1'], 'value1');
        expect(result['key2'], 'value2');

        // Should throw on invalid keys
        expect(
          () => container.getAll(['valid', '']),
          throwsArgumentError,
        );
      });

      test('removeAll validates all keys', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');

        // Should work with valid keys
        await container.removeAll(['key1', 'key2']);
        expect(await container.containsKey('key1'), false);
        expect(await container.containsKey('key2'), false);

        // Should throw on invalid keys
        expect(
          () => container.removeAll(['valid', '   ']),
          throwsArgumentError,
        );
      });
    });
  });
}

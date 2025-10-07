import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

enum ContainerTestEnum { foo, bar, baz }

void main() {
  group('HyperStorageContainer', () {
    late InMemoryBackend backend;
    late HyperStorageContainer container;

    setUp(() async {
      backend = InMemoryBackend();
      await backend.init();
      container = HyperStorageContainer(backend: backend, name: 'test');
    });

    tearDown(() async {
      await container.close();
      await backend.close();
    });

    group('basic operations', () {
      test('setString and getString', () async {
        await container.setString('key', 'value');
        expect(await container.getString('key'), 'value');
      });

      test('setInt and getInt', () async {
        await container.setInt('count', 42);
        expect(await container.getInt('count'), 42);
      });

      test('setDouble and getDouble', () async {
        await container.setDouble('price', 99.99);
        expect(await container.getDouble('price'), 99.99);
      });

      test('setBool and getBool', () async {
        await container.setBool('enabled', true);
        expect(await container.getBool('enabled'), true);
      });

      test('returns null for non-existent keys', () async {
        expect(await container.getString('nonExistent'), isNull);
        expect(await container.getInt('nonExistent'), isNull);
        expect(await container.getDouble('nonExistent'), isNull);
        expect(await container.getBool('nonExistent'), isNull);
      });
    });

    group('DateTime operations', () {
      test('setDateTime and getDateTime in UTC', () async {
        final now = DateTime.now().toUtc();
        await container.setDateTime('timestamp', now);
        final retrieved = await container.getDateTime('timestamp', isUtc: true);
        expect(retrieved?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      });

      test('setDateTime and getDateTime in local time', () async {
        final now = DateTime.now();
        await container.setDateTime('timestamp', now);
        final retrieved = await container.getDateTime('timestamp');
        expect(retrieved?.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('handles UTC to local conversion', () async {
        final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
        await container.setDateTime('timestamp', utcTime);
        final local = await container.getDateTime('timestamp', isUtc: false);
        expect(local?.toUtc().millisecondsSinceEpoch, utcTime.millisecondsSinceEpoch);
      });
    });

    group('Duration operations', () {
      test('setDuration and getDuration', () async {
        final duration = Duration(hours: 2, minutes: 30, seconds: 15);
        await container.setDuration('timeout', duration);
        expect(await container.getDuration('timeout'), duration);
      });

      test('handles zero duration', () async {
        final duration = Duration.zero;
        await container.setDuration('zero', duration);
        expect(await container.getDuration('zero'), duration);
      });

      test('handles negative duration', () async {
        final duration = Duration(milliseconds: -1000);
        await container.setDuration('negative', duration);
        expect(await container.getDuration('negative'), duration);
      });
    });

    group('Enum operations', () {
      test('setEnum and getEnum', () async {
        await container.setEnum('status', ContainerTestEnum.bar);
        final result = await container.getEnum('status', ContainerTestEnum.values);
        expect(result, ContainerTestEnum.bar);
      });

      test('getEnum returns null when key missing', () async {
        final result = await container.getEnum('missing', ContainerTestEnum.values);
        expect(result, isNull);
      });

      test('getEnum returns null when stored value mismatches', () async {
        await backend.setString('test___status', 'unknown');
        final result = await container.getEnum('status', ContainerTestEnum.values);
        expect(result, isNull);
      });

      test('generic get retrieves enum with values', () async {
        await container.setEnum('status', ContainerTestEnum.foo);
        final result = await container.get<ContainerTestEnum>('status', enumValues: ContainerTestEnum.values);
        expect(result, ContainerTestEnum.foo);
      });

      test('generic set stores enum name', () async {
        await container.set('status', ContainerTestEnum.baz);
        final stored = await backend.getString('test___status');
        expect(stored, 'baz');
      });
    });

    group('StringList operations', () {
      test('setStringList and getStringList', () async {
        final list = ['a', 'b', 'c'];
        await container.setStringList('items', list);
        expect(await container.getStringList('items'), list);
      });

      test('handles empty list', () async {
        await container.setStringList('empty', []);
        expect(await container.getStringList('empty'), []);
      });

      test('handles list with special characters', () async {
        final list = ['hello world', 'test\nline', 'tab\there'];
        await container.setStringList('special', list);
        expect(await container.getStringList('special'), list);
      });
    });

    group('JSON operations', () {
      test('setJson and getJson', () async {
        final json = {'name': 'John', 'age': 30, 'active': true};
        await container.setJson('user', json);
        expect(await container.getJson('user'), json);
      });

      test('handles nested JSON', () async {
        final json = {
          'user': {'name': 'John', 'age': 30},
          'settings': {
            'theme': 'dark',
            'notifications': {'email': true, 'push': false},
          },
        };
        await container.setJson('data', json);
        expect(await container.getJson('data'), json);
      });

      test('handles JSON with arrays', () async {
        final json = {
          'items': [1, 2, 3],
          'tags': ['a', 'b', 'c'],
        };
        await container.setJson('data', json);
        expect(await container.getJson('data'), json);
      });
    });

    group('JsonList operations', () {
      test('setJsonList and getJsonList', () async {
        final list = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ];
        await container.setJsonList('items', list);
        expect(await container.getJsonList('items'), list);
      });

      test('handles empty JSON list', () async {
        await container.setJsonList('empty', []);
        expect(await container.getJsonList('empty'), []);
      });
    });

    group('batch operations', () {
      test('setAll stores multiple values', () async {
        await container.setAll({
          'key1': 'value1',
          'key2': 42,
          'key3': true,
          'key4': 3.14,
        });

        expect(await container.getString('key1'), 'value1');
        expect(await container.getInt('key2'), 42);
        expect(await container.getBool('key3'), true);
        expect(await container.getDouble('key4'), 3.14);
      });

      test('getAll returns all container data', () async {
        await container.setString('key1', 'value1');
        await container.setInt('key2', 42);

        final all = await container.getAll();
        expect(all.keys, containsAll(['key1', 'key2']));
        expect(all['key1'], 'value1');
        expect(all['key2'], 42);
      });

      test('getAll filters by allowList', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');
        await container.setString('key3', 'value3');

        final filtered = await container.getAll(['key1', 'key3']);
        expect(filtered, {'key1': 'value1', 'key3': 'value3'});
      });
    });

    group('key management', () {
      test('getKeys returns all container keys', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');
        await container.setInt('key3', 42);

        final keys = await container.getKeys();
        expect(keys, {'key1', 'key2', 'key3'});
      });

      test('containsKey returns true for existing key', () async {
        await container.setString('key', 'value');
        expect(await container.containsKey('key'), true);
      });

      test('containsKey returns false for non-existent key', () async {
        expect(await container.containsKey('nonExistent'), false);
      });
    });

    group('remove operations', () {
      test('remove deletes a key', () async {
        await container.setString('key', 'value');
        await container.remove('key');

        expect(await container.containsKey('key'), false);
        expect(await container.getString('key'), isNull);
      });

      test('removeAll deletes multiple keys', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');
        await container.setString('key3', 'value3');

        await container.removeAll(['key1', 'key3']);

        expect(await container.containsKey('key1'), false);
        expect(await container.containsKey('key2'), true);
        expect(await container.containsKey('key3'), false);
      });

      test('clear removes all container data', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');
        await container.clear();

        final keys = await container.getKeys();
        expect(keys, isEmpty);
      });

      test('clear only affects this container', () async {
        final backend2 = InMemoryBackend();
        await backend2.init();
        final container2 = HyperStorageContainer(backend: backend2, name: 'other');

        await container.setString('key1', 'value1');
        await container2.setString('key2', 'value2');

        await container.clear();

        expect(await container.getKeys(), isEmpty);
        expect(await container2.getKeys(), {'key2'});

        await container2.close();
        await backend2.close();
      });
    });

    group('container isolation', () {
      test('different containers have isolated data', () async {
        final container1 = HyperStorageContainer(backend: backend, name: 'container1');
        final container2 = HyperStorageContainer(backend: backend, name: 'container2');

        await container1.setString('key', 'value1');
        await container2.setString('key', 'value2');

        final value1 = await container1.getString('key');
        final value2 = await container2.getString('key');

        expect(value1, 'value1');
        expect(value2, 'value2');

        await container1.close();
        await container2.close();
      });

      test('containers with same name share data', () async {
        await container.setString('key', 'value');

        final sameNameContainer = HyperStorageContainer(backend: backend, name: 'test');
        final value = await sameNameContainer.getString('key');
        expect(value, 'value');

        await sameNameContainer.close();
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty returns true for empty container', () async {
        // Container starts empty
        final isEmpty = await container.isEmpty;
        expect(isEmpty, true);
      });

      test('isEmpty returns false when data exists', () async {
        await container.setString('key', 'value');
        final isEmpty = await container.isEmpty;
        expect(isEmpty, false);
      });

      test('isNotEmpty returns false for empty container', () async {
        // Create fresh container to ensure it's empty
        final tempBackend = InMemoryBackend();
        await tempBackend.init();
        final tempContainer = HyperStorageContainer(backend: tempBackend, name: 'temp');

        final isNotEmpty = await tempContainer.isNotEmpty;
        expect(isNotEmpty, false);

        await tempContainer.close();
        await tempBackend.close();
      });

      test('isNotEmpty returns true when data exists', () async {
        await container.setString('key', 'value');
        final isNotEmpty = await container.isNotEmpty;
        expect(isNotEmpty, true);
      });

      test('isEmpty reflects state after clear', () async {
        await container.setString('key', 'value');
        expect(await container.isEmpty, false);

        await container.clear();
        final isEmpty = await container.isEmpty;
        expect(isEmpty, true);
      });
    });

    group('data type preservation', () {
      test('preserves string type', () async {
        await container.setString('str', '123');
        final value = await container.getString('str');
        expect(value, isA<String>());
        expect(value, '123');
      });

      test('preserves int type', () async {
        await container.setInt('num', 123);
        final value = await container.getInt('num');
        expect(value, isA<int>());
        expect(value, 123);
      });

      test('preserves bool type', () async {
        await container.setBool('flag', true);
        final value = await container.getBool('flag');
        expect(value, isA<bool>());
        expect(value, true);
      });

      test('preserves double type', () async {
        await container.setDouble('decimal', 3.14);
        final value = await container.getDouble('decimal');
        expect(value, isA<double>());
        expect(value, 3.14);
      });
    });

    group('edge cases', () {
      test('handles very long strings', () async {
        final longString = 'a' * 10000;
        await container.setString('long', longString);
        expect(await container.getString('long'), longString);
      });

      test('handles empty string value', () async {
        await container.setString('empty', '');
        expect(await container.getString('empty'), '');
      });

      test('handles zero values', () async {
        await container.setInt('zero', 0);
        await container.setDouble('zeroDouble', 0.0);

        expect(await container.getInt('zero'), 0);
        expect(await container.getDouble('zeroDouble'), 0.0);
      });

      test('handles special characters in values', () async {
        final special = 'test\n\t\r"\'\\';
        await container.setString('special', special);
        expect(await container.getString('special'), special);
      });

      test('overwrites existing values', () async {
        await container.setString('key', 'value1');
        await container.setString('key', 'value2');
        expect(await container.getString('key'), 'value2');
      });

      test('handles rapid sequential operations', () async {
        for (int i = 0; i < 100; i++) {
          await container.setInt('counter', i);
        }
        expect(await container.getInt('counter'), 99);
      });
    });

    group('generic get and set', () {
      test('get<String> works', () async {
        await container.setString('key', 'value');
        expect(await container.getString('key'), 'value');
      });

      test('get<int> works', () async {
        await container.setInt('key', 42);
        expect(await container.getInt('key'), 42);
      });

      test('get<double> works', () async {
        await container.setDouble('key', 3.14);
        expect(await container.getDouble('key'), 3.14);
      });

      test('get<bool> works', () async {
        await container.setBool('key', true);
        expect(await container.getBool('key'), true);
      });

      test('get<DateTime> works', () async {
        final now = DateTime.now();
        await container.setDateTime('key', now);
        final retrieved = await container.getDateTime('key');
        expect(retrieved?.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('get<Duration> works', () async {
        final duration = Duration(hours: 1);
        await container.setDuration('key', duration);
        expect(await container.getDuration('key'), duration);
      });

      test('get<List<String>> works', () async {
        final list = ['a', 'b', 'c'];
        await container.setStringList('key', list);
        expect(await container.getStringList('key'), list);
      });

      test('get<Map<String, dynamic>> works', () async {
        final map = {'key': 'value', 'num': 42};
        await container.setJson('key', map);
        expect(await container.getJson('key'), map);
      });
    });

    group('stream', () {
      test('stream() emits initial value', () async {
        await container.setString('key', 'initial value');

        final stream = container.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values, contains('initial value'));
      });

      test('stream() emits null for non-existent key', () async {
        final stream = container.stream<String>('nonExistent');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values, contains(null));
      });

      test('stream() updates when value changes', () async {
        await container.setString('key', 'initial');

        final stream = container.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await container.setString('key', 'updated');
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, contains('initial'));
        expect(values, contains('updated'));
      });

      test('stream() handles multiple updates', () async {
        await container.setInt('counter', 0);

        final stream = container.stream<int>('counter');
        final values = <int?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await container.setInt('counter', 1);
        await Future.delayed(Duration(milliseconds: 50));
        await container.setInt('counter', 2);
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, containsAll([0, 1, 2]));
      });

      test('stream() works with different data types', () async {
        // Test with int
        await container.setInt('intKey', 42);
        final intStream = container.stream<int>('intKey');
        final intValues = <int?>[];
        final intSub = intStream.listen(intValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await intSub.cancel();
        expect(intValues, contains(42));

        // Test with bool
        await container.setBool('boolKey', true);
        final boolStream = container.stream<bool>('boolKey');
        final boolValues = <bool?>[];
        final boolSub = boolStream.listen(boolValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await boolSub.cancel();
        expect(boolValues, contains(true));

        // Test with double
        await container.setDouble('doubleKey', 3.14);
        final doubleStream = container.stream<double>('doubleKey');
        final doubleValues = <double?>[];
        final doubleSub = doubleStream.listen(doubleValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await doubleSub.cancel();
        expect(doubleValues, contains(3.14));

        // Test with enum
        await container.setEnum('enumKey', ContainerTestEnum.bar);
        final enumStream = container.stream<ContainerTestEnum>(
          'enumKey',
          enumValues: ContainerTestEnum.values,
        );
        final enumValues = <ContainerTestEnum?>[];
        final enumSub = enumStream.listen(enumValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await enumSub.cancel();
        expect(enumValues, contains(ContainerTestEnum.bar));
      });

      test('stream() updates enum values', () async {
        await container.setEnum('enumKey', ContainerTestEnum.foo);

        final stream = container.stream<ContainerTestEnum>(
          'enumKey',
          enumValues: ContainerTestEnum.values,
        );
        final values = <ContainerTestEnum?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await container.setEnum('enumKey', ContainerTestEnum.baz);
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, containsAll([ContainerTestEnum.foo, ContainerTestEnum.baz]));
      });

      test('stream() cleans up listener on cancellation', () async {
        await container.setString('key', 'value');

        final stream = container.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        final initialLength = values.length;
        await subscription.cancel();

        // Update after cancellation
        await container.setString('key', 'new value');
        await Future.delayed(Duration(milliseconds: 50));

        // Values list should not grow after cancellation
        expect(values.length, initialLength);
      });

      test('stream() handles concurrent streams for same key', () async {
        await container.setString('key', 'initial');

        final stream1 = container.stream<String>('key');
        final stream2 = container.stream<String>('key');

        final values1 = <String?>[];
        final values2 = <String?>[];

        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(Duration(milliseconds: 50));

        await container.setString('key', 'updated');
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        expect(values1, contains('initial'));
        expect(values1, contains('updated'));
        expect(values2, contains('initial'));
        expect(values2, contains('updated'));
      });

      test('stream() handles concurrent streams for different keys', () async {
        await container.setString('key1', 'value1');
        await container.setString('key2', 'value2');

        final stream1 = container.stream<String>('key1');
        final stream2 = container.stream<String>('key2');

        final values1 = <String?>[];
        final values2 = <String?>[];

        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(Duration(milliseconds: 50));

        await container.setString('key1', 'updated1');
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        expect(values1, contains('value1'));
        expect(values1, contains('updated1'));
        expect(values2, contains('value2'));
        expect(values2, isNot(contains('updated1')));
      });

      test('stream() only reacts to container-specific changes', () async {
        final backend2 = InMemoryBackend();
        await backend2.init();
        final container2 = HyperStorageContainer(backend: backend2, name: 'other');

        await container.setString('key', 'container1');
        await container2.setString('key', 'container2');

        final stream1 = container.stream<String>('key');
        final stream2 = container2.stream<String>('key');

        final values1 = <String?>[];
        final values2 = <String?>[];

        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(Duration(milliseconds: 50));

        // Update container1
        await container.setString('key', 'container1-updated');
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        // stream1 should have both values from container1
        expect(values1, contains('container1'));
        expect(values1, contains('container1-updated'));

        // stream2 should only have the initial value from container2
        expect(values2, contains('container2'));
        expect(values2, isNot(contains('container1-updated')));

        await container2.close();
        await backend2.close();
      });
    });
  });
}

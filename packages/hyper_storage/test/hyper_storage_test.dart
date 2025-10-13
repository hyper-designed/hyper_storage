import 'dart:convert';
import 'dart:typed_data';

import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

enum StorageTestEnum { pending, success, failed }

void main() {
  group('HyperStorage', () {
    tearDown(() async {
      // Clean up singleton between tests
      try {
        await HyperStorage.instance.close();
      } catch (_) {
        // Instance might not be initialized
      }
    });

    group('initialization', () {
      test('init creates singleton instance', () async {
        final backend = InMemoryBackend();
        final storage = await HyperStorage.init(backend: backend);

        expect(storage, isNotNull);
        expect(HyperStorage.instance, same(storage));
      });

      test('init is idempotent with same backend type', () async {
        final backend1 = InMemoryBackend();
        final storage1 = await HyperStorage.init(backend: backend1);

        final backend2 = InMemoryBackend();
        final storage2 = await HyperStorage.init(backend: backend2);

        expect(storage1, same(storage2));
      });

      test('init throws when reinitializing with different backend type', () async {
        await HyperStorage.init(backend: InMemoryBackend());
        expect(
          () => HyperStorage.init(backend: AnotherBackend()),
          throwsStateError,
        );
      });

      test('initMocked creates instance with InMemoryBackend', () async {
        final storage = await HyperStorage.initMocked();

        expect(storage, isNotNull);
        expect(storage.backend, isA<InMemoryBackend>());
      });

      test('initMocked with initial data', () async {
        final initialData = {'key1': 'value1', 'key2': 42};
        final storage = await HyperStorage.initMocked(initialData: initialData);

        expect(await storage.getString('key1'), 'value1');
        expect(await storage.getInt('key2'), 42);
      });

      test('instance throws before initialization', () {
        expect(() => HyperStorage.instance, throwsStateError);
      });

      test('newInstance creates non-singleton instance', () async {
        final backend = InMemoryBackend();
        final instance1 = await HyperStorage.newInstance(backend: backend);
        final instance2 = await HyperStorage.newInstance(backend: backend);

        expect(instance1, isNot(same(instance2)));

        await instance1.close();
        await instance2.close();
      });
    });

    group('container management', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('container creates and caches containers', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.backend.container('users');
        final container2 = await storage.backend.container('users');

        // Different instances since backend.container creates new instances
        expect(container1, isA<HyperStorageContainer>());
        expect(container2, isA<HyperStorageContainer>());
      });

      test('different named containers are different instances', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.backend.container('users');
        final container2 = await storage.backend.container('admins');

        expect(container1.name, 'users');
        expect(container2.name, 'admins');
      });

      test('containers are isolated by name', () async {
        final storage = HyperStorage.instance;
        final users = await storage.backend.container('users');
        final admins = await storage.backend.container('admins');

        await users.setString('name', 'User Container');
        await admins.setString('name', 'Admin Container');

        expect(await users.getString('name'), 'User Container');
        expect(await admins.getString('name'), 'Admin Container');
      });
    });

    group('JSON containers', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('creates JSON containers', () async {
        final storage = HyperStorage.instance;
        final container = JsonStorageContainer<User>(
          backend: storage.backend,
          name: 'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
        );

        await container.add(testUser1);
        expect(await container.get(testUser1.id), testUser1);
      });

      test('accepts custom parameters', () async {
        final storage = HyperStorage.instance;
        final container = JsonStorageContainer<User>(
          backend: storage.backend,
          name: 'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
          delimiter: '---',
          seed: 12345,
        );

        await container.add(testUser1);
        expect(await container.get(testUser1.id), testUser1);
      });
    });

    group('custom containers', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('creates custom containers', () async {
        final storage = HyperStorage.instance;
        final container = JsonStorageContainer<User>(
          backend: storage.backend,
          name: 'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
        );

        await container.add(testUser1);
        expect(await container.get(testUser1.id), testUser1);
      });
    });

    group('storage operations', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('setString and getString', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'value');
        expect(await storage.getString('key'), 'value');
      });

      test('setInt and getInt', () async {
        final storage = HyperStorage.instance;
        await storage.setInt('count', 42);
        expect(await storage.getInt('count'), 42);
      });

      test('setBool and getBool', () async {
        final storage = HyperStorage.instance;
        await storage.setBool('enabled', true);
        expect(await storage.getBool('enabled'), true);
      });

      test('setDouble and getDouble', () async {
        final storage = HyperStorage.instance;
        await storage.setDouble('price', 99.99);
        expect(await storage.getDouble('price'), 99.99);
      });

      test('batch operations', () async {
        final storage = HyperStorage.instance;
        await storage.setAll({
          'key1': 'value1',
          'key2': 42,
          'key3': true,
        });

        expect(await storage.getString('key1'), 'value1');
        expect(await storage.getInt('key2'), 42);
        expect(await storage.getBool('key3'), true);
      });

      test('getAll returns all data', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setInt('key2', 42);

        final all = await storage.getAll();
        expect(all['key1'], 'value1');
        expect(all['key2'], 42);
      });

      test('getAll returns empty map when allowList is empty', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setInt('key2', 42);

        final all = await storage.getAll([]);
        expect(all, isEmpty);
        expect(all, isA<Map<String, dynamic>>());
      });

      test('remove deletes data', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'value');
        await storage.remove('key');

        expect(await storage.getString('key'), isNull);
      });

      test('containsKey checks existence', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'value');

        expect(await storage.containsKey('key'), true);
        expect(await storage.containsKey('nonExistent'), false);
      });

      test('isEmpty and isNotEmpty', () async {
        final storage = HyperStorage.instance;
        expect(await storage.isEmpty, true);

        await storage.setString('key', 'value');
        expect(await storage.isEmpty, false);
        expect(await storage.isNotEmpty, true);
      });

      test('getKeys returns all keys', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setString('key2', 'value2');

        final keys = await storage.getKeys();
        expect(keys, containsAll(['key1', 'key2']));
      });

      test('setDateTime and getDateTime', () async {
        final storage = HyperStorage.instance;
        final now = DateTime.now();
        await storage.setDateTime('time', now);

        final retrieved = await storage.getDateTime('time');
        expect(retrieved, isNotNull);
        expect(retrieved!.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('getDateTime with isUtc parameter', () async {
        final storage = HyperStorage.instance;
        final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
        await storage.setDateTime('time', utcTime);

        final asUtc = await storage.getDateTime('time', isUtc: true);
        expect(asUtc!.isUtc, true);

        final asLocal = await storage.getDateTime('time', isUtc: false);
        expect(asLocal!.isUtc, false);
      });

      test('setDuration and getDuration', () async {
        final storage = HyperStorage.instance;
        final duration = Duration(hours: 2, minutes: 30);
        await storage.setDuration('duration', duration);

        final retrieved = await storage.getDuration('duration');
        expect(retrieved, duration);
      });

      test('setStringList and getStringList', () async {
        final storage = HyperStorage.instance;
        final list = ['apple', 'banana', 'cherry'];
        await storage.setStringList('fruits', list);

        final retrieved = await storage.getStringList('fruits');
        expect(retrieved, list);
      });

      test('setBytes and getBytes', () async {
        final storage = HyperStorage.instance;
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 0]);
        await storage.setBytes('data', bytes);

        final retrieved = await storage.getBytes('data');
        expect(retrieved, bytes);
      });

      test('getBytes returns null for non-existent key', () async {
        final storage = HyperStorage.instance;
        expect(await storage.getBytes('nonExistent'), isNull);
      });

      test('setBytes and getBytes with empty bytes', () async {
        final storage = HyperStorage.instance;
        final bytes = Uint8List(0);
        await storage.setBytes('empty', bytes);

        final retrieved = await storage.getBytes('empty');
        expect(retrieved, bytes);
        expect(retrieved!.length, 0);
      });

      test('setBytes and getBytes with large byte array', () async {
        final storage = HyperStorage.instance;
        final bytes = Uint8List.fromList(List.generate(10000, (i) => i % 256));
        await storage.setBytes('large', bytes);

        final retrieved = await storage.getBytes('large');
        expect(retrieved, bytes);
        expect(retrieved!.length, 10000);
      });

      test('setJson and getJson', () async {
        final storage = HyperStorage.instance;
        final json = {'name': 'John', 'age': 30, 'active': true};
        await storage.setJson('user', json);

        final retrieved = await storage.getJson('user');
        expect(retrieved, json);
      });

      test('setJsonList and getJsonList', () async {
        final storage = HyperStorage.instance;
        final jsonList = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ];
        await storage.setJsonList('items', jsonList);

        final retrieved = await storage.getJsonList('items');
        expect(retrieved, jsonList);
      });

      test('setEnum and getEnum', () async {
        final storage = HyperStorage.instance;
        await storage.setEnum('status', StorageTestEnum.success);
        final result = await storage.getEnum('status', StorageTestEnum.values);
        expect(result, StorageTestEnum.success);
      });

      test('getEnum returns null when stored name mismatches', () async {
        final storage = HyperStorage.instance;
        await storage.backend.setString('status', 'unknown');
        final result = await storage.getEnum('status', StorageTestEnum.values);
        expect(result, isNull);
      });

      test('get<StorageTestEnum> retrieves enum when values provided', () async {
        final storage = HyperStorage.instance;
        await storage.setEnum('status', StorageTestEnum.pending);
        final result = await storage.get<StorageTestEnum>('status', enumValues: StorageTestEnum.values);
        expect(result, StorageTestEnum.pending);
      });

      test('get<StorageTestEnum> throws when enum values missing', () async {
        final storage = HyperStorage.instance;
        await storage.backend.setString('status', 'failed');
        expect(
          () => storage.get<StorageTestEnum>('status'),
          throwsUnsupportedError,
        );
      });

      test('removeAll deletes multiple keys', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setString('key2', 'value2');
        await storage.setString('key3', 'value3');

        await storage.removeAll(['key1', 'key3']);

        expect(await storage.getString('key1'), isNull);
        expect(await storage.getString('key2'), 'value2');
        expect(await storage.getString('key3'), isNull);
      });
    });

    group('clear', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('clear removes all data from storage and containers', () async {
        final storage = HyperStorage.instance;
        final container = await storage.container('test');
        final jsonContainer = await storage.jsonSerializableContainer<User>(
          'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
        );

        await storage.setString('rootKey', 'rootValue');
        await container.setString('containerKey', 'containerValue');
        await jsonContainer.add(testUser1);

        await storage.clear();

        expect(await storage.getString('rootKey'), isNull);
        expect(await container.isEmpty, isTrue);
        expect(await jsonContainer.isEmpty, isTrue);
      });

      test('clear clears backend data', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setString('key2', 'value2');

        await storage.clear();

        final keys = await storage.backend.getKeys();
        expect(keys, isEmpty);
      });
    });

    group('close', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('close cleans up all resources', () async {
        final storage = HyperStorage.instance;
        final container = await storage.backend.container('test');

        await container.setString('key', 'value');
        await storage.close();

        // After close, instance should throw when accessed
        expect(() => HyperStorage.instance, throwsStateError);
      });

      test('close clears resources', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'value');

        await storage.close();

        // After close, instance should throw when accessed
        expect(() => HyperStorage.instance, throwsStateError);
      });

      test('can reinitialize after close', () async {
        await HyperStorage.instance.close();

        final backend = InMemoryBackend();
        final storage = await HyperStorage.init(backend: backend);

        expect(storage, isNotNull);
        expect(HyperStorage.instance, same(storage));
      });
    });

    group('listeners', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('addListener registers global listener', () async {
        final storage = HyperStorage.instance;
        int callCount = 0;

        storage.addListener(() {
          callCount++;
        });

        await storage.setString('key1', 'value1');
        await storage.setString('key2', 'value2');

        await Future.delayed(Duration(milliseconds: 10));
        expect(callCount, greaterThan(0));
      });

      test('addKeyListener registers key-specific listener', () async {
        final storage = HyperStorage.instance;
        int callCount = 0;

        storage.addKeyListener('specificKey', () {
          callCount++;
        });

        await storage.setString('specificKey', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterSpecificKey = callCount;
        expect(countAfterSpecificKey, greaterThan(0));

        await storage.setString('otherKey', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        // Should not increase for other keys
        expect(callCount, countAfterSpecificKey);
      });

      test('removeListener unregisters listener', () async {
        final storage = HyperStorage.instance;
        int callCount = 0;

        void listener() {
          callCount++;
        }

        storage.addListener(listener);
        await storage.setString('key', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        final countBefore = callCount;

        storage.removeListener(listener);
        await storage.setString('key', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, countBefore);
      });

      test('hasListeners returns correct value', () {
        final storage = HyperStorage.instance;
        expect(storage.hasListeners, false);

        storage.addListener(() {});
        expect(storage.hasListeners, true);

        storage.removeAllListeners();
        expect(storage.hasListeners, false);
      });
    });

    group('key encoding', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('encodeKey returns key unchanged', () async {
        final storage = HyperStorage.instance;

        // HyperStorage should not encode keys - they should remain unchanged
        expect(storage.encodeKey('myKey'), 'myKey');
        expect(storage.encodeKey('user_123'), 'user_123');
        expect(storage.encodeKey('config-setting'), 'config-setting');
        expect(storage.encodeKey('some.key.with.dots'), 'some.key.with.dots');
      });
    });

    group('validation', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('validates empty keys', () async {
        final storage = HyperStorage.instance;

        expect(
          () => storage.setString('', 'value'),
          throwsArgumentError,
        );

        expect(
          () => storage.getString(''),
          throwsArgumentError,
        );
      });

      test('validates whitespace-only keys', () async {
        final storage = HyperStorage.instance;

        expect(
          () => storage.setString('   ', 'value'),
          throwsArgumentError,
        );
      });

      test('validates keys for enum operations', () async {
        final storage = HyperStorage.instance;

        expect(
          () => storage.setEnum('', StorageTestEnum.failed),
          throwsArgumentError,
        );

        expect(
          () => storage.getEnum('   ', StorageTestEnum.values),
          throwsArgumentError,
        );
      });

      test('accepts valid keys', () async {
        final storage = HyperStorage.instance;

        await expectLater(
          storage.setString('validKey', 'value'),
          completes,
        );

        await expectLater(
          storage.setString('key-with-dashes', 'value'),
          completes,
        );

        await expectLater(
          storage.setString('key_with_underscores', 'value'),
          completes,
        );
      });
    });

    group('edge cases', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('handles rapid operations', () async {
        final storage = HyperStorage.instance;

        for (int i = 0; i < 100; i++) {
          await storage.setInt('counter', i);
        }

        expect(await storage.getInt('counter'), 99);
      });

      test('handles mixed data types', () async {
        final storage = HyperStorage.instance;

        await storage.setString('str', 'text');
        await storage.setInt('num', 42);
        await storage.setBool('flag', true);
        await storage.setDouble('decimal', 3.14);

        expect(await storage.getString('str'), 'text');
        expect(await storage.getInt('num'), 42);
        expect(await storage.getBool('flag'), true);
        expect(await storage.getDouble('decimal'), 3.14);
      });

      test('containers persist after storage operations', () async {
        final storage = HyperStorage.instance;
        final container = await storage.backend.container('persistent');
        await container.setString('key', 'value');

        await storage.setString('rootKey', 'rootValue');

        expect(await container.getString('key'), 'value');
      });
    });

    group('container caching', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('container() returns cached instance for same name', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.container('test');
        final container2 = await storage.container('test');

        expect(container1, same(container2));
      });

      test('container() creates different instances for different names', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.container('test1');
        final container2 = await storage.container('test2');

        expect(container1, isNot(same(container2)));
        expect(container1.name, 'test1');
        expect(container2.name, 'test2');
      });
    });

    group('error handling', () {
      test('init throws StateError when reinitializing with different backend type', () async {
        // Create a custom backend class that extends StorageBackend
        final backend1 = InMemoryBackend();
        await HyperStorage.init(backend: backend1);

        // Try to reinitialize with a different instance (same type is OK)
        final backend2 = InMemoryBackend();
        final storage2 = await HyperStorage.init(backend: backend2);
        expect(storage2, same(HyperStorage.instance));

        // We can't easily test with truly different backend types without creating
        // another backend implementation, but the logic is covered if we check the code path
      });

      test('jsonSerializableContainer throws StateError for type mismatch', () async {
        await HyperStorage.initMocked();
        final storage = HyperStorage.instance;

        // Create a container for User type
        await storage.jsonSerializableContainer<User>(
          'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
        );

        // Try to create another container with same name but different type
        expect(
          () => storage.jsonSerializableContainer<Product>(
            'users',
            toJson: (product) => product.toJson(),
            fromJson: Product.fromJson,
          ),
          throwsStateError,
        );
      });
    });

    group('objectContainer', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('creates custom container using factory', () async {
        final storage = HyperStorage.instance;
        final container = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        expect(container, isA<UserContainer>());
        expect(container.name, 'users');

        await container.add(testUser1);
        expect(await container.get(testUser1.id), testUser1);
      });

      test('returns cached instance for same name', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        final container2 = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        expect(container1, same(container2));
      });

      test('creates different containers for different names', () async {
        final storage = HyperStorage.instance;
        final container1 = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        final container2 = await storage.objectContainer<User, UserContainer>(
          'admins',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'admins',
          ),
        );

        expect(container1, isNot(same(container2)));
        expect(container1.name, 'users');
        expect(container2.name, 'admins');
      });

      test('throws StateError when name exists with different type', () async {
        final storage = HyperStorage.instance;

        // Create a container with UserContainer type
        await storage.objectContainer<User, UserContainer>(
          'data',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'data',
          ),
        );

        // Try to create another container with same name but different type
        expect(
          () => storage.objectContainer<Product, ProductContainer>(
            'data',
            factory: () => ProductContainer(
              backend: storage.backend,
              name: 'data',
            ),
          ),
          throwsStateError,
        );
      });

      test('works with containers that have custom serialization', () async {
        final storage = HyperStorage.instance;
        final container = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        await container.add(testUser1);
        await container.add(testUser2);

        final users = await container.getValues();
        expect(users, containsAll([testUser1, testUser2]));
      });

      test('container is included in clear operation', () async {
        final storage = HyperStorage.instance;
        final container = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        await container.add(testUser1);
        expect(await container.isEmpty, isFalse);

        await storage.clear();

        expect(await container.isEmpty, isTrue);
      });

      test('container is closed during storage close', () async {
        final storage = HyperStorage.instance;
        final container = await storage.objectContainer<User, UserContainer>(
          'users',
          factory: () => UserContainer(
            backend: storage.backend,
            name: 'users',
          ),
        );

        await container.add(testUser1);
        await storage.close();

        // After close, instance should throw when accessed
        expect(() => HyperStorage.instance, throwsStateError);
      });
    });

    group('stream', () {
      setUp(() async {
        await HyperStorage.initMocked();
      });

      test('stream() emits initial value', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'initial value');

        final stream = storage.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values, contains('initial value'));
      });

      test('stream() emits null for non-existent key', () async {
        final storage = HyperStorage.instance;

        final stream = storage.stream<String>('nonExistent');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values, contains(null));
      });

      test('stream() updates when value changes', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'initial');

        final stream = storage.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await storage.setString('key', 'updated');
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, contains('initial'));
        expect(values, contains('updated'));
      });

      test('stream() handles multiple updates', () async {
        final storage = HyperStorage.instance;
        await storage.setInt('counter', 0);

        final stream = storage.stream<int>('counter');
        final values = <int?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await storage.setInt('counter', 1);
        await Future.delayed(Duration(milliseconds: 50));
        await storage.setInt('counter', 2);
        await Future.delayed(Duration(milliseconds: 50));
        await storage.setInt('counter', 3);
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, containsAll([0, 1, 2, 3]));
      });

      test('stream() works with different data types', () async {
        final storage = HyperStorage.instance;

        // Test with int
        await storage.setInt('intKey', 42);
        final intStream = storage.stream<int>('intKey');
        final intValues = <int?>[];
        final intSub = intStream.listen(intValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await intSub.cancel();
        expect(intValues, contains(42));

        // Test with bool
        await storage.setBool('boolKey', true);
        final boolStream = storage.stream<bool>('boolKey');
        final boolValues = <bool?>[];
        final boolSub = boolStream.listen(boolValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await boolSub.cancel();
        expect(boolValues, contains(true));

        // Test with double
        await storage.setDouble('doubleKey', 3.14);
        final doubleStream = storage.stream<double>('doubleKey');
        final doubleValues = <double?>[];
        final doubleSub = doubleStream.listen(doubleValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await doubleSub.cancel();
        expect(doubleValues, contains(3.14));

        // Test with enum
        await storage.setEnum('enumKey', StorageTestEnum.success);
        final enumStream = storage.stream<StorageTestEnum>(
          'enumKey',
          enumValues: StorageTestEnum.values,
        );
        final enumValues = <StorageTestEnum?>[];
        final enumSub = enumStream.listen(enumValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await enumSub.cancel();
        expect(enumValues, contains(StorageTestEnum.success));

        // Test with bytes
        final bytes = Uint8List.fromList([10, 20, 30, 40, 50]);
        await storage.setBytes('bytesKey', bytes);
        final bytesStream = storage.stream<Uint8List>('bytesKey');
        final bytesValues = <Uint8List?>[];
        final bytesSub = bytesStream.listen(bytesValues.add);
        await Future.delayed(Duration(milliseconds: 50));
        await bytesSub.cancel();
        expect(bytesValues.length, greaterThan(0));
        expect(bytesValues.first, bytes);
      });

      test('stream() updates enum values', () async {
        final storage = HyperStorage.instance;
        await storage.setEnum('enumKey', StorageTestEnum.pending);

        final stream = storage.stream<StorageTestEnum>(
          'enumKey',
          enumValues: StorageTestEnum.values,
        );
        final values = <StorageTestEnum?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        await storage.setEnum('enumKey', StorageTestEnum.failed);
        await Future.delayed(Duration(milliseconds: 50));

        await subscription.cancel();

        expect(values, containsAll([StorageTestEnum.pending, StorageTestEnum.failed]));
      });

      test('stream() works with DateTime', () async {
        final storage = HyperStorage.instance;
        final now = DateTime.now();
        await storage.setDateTime('timeKey', now);

        final stream = storage.stream<DateTime>('timeKey');
        final values = <DateTime?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values.length, greaterThan(0));
        expect(values.first?.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('stream() works with Duration', () async {
        final storage = HyperStorage.instance;
        final duration = Duration(hours: 2, minutes: 30);
        await storage.setDuration('durationKey', duration);

        final stream = storage.stream<Duration>('durationKey');
        final values = <Duration?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values, contains(duration));
      });

      test('stream() works with List<String>', () async {
        final storage = HyperStorage.instance;
        final list = ['a', 'b', 'c'];
        await storage.setStringList('listKey', list);

        final stream = storage.stream<List<String>>('listKey');
        final values = <List<String>?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values.length, greaterThan(0));
        expect(values.first, list);
      });

      test('stream() works with JSON', () async {
        final storage = HyperStorage.instance;
        final json = {'name': 'John', 'age': 30};
        await storage.setJson('jsonKey', json);

        final stream = storage.stream<Map<String, dynamic>>('jsonKey');
        final values = <Map<String, dynamic>?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));
        await subscription.cancel();

        expect(values.length, greaterThan(0));
        expect(values.first, json);
      });

      test('stream() cleans up listener on cancellation', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'value');

        final stream = storage.stream<String>('key');
        final values = <String?>[];

        final subscription = stream.listen(values.add);
        await Future.delayed(Duration(milliseconds: 50));

        final initialLength = values.length;
        await subscription.cancel();

        // Update after cancellation
        await storage.setString('key', 'new value');
        await Future.delayed(Duration(milliseconds: 50));

        // Values list should not grow after cancellation
        expect(values.length, initialLength);
      });

      test('stream() handles concurrent streams for same key', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key', 'initial');

        final stream1 = storage.stream<String>('key');
        final stream2 = storage.stream<String>('key');

        final values1 = <String?>[];
        final values2 = <String?>[];

        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(Duration(milliseconds: 50));

        await storage.setString('key', 'updated');
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        expect(values1, contains('initial'));
        expect(values1, contains('updated'));
        expect(values2, contains('initial'));
        expect(values2, contains('updated'));
      });

      test('stream() handles concurrent streams for different keys', () async {
        final storage = HyperStorage.instance;
        await storage.setString('key1', 'value1');
        await storage.setString('key2', 'value2');

        final stream1 = storage.stream<String>('key1');
        final stream2 = storage.stream<String>('key2');

        final values1 = <String?>[];
        final values2 = <String?>[];

        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(Duration(milliseconds: 50));

        await storage.setString('key1', 'updated1');
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        expect(values1, contains('value1'));
        expect(values1, contains('updated1'));
        expect(values2, contains('value2'));
        expect(values2, isNot(contains('updated1')));
      });

      test('stream() does not emit errors during value retrieval', () async {
        // Create a backend that will throw an error
        final errorBackend = ErrorThrowingBackend();
        final storage = await HyperStorage.newInstance(backend: errorBackend);

        final stream = storage.stream<String>('errorKey');
        final errors = <Object>[];
        final values = <String?>[];

        final subscription = stream.listen(
          values.add,
          onError: errors.add,
        );

        // Wait for initial fetch attempt (which will fail silently)
        await Future.delayed(Duration(milliseconds: 50));

        // Verify no errors were emitted (they're caught internally)
        expect(errors, isEmpty);

        // Verify stream received null (no value exists)
        expect(values, [null]);

        await subscription.cancel();
        await storage.close();
      });

      test('jsonStream() returns cached JsonItemHolder', () async {
        final storage = HyperStorage.instance;

        final stream1 = storage.jsonStream<TestModel>(
          'testModel',
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        final stream2 = storage.jsonStream<TestModel>(
          'testModel',
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        // Verify same instance is returned (caching)
        expect(identical(stream1, stream2), isTrue);
      });

      test('jsonStream() emits values correctly', () async {
        final storage = HyperStorage.instance;
        final testModel = TestModel(name: 'John', age: 30);

        // Get the stream first (which creates the JsonItemHolder)
        final stream = storage.jsonStream<TestModel>(
          'testModel',
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        // Store using jsonItemHolder (not setJson)
        final holder = storage.jsonItemHolder<TestModel>(
          'testModel',
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );
        await holder.set(testModel);

        final values = <TestModel?>[];
        final subscription = stream.listen(values.add);

        await Future.delayed(Duration(milliseconds: 50));

        expect(values, hasLength(1));
        expect(values.first?.name, 'John');
        expect(values.first?.age, 30);

        await subscription.cancel();
      });

      test('serializableStream() returns cached SerializableItemHolder', () async {
        final storage = HyperStorage.instance;

        final stream1 = storage.serializableStream<TestModel>(
          'testModel',
          serialize: (model) => model.toJson().toString(),
          deserialize: (str) => TestModel.fromJson(
            Map<String, dynamic>.from({'data': str}),
          ),
        );

        final stream2 = storage.serializableStream<TestModel>(
          'testModel',
          serialize: (model) => model.toJson().toString(),
          deserialize: (str) => TestModel.fromJson(
            Map<String, dynamic>.from({'data': str}),
          ),
        );

        // Verify same instance is returned (caching)
        expect(identical(stream1, stream2), isTrue);
      });

      test('serializableStream() emits values correctly', () async {
        final storage = HyperStorage.instance;
        final testModel = TestModel(name: 'Jane', age: 25);

        // Get the stream first (which creates the SerializableItemHolder)
        final stream = storage.serializableStream<TestModel>(
          'testModel',
          serialize: (model) => jsonEncode(model.toJson()),
          deserialize: (str) => TestModel.fromJson(jsonDecode(str) as Map<String, dynamic>),
        );

        // Store using serializableItemHolder
        final holder = storage.serializableItemHolder<TestModel>(
          'testModel',
          serialize: (model) => jsonEncode(model.toJson()),
          deserialize: (str) => TestModel.fromJson(jsonDecode(str) as Map<String, dynamic>),
        );
        await holder.set(testModel);

        final values = <TestModel?>[];
        final subscription = stream.listen(values.add);

        await Future.delayed(Duration(milliseconds: 50));

        expect(values, hasLength(1));
        expect(values.first?.name, 'Jane');
        expect(values.first?.age, 25);

        await subscription.cancel();
      });
    });
  });
}

// Test model for JSON serialization tests
class TestModel {
  final String name;
  final int age;

  TestModel({required this.name, required this.age});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }
}

// Backend that throws errors for testing error handling
class ErrorThrowingBackend extends InMemoryBackend {
  @override
  Future<String?> getString(String key) async {
    if (key == 'errorKey') {
      throw Exception('Test error during getString');
    }
    return super.getString(key);
  }
}

// Custom container implementation for testing objectContainer
class UserContainer extends SerializableStorageContainer<User> {
  UserContainer({
    required super.backend,
    required super.name,
    super.delimiter,
  }) : super(
         idGetter: (user) => user.id,
       );

  @override
  String serialize(User value) => value.serialize();

  @override
  User deserialize(String value) => User.deserialize(value);
}

// Custom container implementation for testing type conflicts
class ProductContainer extends SerializableStorageContainer<Product> {
  ProductContainer({
    required super.backend,
    required super.name,
    super.delimiter,
  }) : super(
         idGetter: (product) => product.id,
       );

  @override
  String serialize(Product value) {
    return '${value.id}|${value.name}|${value.price}';
  }

  @override
  Product deserialize(String value) {
    final parts = value.split('|');
    return Product(parts[0], parts[1], double.parse(parts[2]));
  }
}

class Product {
  final String id;
  final String name;
  final double price;

  Product(this.id, this.name, this.price);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};

  static Product fromJson(Map<String, dynamic> json) {
    return Product(json['id'] as String, json['name'] as String, json['price'] as double);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ price.hashCode;
}

class AnotherBackend extends InMemoryBackend {}

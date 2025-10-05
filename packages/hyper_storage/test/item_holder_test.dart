import 'dart:async';

import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('ItemHolder', () {
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

    group('basic ItemHolder', () {
      test('get returns null when item does not exist', () async {
        final holder = container.itemHolder<String>('key');
        final value = await holder.get();
        expect(value, isNull);
      });

      test('set and get work for String', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('value');
        final value = await holder.get();
        expect(value, 'value');
      });

      test('set and get work for int', () async {
        final holder = container.itemHolder<int>('counter');
        await holder.set(42);
        final value = await holder.get();
        expect(value, 42);
      });

      test('set and get work for double', () async {
        final holder = container.itemHolder<double>('price');
        await holder.set(99.99);
        final value = await holder.get();
        expect(value, 99.99);
      });

      test('set and get work for bool', () async {
        final holder = container.itemHolder<bool>('enabled');
        await holder.set(true);
        final value = await holder.get();
        expect(value, true);
      });

      test('set and get work for DateTime', () async {
        final holder = container.itemHolder<DateTime>('timestamp');
        final now = DateTime.now();
        await holder.set(now);

        final retrieved = await holder.get();
        expect(retrieved?.millisecondsSinceEpoch, now.toUtc().millisecondsSinceEpoch);
      });

      test('set and get work for Duration', () async {
        final holder = container.itemHolder<Duration>('timeout');
        final duration = Duration(hours: 2);
        await holder.set(duration);
        final value = await holder.get();
        expect(value, duration);
      });

      test('set and get work for List<String>', () async {
        final holder = container.itemHolder<List<String>>('items');
        final list = ['a', 'b', 'c'];
        await holder.set(list);
        final value = await holder.get();
        expect(value, list);
      });

      test('set and get work for Map<String, dynamic>', () async {
        final holder = container.itemHolder<Map<String, dynamic>>('data');
        final map = {'key': 'value', 'num': 42};
        await holder.set(map);
        final value = await holder.get();
        expect(value, map);
      });

      test('exists returns false when item does not exist', () async {
        final holder = container.itemHolder<String>('key');
        expect(await holder.exists, false);
      });

      test('exists returns true when item exists', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('value');
        expect(await holder.exists, true);
      });

      test('remove deletes the item', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('value');
        await holder.remove();

        expect(await holder.exists, false);
        expect(await holder.get(), isNull);
      });

      test('set overwrites existing value', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('value1');
        await holder.set('value2');
        expect(await holder.get(), 'value2');
      });
    });

    group('ItemHolder with custom getter and setter', () {
      test('uses custom getter and setter', () async {
        int getterCalls = 0;
        int setterCalls = 0;

        final holder = container.itemHolder<String>(
          'key',
          get: (backend, key) async {
            getterCalls++;
            return backend.getString(key);
          },
          set: (backend, key, value) async {
            setterCalls++;
            await backend.setString(key, value);
          },
        );

        await holder.set('value');
        expect(setterCalls, 1);

        final value = await holder.get();
        expect(getterCalls, 1);
        expect(value, 'value');
      });

      test('custom getter can transform data', () async {
        final holder = container.itemHolder<String>(
          'key',
          get: (backend, key) async {
            final value = await backend.getString(key);
            return value?.toUpperCase();
          },
          set: (backend, key, value) => backend.setString(key, value),
        );

        await holder.set('hello');
        expect(await holder.get(), 'HELLO');
      });

      test('throws when only getter is provided', () {
        expect(
          () => container.itemHolder<String>(
            'key',
            get: (backend, key) async => backend.getString(key),
          ),
          throwsArgumentError,
        );
      });

      test('throws when only setter is provided', () {
        expect(
          () => container.itemHolder<String>(
            'key',
            set: (backend, key, value) => backend.setString(key, value),
          ),
          throwsArgumentError,
        );
      });
    });

    group('JsonItemHolder', () {
      test('stores and retrieves JSON objects', () async {
        final holder = container.jsonItemHolder<User>(
          'user',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );

        await holder.set(testUser1);
        expect(await holder.get(), testUser1);
      });

      test('handles complex nested objects', () async {
        final holder = container.jsonItemHolder<User>(
          'user',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );

        await holder.set(testUser1);
        final retrieved = await holder.get();

        expect(retrieved?.id, testUser1.id);
        expect(retrieved?.name, testUser1.name);
        expect(retrieved?.email, testUser1.email);
        expect(retrieved?.age, testUser1.age);
      });

      test('returns null for non-existent item', () async {
        final holder = container.jsonItemHolder<User>(
          'user',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );

        expect(await holder.get(), isNull);
      });
    });

    group('SerializableItemHolder', () {
      test('uses custom serialization logic', () async {
        final holder = container.serializableItemHolder<User>(
          'user',
          serialize: (user) => user.serialize(),
          deserialize: User.deserialize,
        );

        await holder.set(testUser1);
        expect(await holder.get(), testUser1);
      });

      test('serialize and deserialize are called correctly', () async {
        int serializeCalls = 0;
        int deserializeCalls = 0;

        final holder = container.serializableItemHolder<User>(
          'user',
          serialize: (user) {
            serializeCalls++;
            return user.serialize();
          },
          deserialize: (data) {
            deserializeCalls++;
            return User.deserialize(data);
          },
        );

        await holder.set(testUser1);
        expect(serializeCalls, 1);

        await holder.get();
        expect(deserializeCalls, 1);
      });
    });

    group('listeners', () {
      test('addListener registers listener', () async {
        final holder = container.itemHolder<String>('key');
        int callCount = 0;

        holder.addListener(() {
          callCount++;
        });

        await holder.set('value1');
        await holder.set('value2');

        // Wait a bit for async listeners
        await Future.delayed(Duration(milliseconds: 10));
        expect(callCount, greaterThan(0));
      });

      test('removeListener unregisters listener', () async {
        final holder = container.itemHolder<String>('key');
        int callCount = 0;

        void listener() {
          callCount++;
        }

        holder.addListener(listener);
        await holder.set('value1');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterFirst = callCount;

        holder.removeListener(listener);
        await holder.set('value2');
        await Future.delayed(Duration(milliseconds: 10));

        // Count should not increase after removing listener
        expect(callCount, countAfterFirst);
      });

      test('removeAllListeners clears all listeners', () async {
        final holder = container.itemHolder<String>('key');
        int count1 = 0;
        int count2 = 0;

        holder.addListener(() => count1++);
        holder.addListener(() => count2++);

        await holder.set('value1');
        await Future.delayed(Duration(milliseconds: 10));
        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));

        holder.removeAllListeners();
        final prevCount1 = count1;
        final prevCount2 = count2;

        await holder.set('value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, prevCount1);
        expect(count2, prevCount2);
      });

      test('hasListeners returns correct value', () async {
        final holder = container.itemHolder<String>('key');
        expect(holder.hasListeners, false);

        holder.addListener(() {});
        expect(holder.hasListeners, true);

        holder.removeAllListeners();
        expect(holder.hasListeners, false);
      });
    });

    group('Stream interface', () {
      test('listen provides initial value', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('initial');

        final completer = Completer<String?>();
        final subscription = holder.listen((value) {
          if (!completer.isCompleted) {
            completer.complete(value);
          }
        });

        final value = await completer.future.timeout(Duration(seconds: 2));
        expect(value, 'initial');

        await subscription.cancel();
      });

      test('listen receives updates', () async {
        final holder = container.itemHolder<String>('key');

        final values = <String?>[];
        final completer = Completer<void>();

        final subscription = holder.listen((value) {
          values.add(value);
          if (values.length >= 3 && !completer.isCompleted) {
            completer.complete();
          }
        });

        // Wait a bit for initial null value
        await Future.delayed(Duration(milliseconds: 100));

        await holder.set('value1');
        await Future.delayed(Duration(milliseconds: 100));

        await holder.set('value2');
        await Future.delayed(Duration(milliseconds: 100));

        // Wait for stream events or timeout
        await completer.future.timeout(
          Duration(seconds: 2),
          onTimeout: () {},
        );

        // Should have received null, value1, value2
        expect(values.length, greaterThanOrEqualTo(2));

        await subscription.cancel();
      });

      test('listen handles errors', () async {
        final holder = container.itemHolder<String>('key');

        final subscription = holder.listen(
          (value) {},
          onError: (error) {
            // Error handler registered
          },
        );

        await Future.delayed(Duration(milliseconds: 100));

        await subscription.cancel();
      });

      test('stream can be cancelled', () async {
        final holder = container.itemHolder<String>('key');

        final values = <String?>[];
        final subscription = holder.listen((value) {
          values.add(value);
        });

        await Future.delayed(Duration(milliseconds: 100));
        final countBeforeCancel = values.length;

        await subscription.cancel();

        await holder.set('after-cancel');
        await Future.delayed(Duration(milliseconds: 100));

        // Values should not increase after cancel
        expect(values.length, countBeforeCancel);
        expect(values.where((v) => v == 'after-cancel'), isEmpty);
      });
    });

    group('dispose', () {
      test('dispose removes all listeners and closes stream', () async {
        final holder = container.itemHolder<String>('key');

        holder.addListener(() {});
        expect(holder.hasListeners, true);

        holder.dispose();
        expect(holder.hasListeners, false);
      });

      test('operations after dispose do not throw', () async {
        final holder = container.itemHolder<String>('key');
        await holder.set('value');

        holder.dispose();

        // These should not throw, but may not work as expected
        expect(() => holder.get(), returnsNormally);
        expect(() => holder.set('new'), returnsNormally);
      });
    });

    group('edge cases', () {
      test('handles rapid sequential operations', () async {
        final holder = container.itemHolder<int>('counter');

        for (int i = 0; i < 100; i++) {
          await holder.set(i);
        }

        final value = await holder.get();
        expect(value, 99);
      });

      test('handles null values correctly', () async {
        final holder = container.itemHolder<String>('key');

        await holder.set('value');
        await holder.remove();

        final value = await holder.get();
        expect(value, isNull);
        expect(await holder.exists, false);
      });

      test('multiple holders for same key share data', () async {
        final holder1 = container.itemHolder<String>('sharedKey');
        final holder2 = container.itemHolder<String>('sharedKey');

        await holder1.set('value');
        final value1 = await holder2.get();
        expect(value1, 'value');

        await holder2.set('updated');
        final value2 = await holder1.get();
        expect(value2, 'updated');

        holder1.dispose();
        holder2.dispose();
      });
    });

    group('type safety', () {
      test('throws for unsupported types without custom getter/setter', () {
        expect(
          () => container.itemHolder<User>('key'),
          throwsUnsupportedError,
        );
      });

      test('allows unsupported types with custom getter/setter', () {
        expect(
          () => container.itemHolder<User>(
            'key',
            get: (backend, key) async {
              final json = await backend.getJson(key);
              if (json == null) return null;
              return User.fromJson(json);
            },
            set: (backend, key, value) => backend.setJson(key, value.toJson()),
          ),
          returnsNormally,
        );
      });
    });

    group('customItemHolder', () {
      test('creates custom ItemHolder with factory', () async {
        final customHolder = container.customItemHolder<CustomUserHolder, User>(
          'user',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );

        expect(customHolder, isA<CustomUserHolder>());
        expect(customHolder.key, 'test___user');
      });

      test('custom ItemHolder works with custom serialization', () async {
        final customHolder = container.customItemHolder<CustomUserHolder, User>(
          'user',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );

        await customHolder.set(testUser1);
        final retrieved = await customHolder.get();
        expect(retrieved, testUser1);
      });

      test('validates key in customItemHolder', () {
        expect(
          () => container.customItemHolder<CustomUserHolder, User>(
            '',
            create: (backend, key) => CustomUserHolder(container, backend, key),
          ),
          throwsArgumentError,
        );

        expect(
          () => container.customItemHolder<CustomUserHolder, User>(
            '   ',
            create: (backend, key) => CustomUserHolder(container, backend, key),
          ),
          throwsArgumentError,
        );
      });

      test('custom ItemHolder receives encoded key', () async {
        final customHolder = container.customItemHolder<CustomUserHolder, User>(
          'user',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );

        // Key should be encoded with container prefix
        expect(customHolder.key, 'test___user');
      });
    });

    group('ItemHolder caching', () {
      test('itemHolder returns same instance for same key', () {
        final holder1 = container.itemHolder<String>('cache-test');
        final holder2 = container.itemHolder<String>('cache-test');
        expect(identical(holder1, holder2), true);
      });

      test('itemHolder throws ArgumentError for type mismatch', () {
        // Create a holder with String type
        container.itemHolder<String>('type-mismatch');

        // Attempt to create another holder with same key but different type
        expect(
          () => container.itemHolder<int>('type-mismatch'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('An ItemHolder with key "type-mismatch" already exists with a different type'),
            ),
          ),
        );
      });

      test('jsonItemHolder returns same instance for same key', () {
        final holder1 = container.jsonItemHolder<User>(
          'user-cache',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );
        final holder2 = container.jsonItemHolder<User>(
          'user-cache',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );
        expect(identical(holder1, holder2), true);
      });

      test('jsonItemHolder throws ArgumentError for type mismatch', () {
        // Create a JsonItemHolder with User type
        container.jsonItemHolder<User>(
          'json-mismatch',
          fromJson: User.fromJson,
          toJson: (user) => user.toJson(),
        );

        // Attempt to create another JsonItemHolder with same key but different type
        expect(
          () => container.jsonItemHolder<Map<String, dynamic>>(
            'json-mismatch',
            fromJson: (json) => json,
            toJson: (data) => data,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('An ItemHolder with key "json-mismatch" already exists with a different type'),
            ),
          ),
        );
      });

      test('serializableItemHolder returns same instance for same key', () {
        final holder1 = container.serializableItemHolder<User>(
          'serializable-cache',
          serialize: (user) => user.serialize(),
          deserialize: User.deserialize,
        );
        final holder2 = container.serializableItemHolder<User>(
          'serializable-cache',
          serialize: (user) => user.serialize(),
          deserialize: User.deserialize,
        );
        expect(identical(holder1, holder2), true);
      });

      test('serializableItemHolder throws ArgumentError for type mismatch', () {
        // Create a SerializableItemHolder with User type
        container.serializableItemHolder<User>(
          'serializable-mismatch',
          serialize: (user) => user.serialize(),
          deserialize: User.deserialize,
        );

        // Attempt to create another SerializableItemHolder with same key but different type
        expect(
          () => container.serializableItemHolder<String>(
            'serializable-mismatch',
            serialize: (s) => s,
            deserialize: (s) => s,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('An ItemHolder with key "serializable-mismatch" already exists with a different type'),
            ),
          ),
        );
      });

      test('customItemHolder returns same instance for same key', () {
        final holder1 = container.customItemHolder<CustomUserHolder, User>(
          'custom-cache',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );
        final holder2 = container.customItemHolder<CustomUserHolder, User>(
          'custom-cache',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );
        expect(identical(holder1, holder2), true);
      });

      test('customItemHolder throws ArgumentError for type mismatch', () {
        // Create a CustomItemHolder
        container.customItemHolder<CustomUserHolder, User>(
          'custom-mismatch',
          create: (backend, key) => CustomUserHolder(container, backend, key),
        );

        // Attempt to create another CustomItemHolder with same key but different holder type
        expect(
          () => container.customItemHolder<AnotherCustomHolder, String>(
            'custom-mismatch',
            create: (backend, key) => AnotherCustomHolder(container, backend, key),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('An ItemHolder with key "custom-mismatch" already exists with a different type'),
            ),
          ),
        );
      });
    });
  });
}

// Custom ItemHolder implementation for testing customItemHolder
class CustomUserHolder extends ItemHolder<User> {
  final String _encodedKey;

  CustomUserHolder(HyperStorageContainer parent, StorageBackend backend, this._encodedKey)
    : super(
        parent,
        _encodedKey,
        getter: (backend, key) async {
          final json = await backend.getJson(key);
          if (json == null) return null;
          return User.fromJson(json);
        },
        setter: (backend, key, value) => backend.setJson(key, value.toJson()),
      );

  String get key => _encodedKey;
}

// Another custom ItemHolder for testing type mismatch
class AnotherCustomHolder extends ItemHolder<String> {
  AnotherCustomHolder(HyperStorageContainer super.parent, StorageBackend backend, super.key)
    : super(
        getter: (backend, key) => backend.getString(key),
        setter: (backend, key, value) => backend.setString(key, value),
      );
}

import 'dart:math';

import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('JsonStorageContainer', () {
    late InMemoryBackend backend;
    late JsonStorageContainer<User> userContainer;

    setUp(() async {
      backend = InMemoryBackend();
      await backend.init();
      userContainer = JsonStorageContainer<User>(
        backend: backend,
        name: 'users',
        toJson: (user) => user.toJson(),
        fromJson: User.fromJson,
        idGetter: (user) => user.id,
      );
    });

    tearDown(() async {
      await userContainer.close();
      await backend.close();
    });

    group('basic CRUD operations', () {
      test('add stores a user', () async {
        await userContainer.add(testUser1);
        final retrieved = await userContainer.get(testUser1.id);
        expect(retrieved, testUser1);
      });

      test('set stores a user with explicit key', () async {
        await userContainer.set('customKey', testUser1);
        final retrieved = await userContainer.get('customKey');
        expect(retrieved, testUser1);
      });

      test('get returns null for non-existent key', () async {
        expect(await userContainer.get('nonExistent'), isNull);
      });

      test('get returns null for null key', () async {
        expect(await userContainer.get(null), isNull);
      });

      test('update modifies existing user', () async {
        await userContainer.add(testUser1);

        final updated = User(testUser1.id, 'John Updated', testUser1.email, 31);
        await userContainer.update(updated);

        final retrieved = await userContainer.get(testUser1.id);
        expect(retrieved, updated);
      });

      test('update throws on non-existent user', () async {
        final newUser = User('newId', 'New User', 'new@test.com', 25);
        await expectLater(
          userContainer.update(newUser),
          throwsStateError,
        );
      });

      test('remove deletes a user', () async {
        await userContainer.add(testUser1);
        await userContainer.remove(testUser1.id);

        expect(await userContainer.get(testUser1.id), isNull);
        expect(await userContainer.containsKey(testUser1.id), false);
      });

      test('removeItem deletes by object', () async {
        await userContainer.add(testUser1);
        await userContainer.removeItem(testUser1);

        expect(await userContainer.get(testUser1.id), isNull);
      });
    });

    group('batch operations', () {
      test('addAll stores multiple users', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);

        expect(await userContainer.get(testUser1.id), testUser1);
        expect(await userContainer.get(testUser2.id), testUser2);
        expect(await userContainer.get(testUser3.id), testUser3);
      });

      test('setAll stores users with explicit keys', () async {
        await userContainer.setAll({
          'key1': testUser1,
          'key2': testUser2,
        });

        expect(await userContainer.get('key1'), testUser1);
        expect(await userContainer.get('key2'), testUser2);
      });

      test('updateAll modifies multiple users', () async {
        await userContainer.addAll([testUser1, testUser2]);

        final updated1 = User(testUser1.id, 'Updated1', testUser1.email, 31);
        final updated2 = User(testUser2.id, 'Updated2', testUser2.email, 26);

        await userContainer.updateAll([updated1, updated2]);

        expect(await userContainer.get(testUser1.id), updated1);
        expect(await userContainer.get(testUser2.id), updated2);
      });

      test('updateAll throws if any user does not exist', () async {
        await userContainer.add(testUser1);

        final updated1 = User(testUser1.id, 'Updated', testUser1.email, 31);
        final newUser = User('newId', 'New', 'new@test.com', 25);

        await expectLater(
          userContainer.updateAll([updated1, newUser]),
          throwsStateError,
        );
      });

      test('removeAll deletes multiple users by key', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);
        await userContainer.removeAll([testUser1.id, testUser3.id]);

        expect(await userContainer.containsKey(testUser1.id), false);
        expect(await userContainer.containsKey(testUser2.id), true);
        expect(await userContainer.containsKey(testUser3.id), false);
      });

      test('removeAllItems deletes multiple users by object', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);
        await userContainer.removeAllItems([testUser1, testUser3]);

        expect(await userContainer.containsKey(testUser1.id), false);
        expect(await userContainer.containsKey(testUser2.id), true);
        expect(await userContainer.containsKey(testUser3.id), false);
      });
    });

    group('query operations', () {
      test('getAll returns all users', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);

        final all = await userContainer.getAll();
        expect(all.length, 3);
        expect(all[testUser1.id], testUser1);
        expect(all[testUser2.id], testUser2);
        expect(all[testUser3.id], testUser3);
      });

      test('getAll with allowList filters users', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);

        final filtered = await userContainer.getAll([testUser1.id, testUser3.id]);
        expect(filtered.length, 2);
        expect(filtered[testUser1.id], testUser1);
        expect(filtered[testUser3.id], testUser3);
        expect(filtered.containsKey(testUser2.id), false);
      });

      test('getValues returns list of all users', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);

        final values = await userContainer.getValues();
        expect(values.length, 3);
        expect(values, containsAll([testUser1, testUser2, testUser3]));
      });

      test('getKeys returns all user IDs', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);

        final keys = await userContainer.getKeys();
        expect(keys, {testUser1.id, testUser2.id, testUser3.id});
      });

      test('containsKey returns correct status', () async {
        await userContainer.add(testUser1);

        expect(await userContainer.containsKey(testUser1.id), true);
        expect(await userContainer.containsKey('nonExistent'), false);
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty returns true for empty container', () async {
        expect(await userContainer.isEmpty, true);
      });

      test('isEmpty returns false when users exist', () async {
        await userContainer.add(testUser1);
        expect(await userContainer.isEmpty, false);
      });

      test('isNotEmpty returns false for empty container', () async {
        expect(await userContainer.isNotEmpty, false);
      });

      test('isNotEmpty returns true when users exist', () async {
        await userContainer.add(testUser1);
        expect(await userContainer.isNotEmpty, true);
      });
    });

    group('clear operations', () {
      test('clear removes all users', () async {
        await userContainer.addAll([testUser1, testUser2, testUser3]);
        await userContainer.clear();

        expect(await userContainer.isEmpty, true);
        expect(await userContainer.getKeys(), isEmpty);
      });

      test('clear only affects this container', () async {
        final otherContainer = JsonStorageContainer<User>(
          backend: backend,
          name: 'otherUsers',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
        );

        await userContainer.add(testUser1);
        await otherContainer.add(testUser2);

        await userContainer.clear();

        expect(await userContainer.isEmpty, true);
        expect(await otherContainer.get(testUser2.id), testUser2);

        await otherContainer.close();
      });
    });

    group('auto-generated IDs', () {
      late JsonStorageContainer<Note> noteContainer;

      setUp(() {
        noteContainer = JsonStorageContainer<Note>(
          backend: backend,
          name: 'notes',
          toJson: (note) => note.toJson(),
          fromJson: Note.fromJson,
          seed: 12345, // Use seed for deterministic testing
        );
      });

      tearDown(() async {
        await noteContainer.close();
      });

      test('add generates ID when no idGetter provided', () async {
        await noteContainer.add(testNote1);

        final keys = await noteContainer.getKeys();
        expect(keys.length, 1);

        final id = keys.first;
        final retrieved = await noteContainer.get(id);
        expect(retrieved, testNote1);
      });

      test('addAll generates unique IDs for each item', () async {
        await noteContainer.addAll([testNote1, testNote2]);

        final keys = await noteContainer.getKeys();
        expect(keys.length, 2);
      });

      test('generated IDs are non-empty strings', () async {
        await noteContainer.add(testNote1);

        final keys = await noteContainer.getKeys();
        final id = keys.first;
        expect(id, isNotEmpty);
        expect(id, isA<String>());
      });
    });

    group('custom delimiter', () {
      test('works with custom delimiter', () async {
        final customContainer = JsonStorageContainer<User>(
          backend: backend,
          name: 'customUsers',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
          delimiter: '---',
        );

        await customContainer.add(testUser1);
        expect(await customContainer.get(testUser1.id), testUser1);

        await customContainer.close();
      });
    });

    group('custom Random', () {
      test('uses provided Random for ID generation', () async {
        final random1 = Random(42);
        final random2 = Random(42);

        final container1 = JsonStorageContainer<Note>(
          backend: InMemoryBackend(),
          name: 'notes1',
          toJson: (note) => note.toJson(),
          fromJson: Note.fromJson,
          random: random1,
        );

        final container2 = JsonStorageContainer<Note>(
          backend: InMemoryBackend(),
          name: 'notes2',
          toJson: (note) => note.toJson(),
          fromJson: Note.fromJson,
          random: random2,
        );

        await container1.add(testNote1);
        await container2.add(testNote1);

        final keys1 = await container1.getKeys();
        final keys2 = await container2.getKeys();

        // With same seed, should generate same IDs
        expect(keys1.first, keys2.first);

        await container1.close();
        await container2.close();
      });
    });

    group('serialization edge cases', () {
      test('handles special characters in user data', () async {
        final specialUser = User('id123', 'John "Doe"', 'test@example.com\n', 30);
        await userContainer.add(specialUser);

        final retrieved = await userContainer.get('id123');
        expect(retrieved, specialUser);
      });

      test('handles empty string fields', () async {
        final emptyUser = User('id', '', '', 0);
        await userContainer.add(emptyUser);

        final retrieved = await userContainer.get('id');
        expect(retrieved, emptyUser);
      });

      test('handles unicode characters', () async {
        final unicodeUser = User('id', '日本語', '中文@test.com', 30);
        await userContainer.add(unicodeUser);

        final retrieved = await userContainer.get('id');
        expect(retrieved, unicodeUser);
      });
    });

    group('container isolation', () {
      test('different containers with different names are isolated', () async {
        final container2 = JsonStorageContainer<User>(
          backend: backend,
          name: 'admins',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
        );

        await userContainer.add(testUser1);
        await container2.add(testUser2);

        expect(await userContainer.getKeys(), {testUser1.id});
        expect(await container2.getKeys(), {testUser2.id});

        await container2.close();
      });

      test('containers with same name share data', () async {
        await userContainer.add(testUser1);

        final sameNameContainer = JsonStorageContainer<User>(
          backend: backend,
          name: 'users',
          toJson: (user) => user.toJson(),
          fromJson: User.fromJson,
          idGetter: (user) => user.id,
        );

        expect(await sameNameContainer.get(testUser1.id), testUser1);

        await sameNameContainer.close();
      });
    });

    group('serialize and deserialize', () {
      test('serialize converts object to JSON string', () {
        final json = userContainer.serialize(testUser1);
        expect(json, isA<String>());
        expect(json.contains(testUser1.name), true);
        expect(json.contains(testUser1.email), true);
      });

      test('deserialize converts JSON string to object', () {
        final json = userContainer.serialize(testUser1);
        final deserialized = userContainer.deserialize(json);
        expect(deserialized, testUser1);
      });

      test('serialize and deserialize are reversible', () {
        final serialized = userContainer.serialize(testUser1);
        final deserialized = userContainer.deserialize(serialized);
        final reserialized = userContainer.serialize(deserialized);
        expect(reserialized, serialized);
      });
    });

    group('ID behavior', () {
      test('uses idGetter when provided', () async {
        await userContainer.add(testUser1);
        final retrieved = await userContainer.get(testUser1.id);
        expect(retrieved?.id, testUser1.id);
      });

      test('validates extracted ID', () async {
        final badUser = User('', 'Bad', 'bad@test.com', 30);
        expect(
          () => userContainer.add(badUser),
          throwsArgumentError,
        );
      });
    });

    group('concurrent operations', () {
      test('handles concurrent adds', () async {
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(userContainer.add(User('user$i', 'User $i', 'user$i@test.com', 20 + i)));
        }

        await Future.wait(futures);

        final keys = await userContainer.getKeys();
        expect(keys.length, 10);
      });

      test('handles concurrent updates', () async {
        await userContainer.add(testUser1);

        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(userContainer.update(User(testUser1.id, 'Update $i', testUser1.email, 30 + i)));
        }

        await Future.wait(futures);

        final retrieved = await userContainer.get(testUser1.id);
        expect(retrieved, isNotNull);
      });
    });
  });
}

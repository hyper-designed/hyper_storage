import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

enum TestEnum { a, b, c }

enum ShortEnum { x, y }

void main() {
  group('ItemHolder _checkExistingMatch edge cases', () {
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

    test('throws when downgrading enum holder to custom accessor holder', () {
      // Create enum holder first
      container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      // Try to create custom accessor holder with same key
      expect(
        () => container.itemHolder<TestEnum>(
          'enumKey',
          get: (backend, key) async {
            final name = await backend.getString(key);
            return name == null ? null : TestEnum.values.byName(name);
          },
          set: (backend, key, value) => backend.setString(key, value.name),
        ),
        throwsStateError,
      );
    });

    test('throws when downgrading enum holder to non-enum holder', () {
      // Create enum holder with enumValues
      container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      // Try to create same holder without enumValues
      // This throws UnsupportedError because enum type requires enumValues
      expect(
        () => container.itemHolder<TestEnum>(
          'enumKey',
          enumValues: null,
        ),
        throwsUnsupportedError,
      );
    });

    test('throws when enumValues have different lengths', () {
      // Create holder with full enum
      container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      // Try to create with partial enum (different length)
      // Must explicitly type the list to avoid type inference issues
      expect(
        () => container.itemHolder<TestEnum>(
          'enumKey',
          enumValues: <TestEnum>[TestEnum.a, TestEnum.b], // Only 2 instead of 3
        ),
        throwsStateError,
      );
    });

    test('throws when trying to use completely different enum type', () {
      // Create holder with TestEnum
      container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      // Try to create with ShortEnum (different type)
      expect(
        () => container.itemHolder<ShortEnum>(
          'enumKey',
          enumValues: ShortEnum.values,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('already exists with a different type'),
          ),
        ),
      );
    });

    test('allows reusing holder with identical enumValues', () {
      final holder1 = container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      final holder2 = container.itemHolder<TestEnum>(
        'enumKey',
        enumValues: TestEnum.values,
      );

      expect(holder1, same(holder2));
    });

    test('allows reusing holder without enumValues when both have none', () {
      final holder1 = container.itemHolder<String>('stringKey');
      final holder2 = container.itemHolder<String>('stringKey');

      expect(holder1, same(holder2));
    });

    test('throws when adding enumValues to existing custom accessor holder', () {
      Future<TestEnum?> getter(StorageBackend backend, String key) async {
        final name = await backend.getString(key);
        return name == null ? null : TestEnum.values.byName(name);
      }

      Future<void> setter(StorageBackend backend, String key, TestEnum value) {
        return backend.setString(key, value.name);
      }

      container.itemHolder<TestEnum>(
        'enumKey',
        get: getter,
        set: setter,
      );

      expect(
        () => container.itemHolder<TestEnum>(
          'enumKey',
          get: getter,
          set: setter,
          enumValues: TestEnum.values,
        ),
        throwsStateError,
      );
    });

    test('throws when removing enumValues from existing custom accessor holder', () {
      Future<TestEnum?> getter(StorageBackend backend, String key) async {
        final name = await backend.getString(key);
        return name == null ? null : TestEnum.values.byName(name);
      }

      Future<void> setter(StorageBackend backend, String key, TestEnum value) {
        return backend.setString(key, value.name);
      }

      container.itemHolder<TestEnum>(
        'enumKey',
        get: getter,
        set: setter,
        enumValues: TestEnum.values,
      );

      expect(
        () => container.itemHolder<TestEnum>(
          'enumKey',
          get: getter,
          set: setter,
        ),
        throwsStateError,
      );
    });
  });
}

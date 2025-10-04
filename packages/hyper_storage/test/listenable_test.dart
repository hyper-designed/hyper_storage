import 'package:hyper_storage/hyper_storage.dart';
import 'package:test/test.dart';

void main() {
  group('ListenableStorage', () {
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

    group('global listeners', () {
      test('addListener registers listener', () {
        expect(container.hasListeners, false);

        container.addListener(() {});

        expect(container.hasListeners, true);
      });

      test('listener is called on data change', () async {
        int callCount = 0;

        container.addListener(() {
          callCount++;
        });

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, greaterThan(0));
      });

      test('multiple listeners are all called', () async {
        int count1 = 0;
        int count2 = 0;
        int count3 = 0;

        container.addListener(() => count1++);
        container.addListener(() => count2++);
        container.addListener(() => count3++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));
        expect(count3, greaterThan(0));
      });

      test('same listener added multiple times only registered once', () async {
        int callCount = 0;

        void listener() {
          callCount++;
        }

        container.addListener(listener);
        container.addListener(listener);
        container.addListener(listener);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        // Should only be called once per change, not three times
        expect(callCount, 1);
      });

      test('removeListener unregisters listener', () async {
        int callCount = 0;

        void listener() {
          callCount++;
        }

        container.addListener(listener);
        await container.setString('key', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterFirst = callCount;
        expect(countAfterFirst, greaterThan(0));

        container.removeListener(listener);
        await container.setString('key', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, countAfterFirst);
      });

      test('removeListener on non-registered listener is safe', () {
        expect(() => container.removeListener(() {}), returnsNormally);
      });

      test('removeAllListeners clears all listeners', () async {
        int count1 = 0;
        int count2 = 0;

        container.addListener(() => count1++);
        container.addListener(() => count2++);

        await container.setString('key', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));

        container.removeAllListeners();
        final prevCount1 = count1;
        final prevCount2 = count2;

        await container.setString('key', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, prevCount1);
        expect(count2, prevCount2);
        expect(container.hasListeners, false);
      });
    });

    group('key-specific listeners', () {
      test('addKeyListener registers listener for specific key', () {
        container.addKeyListener('key1', () {});

        expect(container.hasKeyListeners('key1'), true);
        expect(container.hasKeyListeners('key2'), false);
      });

      test('key listener called only for specific key', () async {
        int count1 = 0;
        int count2 = 0;

        container.addKeyListener('key1', () => count1++);
        container.addKeyListener('key2', () => count2++);

        await container.setString('key1', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, greaterThan(0));
        expect(count2, 0);

        await container.setString('key2', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count2, greaterThan(0));
      });

      test('multiple listeners for same key all called', () async {
        int count1 = 0;
        int count2 = 0;

        container.addKeyListener('key', () => count1++);
        container.addKeyListener('key', () => count2++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));
      });

      test('removeKeyListener removes specific key listener', () async {
        int callCount = 0;

        void listener() {
          callCount++;
        }

        container.addKeyListener('key', listener);
        await container.setString('key', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterFirst = callCount;

        container.removeKeyListener('key', listener);
        await container.setString('key', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, countAfterFirst);
      });

      test('removeAllKeyListeners removes all listeners for key', () async {
        int count1 = 0;
        int count2 = 0;

        container.addKeyListener('key', () => count1++);
        container.addKeyListener('key', () => count2++);

        await container.setString('key', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));

        container.removeAllKeyListeners('key');
        final prevCount1 = count1;
        final prevCount2 = count2;

        await container.setString('key', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(count1, prevCount1);
        expect(count2, prevCount2);
      });

      test('key listeners work with encoded keys', () async {
        int callCount = 0;

        container.addKeyListener('myKey', () => callCount++);

        await container.setString('myKey', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, greaterThan(0));
      });
    });

    group('combined listeners', () {
      test('both global and key listeners are called', () async {
        int globalCount = 0;
        int keyCount = 0;

        container.addListener(() => globalCount++);
        container.addKeyListener('key', () => keyCount++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(globalCount, greaterThan(0));
        expect(keyCount, greaterThan(0));
      });

      test('global listener called for any key change', () async {
        int globalCount = 0;

        container.addListener(() => globalCount++);

        await container.setString('key1', 'value1');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterKey1 = globalCount;

        await container.setString('key2', 'value2');
        await Future.delayed(Duration(milliseconds: 10));

        expect(globalCount, greaterThan(countAfterKey1));
      });
    });

    group('listener error handling', () {
      test('listener exception does not break other listeners', () async {
        int goodListenerCount = 0;

        container.addListener(() {
          throw Exception('Test exception');
        });

        container.addListener(() {
          goodListenerCount++;
        });

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(goodListenerCount, greaterThan(0));
      });

      test('key listener exception does not break other listeners', () async {
        int goodListenerCount = 0;

        container.addKeyListener('key', () {
          throw Exception('Test exception');
        });

        container.addKeyListener('key', () {
          goodListenerCount++;
        });

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(goodListenerCount, greaterThan(0));
      });

      test('exception in global listener does not affect key listeners', () async {
        int keyListenerCount = 0;

        container.addListener(() {
          throw Exception('Global listener error');
        });

        container.addKeyListener('key', () {
          keyListenerCount++;
        });

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(keyListenerCount, greaterThan(0));
      });
    });

    group('operations triggering listeners', () {
      test('setString triggers listeners', () async {
        int callCount = 0;
        container.addListener(() => callCount++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, greaterThan(0));
      });

      test('setInt triggers listeners', () async {
        int callCount = 0;
        container.addListener(() => callCount++);

        await container.setInt('key', 42);
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, greaterThan(0));
      });

      test('setAll triggers listeners', () async {
        int globalCount = 0;
        int key1Count = 0;
        int key2Count = 0;

        container.addListener(() => globalCount++);
        container.addKeyListener('key1', () => key1Count++);
        container.addKeyListener('key2', () => key2Count++);

        await container.setAll({'key1': 'value1', 'key2': 'value2'});
        await Future.delayed(Duration(milliseconds: 10));

        expect(globalCount, greaterThan(0));
        expect(key1Count, greaterThan(0));
        expect(key2Count, greaterThan(0));
      });

      test('remove triggers listeners', () async {
        int callCount = 0;
        container.addKeyListener('key', () => callCount++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        final countAfterSet = callCount;

        await container.remove('key');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, greaterThan(countAfterSet));
      });

      test('removeAll triggers listeners for each key', () async {
        int key1Count = 0;
        int key2Count = 0;

        container.addKeyListener('key1', () => key1Count++);
        container.addKeyListener('key2', () => key2Count++);

        await container.setAll({'key1': 'value1', 'key2': 'value2'});
        await Future.delayed(Duration(milliseconds: 10));

        // Reset counts
        key1Count = 0;
        key2Count = 0;

        await container.removeAll(['key1', 'key2']);
        await Future.delayed(Duration(milliseconds: 10));

        expect(key1Count, greaterThan(0));
        expect(key2Count, greaterThan(0));
      });

      test('clear triggers listeners', () async {
        int globalCount = 0;
        container.addListener(() => globalCount++);

        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        globalCount = 0; // Reset

        await container.clear();
        await Future.delayed(Duration(milliseconds: 10));

        expect(globalCount, greaterThan(0));
      });
    });

    group('hasListeners', () {
      test('returns false when no listeners', () {
        expect(container.hasListeners, false);
      });

      test('returns true when global listener exists', () {
        container.addListener(() {});
        expect(container.hasListeners, true);
      });

      test('returns true when key listener exists', () {
        container.addKeyListener('key', () {});
        expect(container.hasListeners, true);
      });

      test('returns false after removing all listeners', () {
        container.addListener(() {});
        container.addKeyListener('key', () {});

        container.removeAllListeners();

        expect(container.hasListeners, false);
      });
    });

    group('hasKeyListeners', () {
      test('returns false when no listeners for key', () {
        expect(container.hasKeyListeners('key'), false);
      });

      test('returns true when listener exists for key', () {
        container.addKeyListener('key', () {});
        expect(container.hasKeyListeners('key'), true);
      });

      test('returns false after removing key listeners', () {
        container.addKeyListener('key', () {});
        container.removeAllKeyListeners('key');

        expect(container.hasKeyListeners('key'), false);
      });

      test('removing one key listener does not affect other keys', () {
        container.addKeyListener('key1', () {});
        container.addKeyListener('key2', () {});

        container.removeAllKeyListeners('key1');

        expect(container.hasKeyListeners('key1'), false);
        expect(container.hasKeyListeners('key2'), true);
      });
    });

    group('listener lifecycle', () {
      test('listeners persist across multiple operations', () async {
        int callCount = 0;
        container.addListener(() => callCount++);

        for (int i = 0; i < 5; i++) {
          await container.setString('key', 'value$i');
          await Future.delayed(Duration(milliseconds: 10));
        }

        expect(callCount, greaterThanOrEqualTo(5));
      });

      test('listeners removed in clear', () async {
        int callCount = 0;
        container.addListener(() => callCount++);

        await container.clear();

        callCount = 0;
        await container.setString('key', 'value');
        await Future.delayed(Duration(milliseconds: 10));

        expect(callCount, 0);
      });

      test('listeners removed in close', () async {
        final backend2 = InMemoryBackend();
        await backend2.init();
        final container2 = HyperStorageContainer(backend: backend2, name: 'temp');

        int callCount = 0;
        container2.addListener(() => callCount++);

        await container2.close();

        // Cannot test notification after close as container is closed
        expect(container2.hasListeners, false);

        await backend2.close();
      });
    });
  });
}

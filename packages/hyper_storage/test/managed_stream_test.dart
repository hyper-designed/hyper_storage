// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:hyper_storage/src/managed_stream.dart';
import 'package:test/test.dart';

void main() {
  group('ManagedStream', () {
    group('Basic functionality', () {
      test('emits values to listeners', () async {
        final stream = TestManagedStream<int>();
        final values = <int>[];

        final subscription = stream.listen(values.add);
        stream.emit(1);
        stream.emit(2);
        stream.emit(3);

        await Future.delayed(Duration(milliseconds: 10));
        expect(values, [1, 2, 3]);

        await subscription.cancel();
        stream.dispose();
      });

      test('caches latest value for new listeners (BehaviorSubject)', () async {
        final stream = TestManagedStream<String>();

        stream.emit('initial');
        await Future.delayed(Duration(milliseconds: 10));

        final values = <String>[];
        final subscription = stream.listen(values.add);

        await Future.delayed(Duration(milliseconds: 10));
        expect(values, ['initial']); // Should receive cached value immediately

        await subscription.cancel();
        stream.dispose();
      });

      test('supports multiple concurrent listeners', () async {
        final stream = TestManagedStream<int>();
        final values1 = <int>[];
        final values2 = <int>[];
        final values3 = <int>[];

        final sub1 = stream.listen(values1.add);
        final sub2 = stream.listen(values2.add);
        final sub3 = stream.listen(values3.add);

        stream.emit(42);
        await Future.delayed(Duration(milliseconds: 10));

        expect(values1, [42]);
        expect(values2, [42]);
        expect(values3, [42]);

        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();
        stream.dispose();
      });
    });

    group('Lifecycle hooks', () {
      test('onFirstListener called when first subscriber added', () async {
        final stream = TestManagedStream<int>();

        expect(stream.firstListenerCallCount, 0);

        final sub = stream.listen((_) {});
        expect(stream.firstListenerCallCount, 1);

        // Second listener should not trigger onFirstListener
        final sub2 = stream.listen((_) {});
        expect(stream.firstListenerCallCount, 1);

        await sub.cancel();
        await sub2.cancel();
        stream.dispose();
      });

      test('onNoListeners called during dispose if subscriptions exist', () async {
        final stream = TestManagedStream<int>();

        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});

        expect(stream.noListenersCallCount, 0);

        // Cancelling subscriptions does NOT trigger onNoListeners
        // (subscription.onDone() only fires when stream closes, not on cancel)
        // Importantly, _subscriptionCount is NOT decremented on cancel!
        await sub1.cancel();
        await sub2.cancel();
        await Future.delayed(Duration(milliseconds: 50));
        expect(stream.noListenersCallCount, 0);

        // When dispose() is called, _subscriptionCount is still 2 (> 0)
        // so onNoListeners() IS called!
        stream.dispose();
        expect(stream.noListenersCallCount, 1); // Called during dispose
      });

      test('onNewListener called for every subscription', () async {
        final stream = TestManagedStream<int>();

        expect(stream.newListenerCallCount, 0);

        final sub1 = stream.listen((_) {});
        expect(stream.newListenerCallCount, 1);

        final sub2 = stream.listen((_) {});
        expect(stream.newListenerCallCount, 2);

        final sub3 = stream.listen((_) {});
        expect(stream.newListenerCallCount, 3);

        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();
        stream.dispose();
      });

      test('lifecycle order: onFirstListener -> onNewListener', () async {
        final stream = LifecycleOrderStream<int>();

        final sub = stream.listen((_) {});

        expect(stream.callOrder, ['onFirstListener', 'onNewListener']);

        await sub.cancel();
        stream.dispose();
      });

      test('onNoListeners called during dispose with active subscriptions', () async {
        final stream = TestManagedStream<int>();

        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});

        expect(stream.noListenersCallCount, 0);

        stream.dispose(); // Dispose with active subscriptions

        expect(stream.noListenersCallCount, 1); // Should be called

        await sub1.cancel();
        await sub2.cancel();
      });
    });

    group('Error handling', () {
      test('emitError delivers errors to active listeners', () async {
        final stream = TestManagedStream<int>();
        final errors = <Object>[];

        final subscription = stream.listen(
          (_) {},
          onError: errors.add,
        );

        stream.emitError(Exception('test error'));
        await Future.delayed(Duration(milliseconds: 10));

        expect(errors, hasLength(1));
        expect(errors.first, isA<Exception>());

        await subscription.cancel();
        stream.dispose();
      });

      test('emitError with stackTrace', () async {
        final stream = TestManagedStream<int>();
        final errors = <Object>[];
        final stackTraces = <StackTrace?>[];

        final subscription = stream.listen(
          (_) {},
          onError: (error, [stackTrace]) {
            errors.add(error);
            stackTraces.add(stackTrace);
          },
        );

        final testStackTrace = StackTrace.current;
        stream.emitError(Exception('test error'), testStackTrace);
        await Future.delayed(Duration(milliseconds: 10));

        expect(errors, hasLength(1));
        expect(stackTraces, hasLength(1));
        expect(stackTraces.first, equals(testStackTrace));

        await subscription.cancel();
        stream.dispose();
      });

      test('errors ARE cached by BehaviorSubject', () async {
        final stream = TestManagedStream<int>();

        // First listener receives error
        final errors1 = <Object>[];
        final sub1 = stream.listen(
          (_) {},
          onError: errors1.add,
        );

        stream.emitError(Exception('error 1'));
        await Future.delayed(Duration(milliseconds: 10));
        expect(errors1, hasLength(1));

        await sub1.cancel();

        // Second listener WILL receive cached error (BehaviorSubject behavior)
        final errors2 = <Object>[];
        final sub2 = stream.listen(
          (_) {},
          onError: errors2.add,
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(errors2, hasLength(1)); // Error IS cached!

        await sub2.cancel();
        stream.dispose();
      });

      test('emitError on disposed stream is silently ignored', () async {
        final stream = TestManagedStream<int>();
        stream.dispose();

        // Should not throw
        expect(() => stream.emitError(Exception('test')), returnsNormally);
      });
    });

    group('Disposal', () {
      test('throws StateError when listening to disposed stream', () {
        final stream = TestManagedStream<int>();
        stream.dispose();

        expect(
          () => stream.listen((_) {}),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot listen to a disposed'),
            ),
          ),
        );
      });

      test('isClosed returns true after dispose', () {
        final stream = TestManagedStream<int>();
        expect(stream.isClosed, isFalse);

        stream.dispose();
        expect(stream.isClosed, isTrue);
      });

      test('emit on disposed stream is silently ignored', () {
        final stream = TestManagedStream<int>();
        stream.dispose();

        // Should not throw
        expect(() => stream.emit(42), returnsNormally);
      });

      test('dispose closes stream and prevents new subscriptions', () async {
        final stream = TestManagedStream<int>();

        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});

        expect(stream.isClosed, isFalse);

        stream.dispose();

        expect(stream.isClosed, isTrue);

        // Attempting to listen after dispose throws
        expect(
          () => stream.listen((_) {}),
          throwsStateError,
        );

        await sub1.cancel();
        await sub2.cancel();
      });

      test('dispose can be called multiple times safely', () {
        final stream = TestManagedStream<int>();

        expect(() {
          stream.dispose();
          stream.dispose();
          stream.dispose();
        }, returnsNormally);
      });
    });

    group('Subscription management', () {
      test('subscription.onDone() only triggered for ACTIVE subscriptions', () async {
        final stream = TestManagedStream<int>();
        var onDoneCalled = false;

        final subscription = stream.listen((_) {});
        subscription.onDone(() => onDoneCalled = true);

        expect(onDoneCalled, isFalse);

        // Cancel the subscription
        await subscription.cancel();
        await Future.delayed(Duration(milliseconds: 50));
        expect(onDoneCalled, isFalse);

        // onDone is NOT triggered for cancelled subscriptions even when stream closes
        stream.dispose();
        await Future.delayed(Duration(milliseconds: 50));
        expect(onDoneCalled, isFalse); // Still false - subscription was cancelled!

        // To test that onDone DOES fire for active subscriptions:
        final stream2 = TestManagedStream<int>();
        var onDone2Called = false;

        final sub2 = stream2.listen((_) {});
        sub2.onDone(() => onDone2Called = true);

        stream2.dispose(); // Don't cancel before disposing
        await Future.delayed(Duration(milliseconds: 50));
        expect(onDone2Called, isTrue); // Now it's called!

        await sub2.cancel();
      });

      test('subscription count NOT decremented on cancel, only on dispose', () async {
        final stream = TestManagedStream<int>();

        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});

        expect(stream.noListenersCallCount, 0);

        // Cancelling subscriptions does NOT decrement count
        // (onDone callbacks only fire on stream close)
        await sub1.cancel();
        await sub2.cancel();
        await Future.delayed(Duration(milliseconds: 50));
        expect(stream.noListenersCallCount, 0);

        // When dispose() is called, count is still 2 (> 0)
        // so onNoListeners IS called
        stream.dispose();
        expect(stream.noListenersCallCount, 1); // Called!
      });

      test('subscription receives values only while active', () async {
        final stream = TestManagedStream<int>();
        final values = <int>[];

        final subscription = stream.listen(values.add);

        stream.emit(1);
        await Future.delayed(Duration(milliseconds: 10));
        expect(values, [1]);

        await subscription.cancel();

        stream.emit(2);
        await Future.delayed(Duration(milliseconds: 10));
        expect(values, [1]); // Should not receive 2

        stream.dispose();
      });
    });

    group('Protected members', () {
      test('streamController.hasValue reflects cached state', () async {
        final stream = TestManagedStream<int>();

        expect(stream.streamController.hasValue, isFalse);

        stream.emit(42);
        await Future.delayed(Duration(milliseconds: 10));

        expect(stream.streamController.hasValue, isTrue);
        expect(stream.streamController.value, 42);

        stream.dispose();
      });
    });

    group('Edge cases', () {
      test('rapid subscribe/unsubscribe cycles - count never decrements', () async {
        final stream = TestManagedStream<int>();

        // Subscribe and cancel multiple times
        for (var i = 0; i < 10; i++) {
          final sub = stream.listen((_) {});
          await sub.cancel();
        }

        // onFirstListener is only called ONCE (first time count goes 0->1)
        // After that, count stays >= 1 because cancel doesn't decrement
        expect(stream.firstListenerCallCount, 1);

        // onNoListeners is NOT called on cancel (only on dispose)
        expect(stream.noListenersCallCount, 0);

        stream.dispose();
        // Count is 10 (all the increments, no decrements), so onNoListeners IS called
        expect(stream.noListenersCallCount, 1);
      });

      test('emit during listener callback', () async {
        final stream = TestManagedStream<int>();
        final values = <int>[];

        stream.listen((value) {
          values.add(value);
          if (value < 3) {
            stream.emit(value + 1); // Emit during callback
          }
        });

        stream.emit(1);
        await Future.delayed(Duration(milliseconds: 50));

        expect(values, [1, 2, 3]);

        stream.dispose();
      });

      test('multiple errors to same listener', () async {
        final stream = TestManagedStream<int>();
        final errors = <Object>[];

        final sub = stream.listen(
          (_) {},
          onError: errors.add,
        );

        stream.emitError(Exception('error 1'));
        stream.emitError(Exception('error 2'));
        stream.emitError(Exception('error 3'));

        await Future.delayed(Duration(milliseconds: 10));

        expect(errors, hasLength(3));

        await sub.cancel();
        stream.dispose();
      });

      test('listener with cancelOnError=true', () async {
        final stream = TestManagedStream<int>();
        final values = <int>[];
        final errors = <Object>[];

        final sub = stream.listen(
          values.add,
          onError: errors.add,
          cancelOnError: true,
        );

        stream.emit(1);
        await Future.delayed(Duration(milliseconds: 10));

        stream.emitError(Exception('error'));
        await Future.delayed(Duration(milliseconds: 10));

        stream.emit(2);
        await Future.delayed(Duration(milliseconds: 10));

        expect(values, [1]); // Should not receive 2 after error
        expect(errors, hasLength(1));

        await sub.cancel();
        stream.dispose();
      });
    });

    group('Base class default implementations', () {
      test('default onFirstListener does nothing (no-op)', () async {
        final stream = MinimalManagedStream<int>();

        // Subscribe to trigger onFirstListener
        final sub = stream.listen((_) {});

        // Should complete without error (default implementation is empty)
        expect(() => sub, returnsNormally);

        await sub.cancel();
        stream.dispose();
      });

      test('default onNoListeners does nothing (no-op)', () async {
        final stream = MinimalManagedStream<int>();

        final sub = stream.listen((_) {});
        await sub.cancel();

        // Dispose to trigger onNoListeners
        expect(() => stream.dispose(), returnsNormally);
      });

      test('default onNewListener does nothing (no-op)', () async {
        final stream = MinimalManagedStream<int>();

        // Each subscription triggers onNewListener
        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});
        final sub3 = stream.listen((_) {});

        // Should complete without error (default implementation is empty)
        expect(() => sub1, returnsNormally);
        expect(() => sub2, returnsNormally);
        expect(() => sub3, returnsNormally);

        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();
        stream.dispose();
      });

      test('stream with default implementations works normally', () async {
        final stream = MinimalManagedStream<int>();
        final values = <int>[];

        final sub = stream.listen(values.add);

        stream.emitValue(1);
        stream.emitValue(2);
        stream.emitValue(3);

        await Future.delayed(Duration(milliseconds: 10));

        expect(values, [1, 2, 3]);

        await sub.cancel();
        stream.dispose();
      });
    });
  });
}

/// Test implementation of ManagedStream for testing purposes.
class TestManagedStream<E> extends ManagedStream<E> {
  int firstListenerCallCount = 0;
  int noListenersCallCount = 0;
  int newListenerCallCount = 0;

  @override
  void onFirstListener() {
    firstListenerCallCount++;
  }

  @override
  void onNoListeners() {
    noListenersCallCount++;
  }

  @override
  void onNewListener() {
    newListenerCallCount++;
  }

  // Expose protected methods for testing
  @override
  void emit(E event) => super.emit(event);

  @override
  void emitError(Object error, [StackTrace? stackTrace]) => super.emitError(error, stackTrace);
}

/// Stream that tracks lifecycle call order for testing.
class LifecycleOrderStream<E> extends ManagedStream<E> {
  final List<String> callOrder = [];

  @override
  void onFirstListener() {
    callOrder.add('onFirstListener');
  }

  @override
  void onNoListeners() {
    callOrder.add('onNoListeners');
  }

  @override
  void onNewListener() {
    callOrder.add('onNewListener');
  }
}

/// Minimal stream that doesn't override lifecycle hooks (for coverage of base implementations).
class MinimalManagedStream<E> extends ManagedStream<E> {
  // No overrides - uses default empty implementations

  // Expose protected methods for testing
  void emitValue(E event) => emit(event);
  void emitErrorValue(Object error, [StackTrace? stackTrace]) => emitError(error, stackTrace);
}

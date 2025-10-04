import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

void main() {
  group('ItemHolderExtensions', () {
    late HyperStorage storage;
    late ItemHolder<String> holder;

    setUp(() async {
      storage = await HyperStorage.newInstance(backend: InMemoryBackend());
      holder = storage.itemHolder<String>('test_key');
    });

    tearDown(() async {
      await storage.close();
    });

    test('asValueNotifier creates ValueNotifier with initial null value', () {
      final notifier = holder.asValueNotifier();
      expect(notifier, isA<ValueNotifier<String?>>());
      notifier.dispose();
    });

    test('asValueNotifier updates when item changes', () async {
      final notifier = holder.asValueNotifier();

      // Wait for initial async fetch
      await Future.delayed(Duration.zero);
      expect(notifier.value, isNull);

      // Set value and wait for async update
      await holder.set('test_value');
      await Future.delayed(Duration.zero);

      expect(notifier.value, 'test_value');

      notifier.dispose();
    });

    test('asValueNotifier updates multiple times', () async {
      final notifier = holder.asValueNotifier();
      final values = <String?>[];

      notifier.addListener(() {
        values.add(notifier.value);
      });

      await holder.set('value1');
      await Future.delayed(Duration.zero);

      await holder.set('value2');
      await Future.delayed(Duration.zero);

      await holder.set('value3');
      await Future.delayed(Duration.zero);

      expect(values, contains('value1'));
      expect(values, contains('value2'));
      expect(values, contains('value3'));

      notifier.dispose();
    });

    test('dispose removes listener from holder', () async {
      final notifier = holder.asValueNotifier();

      // Set initial value
      await holder.set('initial');
      await Future.delayed(Duration.zero);
      expect(notifier.value, 'initial');

      // Dispose notifier
      notifier.dispose();

      // Change value after dispose
      await holder.set('after_dispose');
      await Future.delayed(Duration.zero);

      // Value should not update after dispose
      expect(notifier.value, 'initial');
    });

    test('multiple notifiers work independently', () async {
      final notifier1 = holder.asValueNotifier();
      final notifier2 = holder.asValueNotifier();

      await holder.set('shared_value');
      await Future.delayed(Duration.zero);

      expect(notifier1.value, 'shared_value');
      expect(notifier2.value, 'shared_value');

      notifier1.dispose();
      notifier2.dispose();
    });
  });

  group('HyperStorageExt', () {
    late HyperStorage storage;

    setUp(() async {
      storage = await HyperStorage.newInstance(backend: InMemoryBackend());
    });

    tearDown(() async {
      await storage.close();
    });

    test('stream emits initial value', () async {
      await storage.set('key1', 'initial_value');

      final stream = storage.stream<String>('key1');
      final firstValue = await stream.first;

      expect(firstValue, 'initial_value');
    });

    test('stream emits null for non-existent key', () async {
      final stream = storage.stream<String>('non_existent');
      final firstValue = await stream.first;

      expect(firstValue, isNull);
    });

    test('stream emits updates when value changes', () async {
      await storage.set('key1', 'value1');

      final stream = storage.stream<String>('key1');
      final values = <String?>[];

      final subscription = stream.listen(values.add);

      // Wait for initial value
      await Future.delayed(Duration(milliseconds: 10));

      // Update value
      await storage.set('key1', 'value2');
      await Future.delayed(Duration(milliseconds: 10));

      await storage.set('key1', 'value3');
      await Future.delayed(Duration(milliseconds: 10));

      await subscription.cancel();

      expect(values, contains('value1'));
      expect(values, contains('value2'));
      expect(values, contains('value3'));
    });

    test('stream handles multiple listeners', () async {
      await storage.set('key1', 'initial');

      final stream1 = storage.stream<String>('key1');
      final stream2 = storage.stream<String>('key1');

      final values1 = <String?>[];
      final values2 = <String?>[];

      final sub1 = stream1.listen(values1.add);
      final sub2 = stream2.listen(values2.add);

      await Future.delayed(Duration(milliseconds: 10));

      await storage.set('key1', 'updated');
      await Future.delayed(Duration(milliseconds: 10));

      await sub1.cancel();
      await sub2.cancel();

      expect(values1, contains('initial'));
      expect(values1, contains('updated'));
      expect(values2, contains('initial'));
      expect(values2, contains('updated'));
    });

    test('stream stops emitting after cancellation', () async {
      await storage.set('key1', 'value1');

      final stream = storage.stream<String>('key1');
      final values = <String?>[];

      final subscription = stream.listen(values.add);
      await Future.delayed(Duration(milliseconds: 10));

      // Cancel subscription
      await subscription.cancel();

      // Update value after cancellation
      await storage.set('key1', 'value2');
      await Future.delayed(Duration(milliseconds: 10));

      // Should only contain initial value, not the update after cancellation
      expect(values.length, 1);
      expect(values, ['value1']);
    });

    test('stream works with different types', () async {
      await storage.set('int_key', 42);
      await storage.set('bool_key', true);
      await storage.set('double_key', 3.14);

      final intStream = storage.stream<int>('int_key');
      final boolStream = storage.stream<bool>('bool_key');
      final doubleStream = storage.stream<double>('double_key');

      expect(await intStream.first, 42);
      expect(await boolStream.first, true);
      expect(await doubleStream.first, 3.14);
    });
  });

  group('Memory Leak Prevention', () {
    late HyperStorage storage;

    setUp(() async {
      storage = await HyperStorage.newInstance(backend: InMemoryBackend());
    });

    tearDown(() async {
      await storage.close();
    });

    test('ValueNotifier properly removes listener on dispose', () async {
      final holder = storage.itemHolder<String>('test_key');
      final notifier = holder.asValueNotifier();

      await holder.set('value1');
      await Future.delayed(Duration.zero);

      // Before dispose, notifier should update
      expect(notifier.value, 'value1');

      notifier.dispose();

      // After dispose, notifier should not update
      await holder.set('value2');
      await Future.delayed(Duration.zero);
      expect(notifier.value, 'value1'); // Should still be old value
    });

    test('Stream properly removes listener on cancellation', () async {
      await storage.set('key1', 'value1');

      final stream = storage.stream<String>('key1');
      final values = <String?>[];

      final subscription = stream.listen(values.add);
      await Future.delayed(Duration(milliseconds: 10));

      await subscription.cancel();

      // After cancellation, no more values should be added
      final beforeCount = values.length;

      await storage.set('key1', 'value2');
      await storage.set('key1', 'value3');
      await Future.delayed(Duration(milliseconds: 10));

      expect(values.length, beforeCount);
    });
  });
}

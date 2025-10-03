import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:hyper_storage/hyper_storage.dart';

/// Extensions for [ItemHolder] to convert it into a [ValueNotifier].
extension ItemHolderExtensions<E extends Object> on ItemHolder<E> {
  /// Converts the [ItemHolder] into a [ValueNotifier].
  /// The [ValueNotifier] will update its value whenever the [ItemHolder] notifies
  /// its listeners.
  ///
  /// It is important to dispose of the returned [ValueNotifier] when it is no longer needed.
  /// This can be done by calling the [dispose] method on the [ValueNotifier].
  ValueNotifier<E?> asValueNotifier() => _ItemNotifier(this);
}

/// Extensions for [HyperStorage] to provide a stream of values for a given key.
extension HyperStorageExt on HyperStorage {
  /// Provides a [Stream] of values for the given [key].
  /// The stream will emit the current value of the key and will update
  /// whenever the value changes.
  ///
  /// It is important to close the stream when it is no longer needed
  /// to avoid memory leaks.
  ///
  /// This can be done by cancelling the subscription to the stream.
  Stream<E?> stream<E>(String key) async* {
    final E? itemValue = await get(key);
    yield itemValue;
    final controller = StreamController<E?>();

    void retrieveAndAdd() async {
      if (controller.isClosed) {
        removeListener(retrieveAndAdd);
        return;
      }
      final E? value = await get(key);
      controller.add(value);
    }

    addListener(retrieveAndAdd);

    yield* controller.stream;
  }
}

/// Extensions for [HyperStorageContainer] to provide a stream of values for a given key.
/// This is similar to the [HyperStorageExt] but scoped to a specific container.
extension HyperStorageContainerExt on HyperStorage {
  /// Provides a [Stream] of values for the given [key] in the container.
  /// The stream will emit the current value of the key and will update
  /// whenever the value changes.
  ///
  /// It is important to close the stream when it is no longer needed
  /// to avoid memory leaks.
  ///
  /// This can be done by cancelling the subscription to the stream.
  Stream<E?> stream<E>(String key) async* {
    final E? itemValue = await get(key);
    yield itemValue;
    final controller = StreamController<E?>();

    void retrieveAndAdd() async {
      if (controller.isClosed) {
        removeListener(retrieveAndAdd);
        return;
      }
      final E? value = await get(key);
      controller.add(value);
    }

    addListener(retrieveAndAdd);

    yield* controller.stream;
  }
}

/// A [ValueNotifier] that listens to an [ItemHolder] and updates its value accordingly.
/// It retrieves the current value from the [ItemHolder] when created and whenever
/// the [ItemHolder] notifies its listeners.
/// It is important to dispose of this notifier when it is no longer needed to avoid memory leaks.
class _ItemNotifier<E extends Object> extends ValueNotifier<E?> {
  final ItemHolder<E> holder;

  _ItemNotifier(this.holder) : super(null) {
    void retrieveAndSet() async {
      final itemValue = await holder.get();
      value = itemValue;
    }

    retrieveAndSet();
    holder.addListener(retrieveAndSet);
  }

  @override
  void dispose() {
    holder.removeListener(() {});
    super.dispose();
  }
}

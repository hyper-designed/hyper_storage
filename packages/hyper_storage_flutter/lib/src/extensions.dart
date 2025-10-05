// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

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
  Stream<E?> stream<E extends Object>(String key) async* {
    final E? itemValue = await get<E>(key);
    yield itemValue;

    late final void Function() retrieveAndAdd;
    final controller = StreamController<E?>(
      onCancel: () => removeListener(retrieveAndAdd),
    );

    retrieveAndAdd = () async {
      if (controller.isClosed) return;
      final E? value = await get<E>(key);
      if (!controller.isClosed) {
        controller.add(value);
      }
    };

    addListener(retrieveAndAdd);

    yield* controller.stream;
    await controller.close();
  }
}

/// A [ValueNotifier] that listens to an [ItemHolder] and updates its value accordingly.
/// It retrieves the current value from the [ItemHolder] when created and whenever
/// the [ItemHolder] notifies its listeners.
/// It is important to dispose of this notifier when it is no longer needed to avoid memory leaks.
class _ItemNotifier<E extends Object> extends ValueNotifier<E?> {
  final ItemHolder<E> holder;
  late final void Function() _listener;

  _ItemNotifier(this.holder) : super(null) {
    void retrieveAndSet() async {
      final itemValue = await holder.get();
      value = itemValue;
    }

    _listener = retrieveAndSet;
    retrieveAndSet();
    holder.addListener(_listener);
  }

  @override
  void dispose() {
    holder.removeListener(_listener);
    super.dispose();
  }
}

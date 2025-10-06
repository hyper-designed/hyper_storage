// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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

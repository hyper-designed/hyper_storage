# Hyper Storage Flutter Examples

This file provides examples of how to use the `hyper_storage_flutter` package to build reactive user interfaces in
Flutter.

## Listening to a Single Key

There are multiple ways to listen to a single key in your storage.

- Using `ItemHolder`: ItemHolder is listenable and can be streamed too.
- Using `ItemHolder.asValueNotifier`: This is a convenient way to get a `ValueNotifier` for a specific key.
- Using `storage.stream<E>(key)`: This provides a stream of changes for a specific key.

You can use `asValueNotifier` on an `ItemHolder` to obtain a `ValueNotifier` for a specific key. This allows you to
rebuild your UI automatically whenever the value of that key changes.

### Using `ItemHolder` as `ValueNotifier`.

> Note: `ItemHolder.asValueNotifier` must be called outside of the `build` method, typically in `initState` as it will
> create a new `ValueNotifier` each time it is called.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

class CounterScreen extends StatefulWidget {
  final HyperStorage storage;

  const CounterScreen({super.key, required this.storage});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late final ItemHolder<int> _counterHolder;
  late final ValueNotifier<int?> _counterNotifier;

  @override
  void initState() {
    super.initState();
    _counterHolder = widget.storage.itemHolder<int>('counter');
    _counterNotifier = _counterHolder.asValueNotifier();
  }

  @override
  void dispose() {
    _counterNotifier.dispose();
    _counterHolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int?>(
          valueListenable: _counterNotifier,
          builder: (context, counter, child) {
            return Text('Counter: ${counter ?? 0}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentCounter = await _counterHolder.get() ?? 0;
          await _counterHolder.set(currentCounter + 1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Using `ItemHolder` with `StreamBuilder`.

> Note: It is safe to reuse the same `ItemHolder` instance multiple times without disposing it, as it manages its own
> resources. Calling `itemHolder` multiple times with the same key will return the same instance.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

class CounterScreen extends StatefulWidget {
  final HyperStorage storage;

  const CounterScreen({super.key, required this.storage});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late final ItemHolder<int> _counterHolder = widget.storage.itemHolder<int>('counter');

  @override
  void dispose() {
    _counterHolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<int?>(
          stream: _counterHolder,
          builder: (context, snapshot) {
            return Text('Counter: ${snapshot.data ?? 0}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentCounter = await _counterHolder.get() ?? 0;
          await _counterHolder.set(currentCounter + 1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Using streams with `StreamBuilder`.

> Note: `storage.stream<E>(key)` is safe to call inside the `build` method as it manages the stream internally.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

class CounterScreen extends StatefulWidget {
  final HyperStorage storage;

  const CounterScreen({super.key, required this.storage});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<int?>(
          stream: widget.storage.stream<int>('counter'),
          builder: (context, snapshot) {
            return Text('Counter: ${snapshot.data ?? 0}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentCounter = await widget.storage.getInt('counter') ?? 0;
          await widget.storage.setInt('counter', currentCounter + 1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

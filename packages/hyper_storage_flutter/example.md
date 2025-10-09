# Hyper Storage Flutter Examples

This file provides examples of how to use the `hyper_storage_flutter` package to build reactive user interfaces in Flutter.

## Contents

-   [Listening to a Single Key](#listening-to-a-single-key)
-   [Listening with a Default Value](#listening-with-a-default-value)
-   [Using with Containers](#using-with-containers)

## Listening to a Single Key

You can use `asValueNotifier` on an `ItemHolder` to obtain a `ValueNotifier` for a specific key. This allows you to rebuild your UI automatically whenever the value of that key changes.

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

## Listening with a Default Value

You can provide your own default value when rendering the UI. For example:

```dart
ValueListenableBuilder<int?>(
  valueListenable: _counterNotifier,
  builder: (context, counter, child) {
    return Text('Counter: ${counter ?? 0}');
  },
);
```

## Using with Containers

You can call `asValueNotifier` on item holders that originate from containers as well.

```dart
final profile = await storage.container('profile');
final nameHolder = profile.itemHolder<String>('name');
final nameNotifier = nameHolder.asValueNotifier();

ValueListenableBuilder<String?>(
  valueListenable: nameNotifier,
  builder: (context, name, child) {
    return Text('Current Name: ${name ?? 'Not set'}');
  },
);
```

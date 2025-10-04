# Hyper Storage Flutter Examples

This file provides examples of how to use the `hyper_storage_flutter` package to build reactive user interfaces in Flutter.

## Contents

-   [Listening to a Single Key](#listening-to-a-single-key)
-   [Listening with a Default Value](#listening-with-a-default-value)
-   [Using with Containers](#using-with-containers)

## Listening to a Single Key

You can use the `listenable` extension method on a `HyperStorage` or `HyperStorageContainer` instance to get a `ValueListenable` for a specific key. This allows you to rebuild your UI automatically whenever the value of that key changes.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

class CounterScreen extends StatelessWidget {
  final HyperStorage storage;

  const CounterScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int?>(
          valueListenable: storage.listenable('counter'),
          builder: (context, counter, child) {
            return Text('Counter: ${counter ?? 0}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentCounter = await storage.getInt('counter') ?? 0;
          await storage.setInt('counter', currentCounter + 1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Listening with a Default Value

The `listenable` method takes an optional `defaultValue` parameter. If you provide a `defaultValue`, the `ValueListenable` will emit this value initially if the key does not exist in the storage.

```dart
ValueListenableBuilder<int>(
  valueListenable: storage.listenable('counter', defaultValue: 0),
  builder: (context, counter, child) {
    return Text('Counter: $counter');
  },
),
```

## Using with Containers

The `listenable` extension method is also available on `HyperStorageContainer` instances.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final HyperStorageContainer profileContainer;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    profileContainer = await HyperStorage.container('profile');
    final currentName = await profileContainer.getString('name');
    if (currentName != null) {
      _controller.text = currentName;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: profileContainer.listenable('name'),
              builder: (context, name, child) {
                return Text('Current Name: ${name ?? 'Not set'}');
              },
            ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'New Name'),
            ),
            ElevatedButton(
              onPressed: () async {
                await profileContainer.setString('name', _controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
```

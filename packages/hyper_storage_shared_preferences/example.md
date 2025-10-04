# Hyper Storage SharedPreferences Examples

This file provides examples of how to use the `hyper_storage_shared_preferences` package with `hyper_storage` in a Flutter application.

## Contents

-   [Initialization](#initialization)
-   [Usage with HyperStorage](#usage-with-hyperstorage)

## Initialization

To use the `shared_preferences` backend, you need to initialize `hyper_storage` with `SharedPreferencesBackend`.

Make sure to call `WidgetsFlutterBinding.ensureInitialized()` before initializing the storage.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_shared_preferences/shared_preferences_backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage with SharedPreferencesBackend
  final storage = await HyperStorage.init(backend: SharedPreferencesBackend());

  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final HyperStorage storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<String?>(
            future: storage.get('message'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(snapshot.data ?? 'No message yet');
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await storage.set('message', 'Hello from SharedPreferences!');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## Usage with HyperStorage

Once initialized, you can use all the features of `hyper_storage` as you normally would. The backend will take care of persisting the data using `shared_preferences`.

### Storing Different Data Types

```dart
await storage.setInt('counter', 10);
await storage.setDouble('rating', 4.5);
await storage.setBool('isFirstTime', false);
await storage.setStringList('reminders', ['Buy milk', 'Walk the dog']);
```

### Retrieving Data

```dart
final counter = await storage.getInt('counter');
final rating = await storage.getDouble('rating');
final isFirstTime = await storage.getBool('isFirstTime');
final reminders = await storage.getStringList('reminders');
```

### Using Containers

You can also use named containers to organize your data.

```dart
final profileSettings = await HyperStorage.container('profile');
await profileSettings.set('username', 'jane_doe');
final username = await profileSettings.get('username');
```

# Hyper Storage Hive Examples

This file provides examples of how to use the `hyper_storage_hive` package with `hyper_storage`.

## Contents

-   [Initialization](#initialization)
-   [Lazy Initialization](#lazy-initialization)
-   [Usage with HyperStorage](#usage-with-hyperstorage)

## Initialization

To use the Hive backend, you need to initialize `hyper_storage` with `HiveBackend`.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  // Initialize the storage with HiveBackend
  final storage = await HyperStorage.init(backend: HiveBackend());

  // Use the storage
  await storage.set('message', 'Hello from Hive!');
  final message = await storage.get('message');
  print(message);

  await storage.close();
}
```

By default, `HiveBackend` will store data in a directory provided by `path_provider`. You can also provide a custom path.

```dart
final backend = HiveBackend(path: '/path/to/your/storage');
final storage = await HyperStorage.init(backend: backend);
```

## Lazy Initialization

The `hyper_storage_hive` package also provides a `LazyHiveBackend` that only loads data from the disk when it is requested. This can be useful for reducing memory usage, especially if you have a large amount of data.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  // Initialize the storage with LazyHiveBackend
  final storage = await HyperStorage.init(backend: LazyHiveBackend());

  // Use the storage
  await storage.set('message', 'Hello from Lazy Hive!');
  final message = await storage.get('message');
  print(message);

  await storage.close();
}
```

## Usage with HyperStorage

Once initialized, you can use all the features of `hyper_storage` as you normally would. The backend will take care of persisting the data.

### Storing Different Data Types

```dart
await storage.setInt('age', 30);
await storage.setDouble('pi', 3.14);
await storage.setBool('isReady', true);
await storage.setStringList('tags', ['flutter', 'dart', 'hive']);
await storage.setJson('user', {'name': 'John Doe', 'age': 30});
```

### Retrieving Data

```dart
final age = await storage.getInt('age');
final pi = await storage.getDouble('pi');
final isReady = await storage.getBool('isReady');
final tags = await storage.getStringList('tags');
final user = await storage.getJson('user');
```

### Using Containers

```dart
final userSettings = await HyperStorage.container('user_settings');
await userSettings.set('theme', 'dark');
final theme = await userSettings.get('theme');
```

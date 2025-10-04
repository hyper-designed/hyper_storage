# Hyper Storage Examples

This file provides a collection of examples demonstrating how to use the `hyper_storage` package.

## Contents

-   [Initialization](#initialization)
-   [Basic Operations](#basic-operations)
-   [Typed Data](#typed-data)
-   [JSON Data](#json-data)
-   [Named Containers](#named-containers)
-   [Object Containers](#object-containers)
-   [Checking for Keys](#checking-for-keys)
-   [Closing the Storage](#closing-the-storage)
-   [Mocking for Tests](#mocking-for-tests)

## Initialization

You can initialize `hyper_storage` with a specific backend. If no backend is provided, it defaults to `InMemoryBackend`.

### Default (In-Memory)

```dart
import 'package:hyper_storage/hyper_storage.dart';

final storage = await HyperStorage.init();
```

### Using Other Backends

To use other backends, you need to add the respective package to your `pubspec.yaml` and then provide the backend instance to the `init` method.

For example, to use the Hive backend:

```dart
// Make sure to add hyper_storage_hive to your dependencies
import 'package:hyper_storage_hive/hyper_storage_hive.dart';
import 'package:hyper_storage/hyper_storage.dart';

final storage = await HyperStorage.init(backend: HiveBackend());
```

## Basic Operations

You can use the `set` and `get` methods to store and retrieve data.

```dart
// Set a value
await storage.set('name', 'Hyper Storage');

// Get a value
final name = await storage.get('name');
print(name); // Output: Hyper Storage
```

## Typed Data

`hyper_storage` provides typed methods to store and retrieve data with type safety.

### Storing Data

```dart
await storage.setString('name', 'John');
await storage.setInt('age', 30);
await storage.setBool('isDeveloper', true);
await storage.setDouble('height', 1.75);
await storage.setStringList('skills', ['Dart', 'Flutter', 'JavaScript']);
```

### Getting Data

```dart
final String? name = await storage.getString('name');
final int? age = await storage.getInt('age');
final bool? isDeveloper = await storage.getBool('isDeveloper');
final double? height = await storage.getDouble('height');
final List<String>? skills = await storage.getStringList('skills');
```

## JSON Data

You can store and retrieve JSON data (`Map<String, dynamic>`) and lists of JSON data (`List<Map<String, dynamic>>`).

### Storing JSON

```dart
await storage.setJson('profile', {
    'name': 'John Doe',
    'age': 30,
    'isDeveloper': true,
    'height': 1.75,
    'skills': ['Dart', 'Flutter', 'JavaScript'],
});

await storage.setJsonList('items', [
    {'id': 1, 'name': 'Item 1'},
    {'id': 2, 'name': 'Item 2'},
    {'id': 3, 'name': 'Item 3'},
]);
```

### Getting JSON

```dart
final Map<String, dynamic>? profile = await storage.getJson('profile');
final List<Map<String, dynamic>>? items = await storage.getJsonList('items');
```

## Named Containers

You can use named containers to organize your data.

```dart
final container = await HyperStorage.container('account');
await container.setString('username', 'john_doe');
final String? username = await container.getString('username');
```

## Object Containers

You can store and retrieve custom objects by providing `toJson` and `fromJson` functions.

```dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'], age: json['age']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }
}

final storage = await HyperStorage.objectContainer<User>(
  'users',
  toJson: (user) => user.toJson(),
  fromJson: User.fromJson,
);

await storage.set('user1', User(name: 'John', age: 23));
final User? user = await storage.get('user1');
final List<User> users = await storage.getValues();
final Map<String, User> allUsers = await storage.getAll();
```

## Checking for Keys

You can check if a key exists in the storage.

```dart
final bool containsName = await storage.containsKey('name');
```

## Closing the Storage

It's important to close the storage when it's no longer needed to release resources.

```dart
await storage.close(); // closes all containers.
```

## Mocking for Tests

For testing, you can use a mocked version of the storage.

```dart
final storage = await HyperStorage.initMocked();
```

You can also provide initial data to the mocked storage.

```dart
final storage = await HyperStorage.initMocked(initialData: {
  'name': 'Test',
  'age': 25,
});
```

<h1 align="center">hyper_storage</h1>

<p align="center">
  <a href="https://pub.dev/packages/hyper_storage">
    <img src="https://img.shields.io/pub/v/hyper_storage?label=pub.dev&labelColor=333940&logo=dart&color=00589B">
  </a>
  <a href="https://github.com/hyper-designed/hyper_storage/actions/workflows/test.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/hyper-designed/hyper_storage/test.yml?branch=main&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://app.codecov.io/gh/hyper-designed/hyper_storage">
    <img src="https://img.shields.io/codecov/c/github/hyper-designed/hyper_storage?logo=codecov&logoColor=fff&labelColor=333940">
  </a>
  <br/>
  <a href="https://twitter.com/birjuvachhani">
    <img src="https://img.shields.io/badge/follow-%40birjuvachhani-1DA1F2?style=flat&label=follow&color=1DA1F2&labelColor=333940&logo=twitter&logoColor=fff">
  </a>
    <a href="https://twitter.com/saadardati">
    <img src="https://img.shields.io/badge/follow-%40saadardati-F0A1F2?style=flat&label=follow&color=0F77dd&labelColor=333940&logo=twitter&logoColor=fff">
  </a>
  <a href="https://github.com/hyper-designed/hyper_storage">
    <img src="https://img.shields.io/github/stars/hyper-designed/hyper_storage?style=flat&label=stars&labelColor=333940&color=8957e5&logo=github">
  </a>
</p>

<p align="center">
  <a href="#getting-started">Quickstart</a> •
  <a href="https://pub.dev/documentation/hyper_storage/latest/topics/Introduction-topic.html">Documentation</a> •
  <a href="https://pub.dev/packages/hyper_storage/example">Example</a>
</p>

<p align="center">
    <b>Hyper Storage</b>unifies local <b>key-value</b> storage in Flutter with a single, consistent API. 
Switch between <b><a href="https://pub.dev/packages/shared_preferences">shared_preferences</a></b>, <b><a href="https://pub.dev/packages/hive_ce">hive_ce</a></b>, <b><a href="https://pub.dev/packages/flutter_secure_storage">flutter_secure_storage</a></b> or any custom backend without changing a single line of app logic.
</p>

---

## Features

- ✅ **Simple API:** Easy to use API for storing and retrieving data.
- ✅ **Multiple Backends:** Supports different backends like `InMemory`, `hive`, `shared_preferences`, and `flutter_secure_storage` (via separate packages).
- ✅ **Typed Storage:** Store and retrieve data with type safety.
- ✅ **JSON Serialization:** Store and retrieve custom objects by providing `toJson` and `fromJson` functions.
- ✅ **Named Containers:** Organize your data into named containers for better structure.
- ✅ **Custom Serializable Objects Support:** Easily store and retrieve custom objects by providing serialization functions.
- ✅ **Reactivity:** Listen to changes in the storage and react accordingly.
- ✅ **Asynchronous:** All operations are asynchronous, making it suitable for Flutter applications.
- ✅ **Cross-Platform:** Works on mobile, web, and desktop platforms.
- ✅ **Fully Tested:** Comprehensive test coverage to ensure reliability.
- ✅ **Mockable:** Easy to mock for testing purposes.

## Getting started

Add `hyper_storage` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  hyper_storage: ^0.1.0 # Replace with the latest version

  hyper_storage_flutter: ^0.1.0 # Add this if you're using Flutter.

  # Add one of the available backends of your choice:
  hyper_storage_hive: ^0.1.0
  hyper_storage_shared_preferences: ^0.1.0
  hyper_storage_secure: ^0.1.0
```

Then, run `flutter pub get` or `dart pub get`.

## Usage

Initialize the storage with a backend of your choice.

```dart
import 'package:hyper_storage/hyper_storage.dart';

void main() async {
  // Initialize the storage with InMemoryBackend
  final storage = await HyperStorage.init(backend: SharedPreferencesBackend());

  // Set a value
  await storage.setString('name', 'Hyper Storage');

  // Get a value
  final name = await storage.getString('name');
  print(name); // Output: Hyper Storage

  // Close the storage
  await storage.close();
}
```

For more detailed examples, please see the [example.md](example.md) file.

## Available Backends

-   `InMemoryBackend`: A simple in-memory backend for temporary storage.

More backends are available in separate packages:

-   [hyper_storage_hive](https://pub.dev/packages/hyper_storage_hive): Hive backend for persistent storage.
-   [hyper_storage_shared_preferences](https://pub.dev/packages/hyper_storage_shared_preferences): SharedPreferences backend for persistent storage.
-   [hyper_storage_secure](https://pub.dev/packages/hyper_storage_secure): Secure storage backend for sensitive data.

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

final storage = await HyperStorage.init(backend: InMemoryBackend());
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

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.
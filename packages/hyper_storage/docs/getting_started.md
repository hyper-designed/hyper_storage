# Table of Contents

- [Installation](#installation)
- [Available Backends](#available-backends)
- [Usage](#usage)
- [Basic Operations](#basic-operations)
- [Typed Data](#typed-data)
- [JSON Data](#json-data)
- [Named Containers](#named-containers)
- [Object Containers](#object-containers)
- [Checking for Keys](#checking-for-keys)
- [Closing the Storage](#closing-the-storage)
- [Mocking for Tests](#mocking-for-tests)

## Installation

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

## Available Backends

-   `InMemoryBackend`: A simple in-memory backend for temporary storage.

More backends are available in separate packages:

-   [hyper_storage_hive](https://pub.dev/packages/hyper_storage_hive): Hive backend for persistent storage.
-   [hyper_storage_shared_preferences](https://pub.dev/packages/hyper_storage_shared_preferences): SharedPreferences backend for persistent storage.
-   [hyper_storage_secure](https://pub.dev/packages/hyper_storage_secure): Secure storage backend for sensitive data.

See the [Backends Documentation](backends.md) for more details.

## Initialization

You can initialize `hyper_storage` with any storage backend that implements the `StorageBackend` interface. Always pass
the backend you want to use to `HyperStorage.init`.

### In-memory (for tests or ephemeral data)

```dart
import 'package:hyper_storage/hyper_storage.dart';

final storage = await HyperStorage.init(backend: InMemoryBackend());
```

### Using other backends

Add the desired backend package to your dependencies and provide the backend instance to `init`:

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

final storage = await HyperStorage.init(backend: HiveBackend());
```

## Usage

Initialize the storage with a backend of your choice.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_shared_preferences/shared_preferences_backend.dart';

void main() async {
  // Initialize the storage with SharedPreferences
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
await storage.setBytes('data', Uint8List.fromList([1, 2, 3, 4, 5]));
```

### Getting Data

```dart
final String? name = await storage.getString('name');
final int? age = await storage.getInt('age');
final bool? isDeveloper = await storage.getBool('isDeveloper');
final double? height = await storage.getDouble('height');
final List<String>? skills = await storage.getStringList('skills');
final Uint8List? data = await storage.getBytes('data');
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
final container = await storage.container('account');
await container.setString('username', 'john_doe');
final String? username = await container.getString('username');
```

See the [Containers Documentation](containers.md) for more details.

## Object Containers

You can store and retrieve custom objects by providing `toJson` and `fromJson` functions.

```dart
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

final users = await storage.jsonContainer<User>(
  'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  idGetter: (user) => user.id,
);

await users.add(User(id: 'user1', name: 'John'));
final User? user = await users.get('user1');
final List<User> allUsers = await users.getValues();
```

See the [Containers Documentation](containers.md) for more details.

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

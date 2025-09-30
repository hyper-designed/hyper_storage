# Hyper Storage

Hyper Storage is a universal abstraction layer for Key-Value local storage solutions like Shared Preferences and Hive in
Flutter. It provides a simple and consistent API for storing and retrieving data, regardless of the underlying storage
mechanism.

## Features

- Lazy by design: Fetches data only when needed.
- Simple and consistent API for key-value storage.
- Listeners for real-time updates on data changes.
- Support for multiple backends:
    - [Shared Preferences](https://pub.dev/packages/shared_preferences)
    - [Hive](https://pub.dev/packages/hive_ce)
    - [Secure Storage](https://pub.dev/packages/flutter_secure_storage)
    - In-Memory Storage
- Extensible architecture: Easily add new storage backends by extending the abstract backend class.
- Extensible serialization: Support for custom serialization and deserialization of complex objects.
- Containers: Namespaced storage areas for better organization.
- Object Containers: Type-safe storage for serializable objects.
- Mockable: Easily create mocked storage instances for testing purposes.
- ItemHolders: Wrappers for individual items with change notifications.
- Supported Data Types:
    - String
    - int
    - bool
    - double
    - num
    - List<String>
    - JSON (Map<String, dynamic>)
    - List<JSON> (List<Map<String, dynamic>>)
    - String List
    - DateTime
    - Duration

## Available Backends:

Following backends are available:
- 
- [Shared Preferences](https://pub.dev/packages/shared_preferences): [`hyper_storage_shared_preferences`](https://pub.dev/packages/hyper_storage_shared_preferences)
- [Hive](https://pub.dev/packages/hive_ce): [`hyper_storage_hive`](https://pub.dev/packages/hyper_storage_hive)
- [Secure Storage](https://pub.dev/packages/flutter_secure_storage): [`hyper_storage_secure_storage`](https://pub.dev/packages/hyper_storage_secure_storage)
- In-Memory Storage: Built-in for testing or temporary storage.

## Getting started

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  hyper_storage: <latest_version>
```

### Choose a backend and add its dependency

Hyper Storage by itself does not include any storage backend. You need to choose a backend that fits your needs and add
its dependency. Following are the available backends:

```yaml
dependencies:
  # Shared Preferences
  hyper_storage_shared_preferences: <latest_version>
  # Hive
  hyper_storage_hive: <latest_version>
  # Flutter Secure Storage
  hyper_storage_secure_storage: <latest_version>
```

## Initialization

You need to initialize Hyper Storage before using it. You can do this in the `main` function of your app.

```dart
  // For Shared Preferences backend
await
HyperStorage.init
(
backend
:
SharedPreferencesBackend
(
)
);
```

```dart
    // For Hive backend
await
HyperStorage.init
(
backend
:
HiveBackend
(
)
);
```

```dart
    // For Flutter Secure Storage backend
await
HyperStorage.init
(
backend
:
SecureStorageBackend
(
)
);
```

```dart
    // In-Memory backend (for testing or temporary storage)
await
HyperStorage.init
(
backend
:
InMemoryBackend
(
)
);
```

## Usage

Storing data

```dart
await
storage.setString
('name
'
,
'
John
'
);await storage.setInt('age', 30);
await storage.setBool('isDeveloper', true);
await storage.setDouble('height', 1.75);
await storage.setStringList('skills', ['Dart', 'Flutter', 'JavaScript']);

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
]
);
```

Getting data

```dart

final String? name = await
storage.getString
('name
'
);final int? age = await storage.getInt('age');
final bool? isDeveloper = await storage.getBool('isDeveloper');
final double? height = await storage.getDouble('height');
final List<String>? skills = await storage.getStringList('skills');
final Map<String, dynamic>? profile = await storage.getJson('profile');
final List<Map<String, dynamic>>? items = await storage.getJsonList('
items
'
);
```

Using named containers

```dart

final container = await
HyperStorage.container
('account
'
);await container.setString('username', 'john_doe');
final String? username = await container.
getString
(
'
username
'
);
```

Checking if a key exists

```dart

final bool containsName = await
storage.containsKey
('name
'
);final bool containsUsername = await container.containsKey('username'
);
```

Generics

```dart

final bool subscribed = await
storage.get
('subscribed
'
);await localStorage.set('age', 32); // sets int value.
```

Object Containers: JSON serializable containers.

```dart

final storage = await
HyperStorage.objectContainer<User>
('users
'
,toJson: (user) => user.toJson(),
fromJson: User.fromJson,
);

await storage.set('user1', User(name: 'John', age: 23));
final User? user = await storage.get('user1');
final List<User> users = await storage.getValues();
final Map<String, User> allUsers = await
storage
.
getAll
(
);
```

Closing the storage

```dart
await
storage.close
(); // closes all containers.
```

Use mocked for testing

```dart

final storage = await
HyperStorage.initMocked
();
```

Optionally populate with data

```dart

final storage = await
HyperStorage.initMocked
(
initialData: {});
```

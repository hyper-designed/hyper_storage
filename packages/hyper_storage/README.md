# Local Storage

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

How to initialize and use the local storage backend. Default backend is shared preferences in async mode.
```dart
final LocalStorage localStorage = await LocalStorage.init();
```

How to use hive backend
```dart
final LocalStorage localStorage = await LocalStorage.init(backend: HiveBackend());
```
Available Backends:
- SharedPreferencesBackend
- HiveBackend 
- InMemoryBackend

Storing data
```dart
await localStorage.setString('name', 'John');
await localStorage.setInt('age', 30);
await localStorage.setBool('isDeveloper', true);
await localStorage.setDouble('height', 1.75);
await localStorage.setStringList('skills', ['Dart', 'Flutter', 'JavaScript']);
await localStorage.setJson('profile', {
    'name': 'John Doe',
    'age': 30,
    'isDeveloper': true,
    'height': 1.75,
    'skills': ['Dart', 'Flutter', 'JavaScript'],
});
await localStorage.setJsonList('items', [
    {'id': 1, 'name': 'Item 1'},
    {'id': 2, 'name': 'Item 2'},
    {'id': 3, 'name': 'Item 3'},
]);
```

Getting data
```dart
final String? name = await localStorage.getString('name');
final int? age = await localStorage.getInt('age');
final bool? isDeveloper = await localStorage.getBool('isDeveloper');
final double? height = await localStorage.getDouble('height');
final List<String>? skills = await localStorage.getStringList('skills');
final Map<String, dynamic>? profile = await localStorage.getJson('profile');
final List<Map<String, dynamic>>? items = await localStorage.getJsonList('items');
```

Using named containers
```dart
final container = await LocalStorage.container('account');
await container.setString('username', 'john_doe');
final String? username = await container.getString('username');
```

Checking if a key exists

```dart
final bool containsName = await localStorage.containsKey('name');
final bool containsUsername = await container.containsKey('username');
```

Generics
```dart
final bool subscribed = await localStorage.get('subscribed');
await localStorage.set('age', 32); // sets int value.
```

Object Containers: JSON serializable containers.

```dart
final storage = await LocalStorage.objectContainer<User>('users',
toJson: (user) => user.toJson(),
fromJson: User.fromJson,
);

await storage.set('user1', User(name: 'John', age: 23));
final User? user = await storage.get('user1');
final List<User> users = await storage.getValues();
final Map<String, User> allUsers = await storage.getAll();
```

Closing the storage
```dart
await localStorage.close(); // closes all containers.
```

Use mocked for testing
```dart
final storage = await LocalStorage.initMocked();
```
Optionally populate with data
```dart
final storage = await LocalStorage.initMocked(initialData: {});
```

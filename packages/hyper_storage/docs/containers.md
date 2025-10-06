# Table of Contents

- [What are Containers?](#what-are-containers)
- [Using Containers](#using-containers)
- [JSON Serializable Containers](#json-serializable-containers)
- [Custom Serializable Containers](#custom-serializable-containers)
- [Container Delimiter](#container-delimiter)

## What are Containers?

A container is a logical grouping of objects within a storage system. Containers can be used to organize and manage
data, as well as to apply policies and settings to a group of objects. Containers are similar to directories or folders
in a file system, but they are not hierarchical. Instead, containers are flat and can contain any number of objects.

They are namespaced, meaning that each container has a unique name within the storage system. Containers can be used to
isolate/group/categorize data, making it easier to manage and retrieve.

For example, you might create a container for storing settings, another for storing user data, another for caching
feed, favorites, downloads, etc.

## Using Containers

To use containers in Hyper Storage, you can create a new container using the `container` method. This method
returns a `Container` object that you can use to interact with the container.

If the container does not exist, it will be created automatically. If it already exists, the existing container will be
returned.

```dart
import 'package:hyper_storage/hyper_storage.dart';

void main() async {
    final storage = await HyperStorage.init(backend: SharedPreferencesBackend());
    
    // Create or get a container named 'settings'
    final settingsContainer = await storage.container('settings');
    
    // Use the container to store and retrieve data
    await settingsContainer.setString('theme', 'dark');
    final theme = await settingsContainer.getString('theme');
    print('Current theme: $theme'); // Output: Current theme: dark
}
```

You can perform all operations on a container that you can perform on the main storage instance, such as `set`, `get`,
`delete`, `clear`, etc. All the supported data types are also supported within containers.

```dart
await settingsContainer.setDouble('volume', 0.8);
await settingsContainer.setBool('notifications', true);
await settingsContainer.setDateTime('last_updated', dateTime);
```

Containers are a powerful feature of Hyper Storage that can help you organize and manage your data more effectively.
Think of them like boxes where you can store related items together for easy access and management. You can have 
multiple boxes (containers) for different purposes, such as one for user settings, another for app data, and so on.

## JSON Serializable Containers

Containers also support storing and retrieving JSON serializable objects. You can use these kind of containers to
store complex data structures in a structured way. For example, storing a list of Todo items with `Todo` class.

```dart
final todoContainer = await storage.jsonContainer<Todo>('todos');

await todoContainer.set('task1', Todo(id: 'task1', title: 'Buy groceries', isCompleted: false));
final todo = await todoContainer.get('task1');
await todoContainer.remove('task1');
```

### Providing a custom ID

By default, serializable containers would generate a unique String ID for each object you store. However, you can
also provide a custom ID by providing a `idGetter` function when creating the container.

```dart
final todoContainer = await storage.jsonContainer<Todo>(
  'todos',
  idGetter: (todo) => todo.id,
);

await todoContainer.add(Todo(id: 't1', title: 'Buy groceries', isCompleted: false));
await todoContainer.get('t1');
await todoContainer.remove('t1');
```

## Custom Serializable Containers

While Hyper Storage provides built-in support for JSON serialization, you can also create containers for custom
serialization formats by extending the `SerializableStorageContainer` class. This allows you to define your own serialization 
and deserialization logic.

```dart
class XmlSerializableContainer<E extends Object> extends SerializableStorageContainer<E> {
  XmlSerializableContainer({super.backend, super.name});

  @override
  E deserialize(String value) {
    // Implement your XML deserialization logic here
    // For example, using an XML parsing library to convert XML string to object
    throw UnimplementedError();
  }

  @override
  String serialize(E value) {
    // Implement your XML serialization logic here
    // For example, using an XML building library to convert object to XML string
    throw UnimplementedError();
  }
}
```

## Container Delimiter

The way containers are implemented is by prefixing the keys with the container name followed by a delimiter. 
By default, the delimiter is a dot (`___`). For example, if you have a container named `settings` and you store a key
`theme` with value `dark`, the actual key stored in the backend would be `settings___theme`.

This is done to isolate the keys into a namespace, preventing key collisions between different containers. You can
change the delimiter by providing a custom delimiter when initializing Hyper Storage.

```dart
// Create a storage instance with a custom delimiter.
final storage = await storage.container('todos', delimiter: '--');
```
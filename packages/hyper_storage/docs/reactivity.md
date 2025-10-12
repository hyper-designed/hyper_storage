# Table of Contents

- [Reactivity](#reactivity)
- [Listening to Key Changes](#listening-to-key-changes)
- [Listening to All Changes](#listening-to-all-changes)
- [Streaming Item Holder Changes](#streaming-item-holder-changes)
- [Converting Item Holder to a ValueNotifier](#converting-item-holder-to-a-valuenotifier)
- [Streaming key changes](#streaming-key-changes)
- [⚠️ Important: Using Streams with Flutter's StreamBuilder](#️-important-using-streams-with-flutters-streambuilder)
- [Streaming with Serializable Containers](#streaming-with-serializable-containers)

## Reactivity

`hyper_storage` supports reactivity through the use of listeners. You can listen for changes to specific keys or to all
changes in the storage. This is useful for updating your UI or triggering actions when data changes. Both the main
storage and containers including Item Holder support reactivity.

## Listening to Key Changes

Listening to changes for a specific key allows you to react only when that particular key is modified.

```dart
// Register a listener for a specific key
storage.addKeyListener('name', onKeyChanged);

void onKeyChanged() async {
  final newValue = await storage.getString('name');
  print('The value of "name" has changed to: $newValue');
}

// unregister the listener
storage.removeKeyListener('name', onKeyChanged);
```

You can also listen to key changes in a named container:

```dart
final container = await storage.container('user');

// Register a listener for a specific key in the container
container.addKeyListener('email', onEmailChanged);

void onEmailChanged() async {
  final newEmail = await container.getString('email');
  print('The email has changed to: $newEmail');
}

// unregister the listener
container.removeKeyListener('email', onEmailChanged);
```

Item Holder also supports listeners:

Item holders itself only holds a single value, so you don't need to specify a key when adding a listener.

```dart
final itemHolder = storage.itemHolder<String>('status');

// Register a listener for changes in the item holder
itemHolder.addListener(onStatusChanged);

void onStatusChanged() async {
  final newStatus = await itemHolder.get();
  print('The status has changed to: $newStatus');
}

// unregister the listener
itemHolder.removeListener(onStatusChanged);
```

## Listening to All Changes
You can listen to all changes in the storage, regardless of which key was modified.

```dart
// Register a listener for all changes
storage.addListener(onStorageChanged);

void onStorageChanged() {
  print('The storage has changed.');
}

// unregister the listener
storage.removeListener(onStorageChanged);
```

You can also listen to all changes in a named container:

```dart
final container = await storage.container('settings');

// Register a listener for all changes in the container
container.addListener(onSettingsChanged);

void onSettingsChanged() {
  print('The settings container has changed.');
}

// unregister the listener
container.removeListener(onSettingsChanged);
```

# Streaming Item Holder Changes

Item Holder also supports streaming changes using Dart's `Stream` API. This allows you to listen to changes in a more
flexible way, such as using `StreamBuilder` in Flutter.

`ItemHolder<E>` implements `Stream<E?>`, so you can listen to it directly.

```dart
final itemHolder = storage.itemHolder<String>('status');

// Listen to changes using Stream API
final subscription = itemHolder.listen((newStatus) {
    print('The status has changed to: $newStatus');
});

// Don't forget to cancel the subscription when it's no longer needed
subscription.cancel();
```

Using with StreamBuilder in Flutter:

```dart
StreamBuilder<String?>(
  stream: itemHolder,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    final status = snapshot.data ?? 'Unknown';
    return Text('Status: $status');
  },
);
```

## Converting Item Holder to a ValueNotifier

You can convert an `ItemHolder` to a `ValueNotifier` for easier integration with Flutter's state management.

```dart
final itemHolder = storage.itemHolder<String>('status');

// Convert to ValueNotifier
final valueNotifier = itemHolder.asValueNotifier();

// Use with ValueListenableBuilder in Flutter
ValueListenableBuilder<String?>(
  valueListenable: valueNotifier,
  builder: (context, status, child) {
    return Text('Status: ${status ?? 'Unknown'}');
  },
);
```
> Whenever you call `asValueNotifier`, it creates a new `ValueNotifier` instance. If you want to avoid creating 
> multiple instances, consider storing the `ValueNotifier` in a variable and reusing it. Remember to dispose the
> `ValueNotifier` once you no longer need it. 
> 
> Make sure to add `hyper_storage_flutter` package to your dependencies to use `asValueNotifier` method.

## Streaming key changes

You can also stream changes for a specific key using the `stream` method.

```dart
// Listen to changes for a specific key
final nameStream = storage.stream<String>('name');
final subscription = nameStream.listen((newName) {
    print('The value of "name" has changed to: $newName');
});
// Don't forget to cancel the subscription when it's no longer needed
subscription.cancel();
```

You can also stream key changes in a named container:

```dart
final container = await storage.container('user');

// Listen to changes for a specific key in the container
final emailStream = container.stream<String>('email');

final subscription = emailStream.listen((newEmail) {
    print('The email has changed to: $newEmail');
});

// Don't forget to cancel the subscription when it's no longer needed
subscription.cancel();
```

## ⚠️ Important: Using Streams with Flutter's StreamBuilder

When using streams with Flutter's `StreamBuilder`, it's crucial to understand the difference between safe and unsafe patterns.

### ❌ **Unsafe Pattern: Calling `stream()` directly in build method**

**DO NOT do this:**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: storage.stream<String>('name'), // ❌ BAD: Creates new stream every rebuild!
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }
}
```

**Why this is problematic:**

- Every time `build()` is called, a **new stream instance** is created
- `StreamBuilder` detects a different stream and recreates the subscription
- This causes:
  - Unnecessary memory allocations (new `StreamController` each time)
  - Performance overhead (creating/destroying subscriptions repeatedly)
  - The initial value is re-fetched unnecessarily
  - Potential UI flickering as the stream restarts

### ✅ **Safe Pattern 1: Use ItemHolder (Recommended)**

The recommended approach is to use `ItemHolder`, which is specifically designed for this use case:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Create ItemHolder once - it's a persistent stream
  late final itemHolder = storage.itemHolder<String>('name');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: itemHolder, // ✅ SAFE: ItemHolder is the same instance every time
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }

  @override
  void dispose() {
    itemHolder.dispose(); // Clean up when done
    super.dispose();
  }
}
```

**Why ItemHolder is safe:**

- `ItemHolder` **is** a `Stream` - it implements `Stream<E?>`
- It uses a single, persistent `StreamController.broadcast()`
- The same `ItemHolder` instance is reused on every build
- Efficient: no unnecessary object creation or subscription cycling

### ✅ **Safe Pattern 2: Cache the stream in a variable**

If you prefer to use the `stream()` method, cache it in a `late final` variable:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Cache the stream - created once and reused
  late final Stream<String?> nameStream = storage.stream<String>('name');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: nameStream, // ✅ SAFE: Same stream instance reused
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }
}
```

### ✅ **Safe Pattern 3: Create stream in `initState()`**

Alternatively, create the stream in `initState()`:

```dart
class _MyWidgetState extends State<MyWidget> {
  late Stream<String?> nameStream;

  @override
  void initState() {
    super.initState();
    nameStream = storage.stream<String>('name');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: nameStream, // ✅ SAFE: Same stream instance
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }
}
```

### Summary: Which pattern should you use?

| Pattern | Recommended? | When to use |
|---------|-------------|-------------|
| **ItemHolder** | ✅ **Best** | Default choice for most cases. Clean, efficient, purpose-built for Flutter. |
| **Cached stream (late final)** | ✅ Good | When you need the `stream()` method specifically. |
| **initState stream** | ✅ Good | When initialization logic is complex. |
| **Direct stream() call in build()** | ❌ **Never** | Don't use - causes performance issues. |

## Streaming with Serializable Containers

You can also stream changes in a `SerializableContainer`. This is useful when you want to listen to changes in a complex
object.

```dart
final todos = await storage.jsonSerializableContainer<Todo>(
  'todos',
  fromJson: Todo.fromJson,
  toJson: (todo) => todo.toJson(),
);

// Listen to changes in the entire container.
final allTodosSubscription = todos.streamAll().listen((items) {
  print('Todos changed: $items');
});

// Don't forget to cancel the subscription when it's no longer needed.
allTodosSubscription.cancel();
```

You can also stream changes for a specific key in a `SerializableStorageContainer`:

```dart
final todos = await storage.jsonSerializableContainer<Todo>(
  'todos',
  fromJson: Todo.fromJson,
  toJson: (todo) => todo.toJson(),
);

// Listen to changes for a specific key in the container
final todoSubscription = todos.stream<Todo>('todo1').listen((todo) {
  print('Todo todo1 changed: $todo');
});

todoSubscription.cancel();
```

The same streaming APIs are available for any custom container that extends `SerializableStorageContainer`.

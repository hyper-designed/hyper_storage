# Table of Contents

- [Reactivity](#reactivity)
- [Listening to Key Changes](#listening-to-key-changes)
- [Listening to All Changes](#listening-to-all-changes)
- [Streaming Item Holder Changes](#streaming-item-holder-changes)
- [Converting Item Holder to a ValueNotifier](#converting-item-holder-to-a-valuenotifier)
- [Streaming key changes](#streaming-key-changes)
- [Streaming with Serializable Containers](#streaming-with-serializable-containers)

## Reactivity

`hyper_storage` supports reactivity through the use of listeners. You can listen for changes to specific keys or to all
changes in the storage. This is useful for updating your UI or triggering actions when data changes. Both the main
storage and containers including Item Holder support reactivity.

## Listening to Key Changes

Listening to changes for a specific key allows you to react only when that particular key is modified.

```dart
// Register a listener for a specific key
storage.addKeyListener
('name
'
, onKeyChanged);

void onKeyChanged() async {
final newValue = await storage.getString('name');
print('The value of "name" has changed to: $newValue');
}

// unregister the listener
storage.removeKeyListener('name', onKeyChanged);
```

You can also listen to key changes in a named container:

```dart

final container = await
storage.container
('user
'
);

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
itemHolder.addListener
(
onStatusChanged);

void onStatusChanged() async {
final newStatus = await itemHolder.get();
print('The status has changed to: $newStatus');
}

// unregister the listener
itemHolder
.
removeListener
(
onStatusChanged
);
```

## Listening to All Changes

You can listen to all changes in the storage, regardless of which key was modified.

```dart
// Register a listener for all changes
storage.addListener
(
onStorageChanged);

void onStorageChanged() {
print('The storage has changed.');
}

// unregister the listener
storage
.
removeListener
(
onStorageChanged
);
```

You can also listen to all changes in a named container:

```dart

final container = await
storage.container
('settings
'
);

// Register a listener for all changes in the container
container.addListener(onSettingsChanged);

void onSettingsChanged() {
print('The settings container has changed.');
}

// unregister the listener
container
.
removeListener
(
onSettingsChanged
);
```

# Streaming Item Holder Changes

Item Holder also supports streaming changes using Dart's `Stream` API. This allows you to listen to changes in a more
flexible way, such as using `StreamBuilder` in Flutter.

`ItemHolder<E>` extends `ManagedStream<E?>` and implements `Stream<E?>`, so you can listen to it directly.

```dart

final itemHolder = storage.itemHolder<String>('status');

// Listen to changes using Stream API
final subscription = itemHolder.listen((newStatus) {
  print('The status has changed to: $newStatus');
});

// Don't forget to cancel the subscription when it's no longer needed
subscription.cancel
();
```

## Using with StreamBuilder in Flutter

ItemHolder is specifically designed for use with Flutter's `StreamBuilder`:

```dart
StreamBuilder<String?>(
  stream: itemHolder,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    // Note: ItemHolder doesn't emit errors - they're handled silently
    final status = snapshot.data ?? 'Unknown';
    return Text('Status: $status');
  },
);
```

**Note**: Unlike traditional streams, ItemHolder does **not** emit errors during value retrieval. This prevents
transient failures (like network issues) from being cached and replayed to future listeners. The stream simply
retains its last valid value and retries on the next update.

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

## Using Streams with Flutter's StreamBuilder

When using streams with Flutter's `StreamBuilder`.

```dart
StreamBuilder<String?>(
  stream: storage.stream<String>('name'), // Use directly from storage.
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    final name = snapshot.data ?? 'Unknown';
    return Text('Name: $name');
  },
);
```

This means calling `storage.stream('key')` directly in a build method is safe and will not create multiple streams.

**Recommended Pattern: Use ItemHolder Directly**: If you have an `ItemHolder` for the key, you can use it directly in
the `StreamBuilder`. This is the most efficient and clear approach.

```dart
class _MyWidgetState extends State<MyWidget> {
  // Create ItemHolder once - it's a persistent stream with value caching
  late final itemHolder = storage.itemHolder<String>('name');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: itemHolder, // uses ItemHolder directly
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        // Note: ItemHolder doesn't emit errors - no need to check snapshot.hasError
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

**Why ItemHolder is recommended:**

- **Clear intent**: Makes it obvious you're using a managed stream
- **Value caching**: Uses `BehaviorSubject` - new listeners get the cached value immediately
- **Efficient**: Single persistent stream with lazy activation
- **Multiple listeners**: Supports many concurrent listeners without duplicating work
- **No error emissions**: Transient failures don't get cached and replayed

### ✅ **Also Acceptable: Cache the stream in a variable**

If you prefer to use the `stream()` method, you can cache it in a `late final` variable.
Since `stream()` returns a cached `ItemHolder`, this is now equivalent to Pattern 1:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Cache the stream - actually returns the same ItemHolder as itemHolder<String>('name')
  late final Stream<String?> nameStream = storage.stream<String>('name');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: nameStream, // ✅ SAFE: Same cached ItemHolder instance
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }

  @override
  void dispose() {
    // If using stream(), you can cast to dispose if needed
    if (nameStream is ItemHolder) {
      (nameStream as ItemHolder).dispose();
    }
    super.dispose();
  }
}
```

### ✅ **Create stream in `initState()`**

You can also create the stream in `initState()`:

```dart
class _MyWidgetState extends State<MyWidget> {
  late Stream<String?> nameStream;

  @override
  void initState() {
    super.initState();
    nameStream = storage.stream<String>('name'); // Returns cached ItemHolder
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: nameStream, // ✅ SAFE: Same cached instance
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Unknown');
      },
    );
  }
}
```

### Summary: Which pattern should you use?

| Pattern                        | Recommended?                      | Notes                                                                      |
|--------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| **ItemHolder directly**        | ✅ **Best**                        | Most explicit. Clear intent. Direct access to ItemHolder API.              |
| **Cached stream (late final)** | ✅ Good                            | Same as above but less explicit. `stream()` returns ItemHolder internally. |
| **initState stream**           | ✅ Good                            | Useful for complex initialization. Still returns cached ItemHolder.        |
| **Direct stream() in build()** | ⚠️ **Acceptable but discouraged** | Now safe (returns cached instance) but not recommended for code clarity.   |

## Streaming with Serializable Containers

You can also stream changes in a `SerializableContainer`. This is useful when you want to listen to changes in a complex
object.

```dart

final todos = await storage.jsonSerializableContainer<Todo>('todos', 
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

final todos = await storage.jsonSerializableContainer<Todo>('todos',
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

# Table of Contents

- [What is Item Holder?](#what-is-item-holder)
- [How to use](#how-to-use)
- [JSON Item Holders](#json-item-holders)
- [Serializable Item Holders](#serializable-item-holders)
- [Custom Item Holders](#custom-item-holders)
- [Custom Serializable holders](#custom-serializable-holders)

## What is Item Holder?

An Item Holder is an interface that holds a single item of type E from the storage or a container. Think of it as
a wrapper around a single item that provides CRUD (Create, Read, Update, Delete) operations around that one item
in underlying storage.

Item holders make it easy to pass around a single item and use it from multiple places in your code.

## How to use

```dart

final ItemHolder<int> countHolder = storage.holder<int>('counter');

// Reading the value
final int count = await countHolder.get() ?? 0;

// Updating the value
await countHolder.set(count + 1);

// Deleting the value
await countHolder.remove();

// Closing the holder when no longer needed
await countHolder.dispose();
```

You must provide a generic type `E` to the `ItemHolder` to specify the type of item it holds.

The type `E` must be one of the supported types:

- `int`
- `double`
- `bool`
- `String`
- `List<String>`
- `Map`
- `List<Map>`
- `DateTime`
- `Duration`

Optionally, you can pass getter and setter functions to provide custom read/write logic for underlying storage.


Calling `storage.itemHolder` multiple times with the same key will return the same instance of `ItemHolder`. Hyper Storage
internally caches the created item holders.

> If an item holder with given key already exists with a different type, an exception will be thrown.

## JSON Item Holders

If you want to store JSON serializable objects, you can use `JsonItemHolder` which allows you to define
`fromJson` and `toJson` functions for your custom types. Under the hood, it is stored as a `String` value.

```dart

final JsonItemHolder<User> userHolder = storage.jsonHolder<User>(
  'user',
  fromJson: (json) => User.fromJson(json),
  toJson: (user) => user.toJson(),
);

// Reading the value
final User? user = await userHolder.get();

// Updating the value
await userHolder.set(User(id: 1, name: 'John Doe'));

// Deleting the value
await userHolder.remove();
```

## Serializable Item Holders

If you want to store custom objects, you can use `SerializableItemHolder` which allows you to define
serialization and deserialization logic for your custom types. Under the hood, it is stored as a `String` value.

```dart

final SerializableItemHolder<User> userHolder = storage.serializableHolder<User>(
  'user',
  serialize: (user) => user.toXML(), // Run your serialization logic here and return a String
  deserialize: (data) => User.fromXML(data), // Run your deserialization logic here and return a User object
);
```

## Custom Item Holders

If you need a custom item holder with specific behavior, you can create your own by extending the `ItemHolder` class.

```dart
class ColorHolder extends ItemHolder<Color> {
  ColorHolder(BaseStorage storage, String key)
      : super(
    storage,
    key,
    getter: (storage, key) async {
      final colorInt = await storage.getInt(key);
      if (colorInt == null) return null;
      return Color(colorInt);
    },
    setter: (storage, key, value) => storage.setInt(key, value.toARGB32()),
  );
}
```
You can then use your custom item holder by calling the `customHolder` method on the `HyperStorage` instance.

```dart
final colorHolder = storage.customHolder<ColorHolder, Color>(
    'favorite_color',
    create: (backend, key) => ColorHolder(backend, key),
);
```

### Custom Serializable holders
If any of the above use-cases do not fit your needs, you can implement your own Item Holder by extending
`SerializableItemHolder` and providing your own serialization and deserialization logic.

```dart
final class XMLItemHolder<E extends Object> extends SerializableItemHolder<E> {
  XMLItemHolder(StorageBackend backend, String key) : super(
    backend,
    key,
    serialize: (E item) => encodeXml(item), // Implement your XML serialization logic here
    deserialize: (value) => decodeXml(value), // Implement your XML deserialization logic here.
  );
}
```

To use your custom item holder, you can call `customHolder` method on `HyperStorage` instance.

```dart

final userHolder = storage.customHolder<XMLItemHolder<User>, User>(
  'user',
  create: (backend, key) => XMLItemHolder<User>(backend, key),
);
```


Hyper Storage supports enums out of the box. Enums are a treated as special kind of data type as it is such data type
in Dart language.

> For any `Enum` related operations where a value needs to be read from underlying storage, you need to provide a
> list of all possible enum values. This is due to limitations of Dart language and Flutter, which does not support
> reflection at runtime (e.g. `Role.values`).

# Table of Contents

- [Storing Enums](#storing-enums)
- [Retrieving Enums](#retrieving-enums)
- [Using ItemHolder with Enums](#using-itemholder-with-enums)
- [Streaming Enums](#streaming-enums)

## Storing Enums

Storing enums is as simple as storing any other data type. You can store enums in a document like this:

```dart
await storage.setEnum('role', Role.guest);
```
Under the hood, Hyper Storage stores enums as their string representation. For example, the enum value `Role.guest`
is stored as the string `"guest"`.

Storing enums in a container is also supported:

```dart
final container = await storage.container('settings');
await container.setEnum('brightness', Brightness.dark);
```

You can also use the generic `set` method to store enums:

```dart
await storage.set('role', Role.admin);
```


## Retrieving Enums

Due to limitations of Dart, retrieving enums requires you to provide a list all possible enum values. 
This is necessary because Dart does not support reflection, and thus cannot determine the enum type at runtime.

You can retrieve enums like this:

```dart
final role = await storage.getEnum<Role>('role', Role.values);
```

If the stored value does not match any of the provided enum values, `null` is returned. The API for the container is
also the same:

```dart
final container = await storage.container('settings');
final brightness = await container.getEnum<Brightness>('brightness', Brightness.values);
```

You can also use the generic `get` method to retrieve enums:

```dart
final role = await storage.get<Role>('role', enumValues: Role.values);
```

## Using ItemHolder with Enums

You can also use `ItemHolder` to store and retrieve enums. Here's an example:

```dart
final roleHolder = storage.itemHolder<Role>(
  'role',
  enumValues: Role.values,
);

// Set the enum value
await roleHolder.set(Role.user);

// Get the enum value
final role = await roleHolder.get();
```

## Streaming Enums

You can stream changes to enum values using the `stream` method. Here's an example:

```dart
final roleStream = storage.stream<Role>('role', enumValues: Role.values);

roleStream.listen((role) {
  print('Role changed to: $role');
});
```

With containers:

```dart
final container = await storage.container('settings');

final brightnessStream = container.stream<Brightness>(
  'brightness',
  enumValues: Brightness.values,
);

brightnessStream.listen((brightness) {
  print('Brightness changed to: $brightness');
});
```

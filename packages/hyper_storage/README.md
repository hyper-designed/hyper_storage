# hyper_storage

[![pub version](https://img.shields.io/pub/v/hyper_storage.svg)](https://pub.dev/packages/hyper_storage)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A simple and flexible key-value storage for Dart and Flutter applications, supporting multiple backends.

## Features

-   ✅ **Simple API:** Easy to use API for storing and retrieving data.
-   ✅ **Multiple Backends:** Supports different backends like `InMemory`, with more to come.
-   ✅ **Typed Storage:** Store and retrieve data with type safety.
-   ✅ **JSON Serialization:** Store and retrieve custom objects by providing `toJson` and `fromJson` functions.
-   ✅ **Named Containers:** Organize your data into named containers.
-   ✅ **Mockable:** Easy to mock for testing purposes.

## Getting started

Add `hyper_storage` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  hyper_storage: ^0.1.0 # Replace with the latest version
```

Then, run `flutter pub get` or `dart pub get`.

## Usage

Initialize the storage with a backend. The `InMemoryBackend` is included by default for temporary storage.

```dart
import 'package:hyper_storage/hyper_storage.dart';

void main() async {
  // Initialize the storage with InMemoryBackend
  final storage = await HyperStorage.init(backend: InMemoryBackend());

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
-   [hyper_secure_storage](https://pub.dev/packages/hyper_secure_storage): Secure storage backend for sensitive data.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.
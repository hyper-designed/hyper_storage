# Table of Contents

- [Available Backends](#available-backends)
- [In-Memory Backend](#in-memory-backend)
- [Shared Preferences Backend](#shared-preferences-backend)
- [Hive Backend](#hive-backend)
- [Secure Storage Backend](#secure-storage-backend)
- [Custom Backends](#custom-backends)
- [Using Multiple Backends](#using-multiple-backends)

# Available Backends

## In-Memory Backend:

A simple, built-in, in-memory backend for temporary storage. This backend is useful for testing and scenarios where data
persistence is not required. Data stored in this backend will be lost when the application is closed or restarted.

```dart
import 'package:hyper_storage/hyper_storage.dart';

void main() async {
  final storage = await HyperStorage.init(backend: InMemoryBackend());
}
```

> In memory backend is backed by a simple `Map`. It is not suitable for production use cases where data persistence is
> required.

## [Shared Preferences Backend](https://pub.dev/packages/hyper_storage_shared_preferences):

A persistent storage backend using SharedPreferences, which is ideal for storing small amounts of data in a key-value
format. This backend is commonly used for user preferences and settings. This is an ideal choice for applications that
need to store simple data that is also accessible outside the app (e.g., user preferences) and do not require high
security. For example, sharing data between Flutter and native Android/iOS code for various use-cases like widgets,
live activities, native runners, etc.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_shared_preferences/hyper_storage_shared_preferences.dart';

void main() async {
  final storage = await HyperStorage.init(backend: SharedPreferencesBackend());
}
```

> Hyper Storage uses `SharedPreferencesAsync` API under the hood, which is a fully asynchronous API for
> `SharedPreferences`.

## [Hive Backend](https://pub.dev/packages/hyper_storage_hive):

A persistent storage backend using Hive, a lightweight and fast key-value database written in pure Dart. This backend
is suitable for storing larger amounts of data and supports complex data types.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  final storage = await HyperStorage.init(backend: HiveBackend());
}
```

The package also provides a `LazyHiveBackend`, which initializes Hive lazily. This is useful in scenarios where you want
to defer the initialization of Hive until it's actually needed, potentially improving startup performance.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  // Initialize Hive before using LazyHiveBackend.
  await Hive.initFlutter();
  final storage = await HyperStorage.init(backend: LazyHiveBackend());
}
```

> Hive backend requires initialization of Hive before use. Hyper Storage do not handle Hive initialization for you.
> You need to initialize Hive in your application before using the Hive backend. For example:

## [Secure Storage Backend](https://pub.dev/packages/hyper_secure_storage):

A secure storage backend using [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage), which
provides a way to store sensitive data securely. This backend is ideal for storing credentials, tokens, and other
sensitive information.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_secure_storage/hyper_secure_storage.dart';

void main() async {
  final storage = await HyperStorage.init(backend: SecureStorageBackend());
}
```

You can optionally provide an instance `FlutterSecureStorage` to the `SecureStorageBackend` constructor to customize its
behavior.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hyper_storage/hyper_storage.dart';

import 'package:hyper_secure_storage/hyper_secure_storage.dart';

void main() async {
  final secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final storage = await HyperStorage.init(
    backend: SecureStorageBackend(secureStorage: secureStorage),
  );
}
```

## Custom Backends

Hyper Storage is designed to be extensible, allowing you to create your own custom backends by implementing the
`StorageBackend` interface. This enables you to integrate with any storage solution that fits your application's
requirements.

```dart
// Define your custom backend by implementing the StorageBackend interface.
class YourCustomBackend implements StorageBackend {
  // Implement all required methods here.
}
```

Then, you can use your custom backend with Hyper Storage as follows:

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:your_custom_backend/your_custom_backend.dart';

void main() async {
  final storage = await HyperStorage.init(backend: YourCustomBackend());
}
```

## Using Multiple Backends

You can also use multiple backends in your application by creating separate `HyperStorage` instances for each backend.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_shared_preferences/hyper_storage_shared_preferences.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  final sharedPreferencesStorage = await HyperStorage.newInstance(backend: SharedPreferencesBackend());
  final hiveStorage = await HyperStorage.newInstance(backend: HiveBackend());

  // Use sharedPreferencesStorage for user preferences
  await sharedPreferencesStorage.setString('theme', 'dark');

  // Use hiveStorage for app data
  await hiveStorage.setString('user_data', 'some complex data');
}
```
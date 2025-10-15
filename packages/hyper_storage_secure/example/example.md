# Hyper Secure Storage Examples

This file provides examples of how to use the `hyper_storage_secure` package with `hyper_storage` in a Flutter application for storing sensitive data.

## Contents

-   [Initialization](#initialization)
-   [Usage with HyperStorage](#usage-with-hyperstorage)
-   [Platform Specific Options](#platform-specific-options)

## Initialization

To use the secure storage backend, you need to initialize `hyper_storage` with `SecureStorageBackend`.

Make sure to call `WidgetsFlutterBinding.ensureInitialized()` before initializing the storage.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_secure/hyper_storage_secure.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage with SecureStorageBackend
  final storage = await HyperStorage.init(backend: SecureStorageBackend());

  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final HyperStorage storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<String?>(
            future: storage.get('secret_token'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(snapshot.data ?? 'No secret token yet');
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await storage.set('secret_token', 'a_very_secret_token');
          },
          child: const Icon(Icons.lock),
        ),
      ),
    );
  }
}
```

## Usage with HyperStorage

Once initialized, you can use `hyper_storage` to securely store and retrieve sensitive information like API keys, tokens, and passwords.

**Note:** Values are persisted as strings under the hood, and the backend provides helpers to parse them back into
common Dart primitives.

### Storing Data

```dart
await storage.set('auth_token', 'your_auth_token');
await storage.set('password', 'your_password');
```

### Retrieving Data

```dart
final authToken = await storage.get('auth_token');
final password = await storage.get('password');
```

## Platform Specific Options

You can pass platform-specific options to the `SecureStorageBackend` constructor. For example, to configure Android-specific options:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final backend = SecureStorageBackend(
  storage: FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final storage = await HyperStorage.init(backend: backend);
```

For more information on available options, please refer to the [`flutter_secure_storage` documentation](https://pub.dev/packages/flutter_secure_storage).

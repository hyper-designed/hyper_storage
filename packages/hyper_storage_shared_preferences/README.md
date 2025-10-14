# hyper_storage_shared_preferences

[![pub version](https://img.shields.io/pub/v/hyper_storage_shared_preferences.svg)](https://pub.dev/packages/hyper_storage_shared_preferences)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A backend for `hyper_storage` that uses `shared_preferences` for Flutter applications.

### [Full Documentation](https://pub.dev/documentation/hyper_storage/latest)

## Features

-   **Persistent Storage:** Persists data on the device using `shared_preferences`.
-   **Flutter Support:** Designed to work seamlessly with Flutter applications.
-   **Easy Integration:** Simple to integrate with `hyper_storage`.

## Getting started

Add `hyper_storage_shared_preferences` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hyper_storage: ^0.1.0 # Replace with the latest version
  hyper_storage_shared_preferences: ^0.1.0 # Replace with the latest version
```

Then, run `flutter pub get`.

## Usage

Initialize `hyper_storage` with `SharedPreferencesBackend`.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_shared_preferences/shared_preferences_backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage with SharedPreferencesBackend
  final storage = await HyperStorage.init(backend: SharedPreferencesBackend());

  // Now you can use the storage as usual
  await storage.set('theme', 'dark');
  final theme = await storage.get('theme');
  print(theme); // Output: dark

  await storage.close();
}
```

For more detailed examples, please see the [example.md](example.md) file.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

# hyper_storage_secure

[![pub version](https://img.shields.io/pub/v/hyper_storage_secure.svg)](https://pub.dev/packages/hyper_storage_secure)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A backend for `hyper_storage` that uses `flutter_secure_storage` for secure data storage.

### [Full Documentation](https://pub.dev/documentation/hyper_storage/latest)

## Features

-   **Secure Storage:** Securely persists data on the device using `flutter_secure_storage`.
-   **Cross-Platform:** Works on iOS, Android, and other platforms supported by `flutter_secure_storage`.
-   **Easy Integration:** Simple to integrate with `hyper_storage`.

## Getting started

Add `hyper_storage_secure` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hyper_storage: ^0.1.0 # Replace with the latest version
  hyper_storage_secure: ^0.1.0 # Replace with the latest version
```

Then, run `flutter pub get`.

### Platform Specific Setup

Please follow the setup instructions for `flutter_secure_storage` for each platform you support:

-   [Android Setup](https://pub.dev/packages/flutter_secure_storage#android)
-   [iOS Setup](https://pub.dev/packages/flutter_secure_storage#ios)
-   [Web Setup](https://pub.dev/packages/flutter_secure_storage#web)

## Usage

Initialize `hyper_storage` with `SecureStorageBackend`.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_secure/hyper_storage_secure.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage with SecureStorageBackend
  final storage = await HyperStorage.init(backend: SecureStorageBackend());

  // Now you can use the storage as usual to store sensitive data
  await storage.set('api_key', 'your_secret_api_key');
  final apiKey = await storage.get('api_key');
  print(apiKey);

  await storage.close();
}
```

For more detailed examples, please see the [example.md](example.md) file.

If you need to customize platform-specific options, create a configured `FlutterSecureStorage` instance and pass it to
`SecureStorageBackend` via the `storage` parameter.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

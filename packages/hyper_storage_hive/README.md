# hyper_storage_hive

[![pub version](https://img.shields.io/pub/v/hyper_storage_hive.svg)](https://pub.dev/packages/hyper_storage_hive)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A backend for `hyper_storage` that uses `hive_ce` for local data storage.

### [Full Documentation](https://pub.dev/documentation/hyper_storage/latest)

## Features

-   **Persistent Storage:** Persists data on the device using Hive.
-   **Lazy Loading:** Supports lazy loading of data to reduce memory usage.
-   **Seamless Integration:** Integrates seamlessly with `hyper_storage`.

## Getting started

Add `hyper_storage_hive` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  hyper_storage: ^0.1.0 # Replace with the latest version
  hyper_storage_hive: ^0.1.0 # Replace with the latest version
```

Then, run `flutter pub get` or `dart pub get`.

## Usage

Initialize `hyper_storage` with `HiveBackend`.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  // Initialize the storage with HiveBackend
  final storage = await HyperStorage.init(backend: HiveBackend());

  // Now you can use the storage as usual
  await storage.set('name', 'Hyper Storage with Hive');
  final name = await storage.get('name');
  print(name); // Output: Hyper Storage with Hive

  await storage.close();
}
```

For more detailed examples, please see the [example.md](example.md) file.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.
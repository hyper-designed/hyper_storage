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

### IMPORTANT
> Hive backend requires initialization of Hive before use. Hyper Storage doesn't handle Hive initialization for you as
> the initialization depends on whether the project is being used in Flutter or pure Dart environment.
> You need to initialize Hive in your application before using the Hive backend.

```dart
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_hive/hyper_storage_hive.dart';

void main() async {
  
  // IMPORTANT:
  // Hive.initFlutter() or Hive.init() must be called before using HiveBackend.
  // For Flutter:
  // await Hive.initFlutter();
  // For pure Dart:
  // Hive.init('path_to_hive_boxes');
  
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

## License

```
BSD 3-Clause License

Copyright (c) 2025, Hyperdesigned

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
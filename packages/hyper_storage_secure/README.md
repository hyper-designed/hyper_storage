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
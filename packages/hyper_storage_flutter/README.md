# hyper_storage_flutter

A package that makes it easy to use `hyper_storage` in Flutter applications.

## Features

-   **ValueListenable Support:** Listen to changes in your storage using `ValueListenable`.
-   **Reactive UI:** Automatically rebuild your widgets when the data in the storage changes.
-   **Seamless Integration:** Integrates smoothly with the Flutter framework and `hyper_storage`.

## Getting started

Add `hyper_storage_flutter` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hyper_storage: ^0.1.0 # Replace with the latest version
  hyper_storage_flutter: ^0.1.0 # Replace with the latest version
```

Then, run `flutter pub get`.

## Usage

This package provides extension methods on `ItemHolder` to get a `ValueListenable` for any key in your storage.

You can use this with a `ValueListenableBuilder` to automatically rebuild your UI when the data changes.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HyperStorage.init();
  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final HyperStorage storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hyper Storage Flutter')),
        body: Center(
          child: ValueListenableBuilder<String?>(
            valueListenable: storage.listenable('message'),
            builder: (context, message, child) {
              return Text(message ?? 'No message yet');
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await storage.set('message', 'Hello from Flutter!');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

For more detailed examples, please see the [example.md](example.md) file.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.
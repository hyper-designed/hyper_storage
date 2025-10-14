# hyper_storage_flutter

A package that makes it easy to use `hyper_storage` in Flutter applications.

### [Full Documentation](https://pub.dev/documentation/hyper_storage/latest)

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

This package extends `ItemHolder` with an `asValueNotifier` helper so you can bridge Hyper Storage with Flutter's
`ValueListenable` APIs.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_storage/hyper_storage.dart';
import 'package:hyper_storage_flutter/hyper_storage_flutter.dart';
import 'package:hyper_storage_shared_preferences/shared_preferences_backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HyperStorage.init(backend: SharedPreferencesBackend());
  runApp(MyApp(storage: storage));
}

class MyApp extends StatefulWidget {
  final HyperStorage storage;

  const MyApp({super.key, required this.storage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ItemHolder<String> _messageHolder;
  late final ValueNotifier<String?> _messageNotifier;

  @override
  void initState() {
    super.initState();
    _messageHolder = widget.storage.itemHolder<String>('message');
    _messageNotifier = _messageHolder.asValueNotifier();
  }

  @override
  void dispose() {
    _messageNotifier.dispose();
    _messageHolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hyper Storage Flutter')),
        body: Center(
          child: ValueListenableBuilder<String?>(
            valueListenable: _messageNotifier,
            builder: (context, message, child) {
              return Text(message ?? 'No message yet');
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final current = await _messageHolder.get() ?? 'Hello';
            await _messageHolder.set('$current!');
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

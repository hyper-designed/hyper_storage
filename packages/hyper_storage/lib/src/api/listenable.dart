import 'package:meta/meta.dart';

typedef ListenableCallback = void Function();

mixin ListenableStorage {
  final Map<int, ListenableCallback> _listeners = <int, ListenableCallback>{};
  final Map<String, List<ListenableCallback>> _keyedListeners = <String, List<ListenableCallback>>{};

  void addListener(ListenableCallback listener) {
    _listeners[listener.hashCode] = listener;
  }

  void removeListener(ListenableCallback listener) {
    _listeners.remove(listener.hashCode);
  }

  void addKeyListener(String key, ListenableCallback listener) {
    _keyedListeners.putIfAbsent(key, () => <ListenableCallback>[]).add(listener);
  }

  void removeKeyListener(String key, ListenableCallback listener) {
    _keyedListeners[key]?.remove(listener);
  }

  void removeAllListeners() {
    _listeners.clear();
    _keyedListeners.clear();
  }

  @protected
  @mustCallSuper
  void notifyListeners([String? key]) {
    for (final listener in _listeners.values) {
      listener();
    }
    if (key != null) notifyKeyListeners(key);
  }

  void notifyKeyListeners(String key) {
    for (final listener in _keyedListeners[key] ?? []) {
      listener();
    }
  }
}

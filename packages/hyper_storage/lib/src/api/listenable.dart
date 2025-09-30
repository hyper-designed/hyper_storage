import 'package:meta/meta.dart';

typedef ListenableCallback = void Function();

@protected
mixin ListenableStorage {
  final Set<ListenableCallback> _listeners = <ListenableCallback>{};
  final Map<String, Set<ListenableCallback>> _keyedListeners = <String, Set<ListenableCallback>>{};

  bool get hasListeners => _listeners.isNotEmpty || _keyedListeners.values.any((listeners) => listeners.isNotEmpty);

  void addListener(ListenableCallback listener) => _listeners.add(listener);

  void removeListener(ListenableCallback listener) => _listeners.remove(listener);

  void addKeyListener(String key, ListenableCallback listener) =>
      _keyedListeners.putIfAbsent(key, () => <ListenableCallback>{}).add(listener);

  void removeKeyListener(String key, ListenableCallback listener) {
    _keyedListeners[key]?.remove(listener);
    if (_keyedListeners[key]?.isEmpty == true) {
      _keyedListeners.remove(key);
    }
  }

  void removeAllListeners() {
    _listeners.clear();
    _keyedListeners.clear();
  }

  @protected
  @mustCallSuper
  void notifyListeners([String? key]) {
    for (final listener in _listeners) {
      listener();
    }
    if (key != null) notifyKeyListeners(key);
  }

  void notifyKeyListeners(String key) {
    final listeners = _keyedListeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        listener();
      }
    }
  }
}

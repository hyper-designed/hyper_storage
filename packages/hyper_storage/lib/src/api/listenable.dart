import 'package:meta/meta.dart';

/// A callback function that takes no arguments and returns no data.
///
/// This typedef is used to define listener callbacks that are invoked when
/// storage data changes.
typedef ListenableCallback = void Function();

/// A mixin that provides functionality for listening to changes in a storage.
///
/// This mixin implements the observer pattern, allowing components to be
/// notified when storage data changes. It supports both global listeners
/// (notified of any change) and key-specific listeners (notified only when
/// specific keys change).
///
/// - Register callbacks that are triggered on any storage modification.
/// - Register callbacks for individual keys, reducing unnecessary notifications.
/// - Listener exceptions don't affect other listeners or storage operations.
/// - Listeners are stored in sets to prevent duplicate registrations.
/// - All listener exceptions are caught and silently ignored to ensure robustness.
/// - When notifying listeners, global listeners are called first, followed by key-specific listeners.
@protected
@internal
mixin ListenableStorage {
  /// Internal storage for global listeners.
  ///
  /// Uses a [Set] to ensure each listener is only registered once.
  final Set<ListenableCallback> _listeners = <ListenableCallback>{};

  /// Internal storage for key-specific listeners.
  ///
  /// Maps storage keys to sets of listeners interested in changes to those
  /// specific keys. Empty sets are automatically removed to prevent memory
  /// leaks.
  final Map<String, Set<ListenableCallback>> _keyedListeners = <String, Set<ListenableCallback>>{};

  /// Returns `true` if there are any listeners registered (global or keyed).
  ///
  /// This property checks both global listeners and all key-specific listener
  /// sets. It returns `true` if at least one listener is registered anywhere.
  bool get hasListeners {
    if (_listeners.isNotEmpty) return true;

    for (final key in _keyedListeners.keys) {
      if (_keyedListeners[key]!.isNotEmpty) return true;
    }
    return false;
  }

  /// Returns `true` if there are any listeners registered for the given [key].
  bool hasKeyListeners(String key) => _keyedListeners[key]?.isNotEmpty == true;

  /// Registers a global listener to be called when any data in the storage
  /// changes.
  ///
  /// The [listener] will be invoked whenever any modification occurs in the
  /// storage, regardless of which key was affected. If the same listener
  /// function is added multiple times, it will only be registered once
  /// (due to set semantics).
  ///
  /// Parameters:
  ///   * [listener] - The callback function to register. Will be called with
  ///     no arguments whenever the storage changes.
  ///
  /// See also:
  /// - [addKeyListener] for listening to specific key changes
  /// - [removeListener] to unregister a listener
  /// - [removeAllListeners] to clear all listeners
  void addListener(ListenableCallback listener) => _listeners.add(listener);

  /// Removes a previously registered global listener.
  ///
  /// If the [listener] is not currently registered, this method has no effect.
  /// After removal, the listener will no longer be notified of storage changes.
  ///
  /// Parameters:
  ///   * [listener] - The callback function to unregister.
  ///
  /// See also:
  /// - [addListener] to register a listener
  /// - [removeKeyListener] to remove a key-specific listener
  void removeListener(ListenableCallback listener) => _listeners.remove(listener);

  /// Registers a listener to be called when data for a specific [key] changes.
  ///
  /// Key-specific listeners are only notified when the specified key is
  /// modified, making them more efficient than global listeners when you only
  /// care about specific data. If the same listener is added multiple times
  /// for the same key, it will only be registered once.
  ///
  /// Parameters:
  ///   * [key] - The storage key to listen to. Must be a non-empty string.
  ///   * [listener] - The callback function to register. Will be called when
  ///     the specified key changes.
  ///
  /// See also:
  /// - [addListener] for listening to all changes
  /// - [removeKeyListener] to unregister a key-specific listener
  /// - [notifyKeyListeners] which triggers these listeners
  void addKeyListener(String key, ListenableCallback listener) =>
      _keyedListeners.putIfAbsent(key, () => <ListenableCallback>{}).add(listener);

  /// Removes a previously registered key-specific listener.
  ///
  /// If the [listener] is not currently registered for the specified [key],
  /// this method has no effect. When the last listener for a key is removed,
  /// the key's listener set is automatically cleaned up to prevent memory
  /// leaks.
  ///
  /// Parameters:
  ///   * [key] - The storage key the listener is registered for.
  ///   * [listener] - The callback function to unregister.
  ///
  /// See also:
  /// - [addKeyListener] to register a key-specific listener
  /// - [removeListener] to remove a global listener
  /// - [removeAllListeners] to clear all listeners
  void removeKeyListener(String key, ListenableCallback listener) {
    _keyedListeners[key]?.remove(listener);
    if (_keyedListeners[key]?.isEmpty == true) {
      _keyedListeners.remove(key);
    }
  }

  /// Removes all listeners registered for a specific [key].
  ///
  /// If no listeners are registered for the given key, this method has no effect.
  /// After calling this method, no listeners for the specified key will be notified
  /// of changes until new listeners are registered.
  ///
  /// Parameters:
  ///   - [key] - The storage key whose listeners should be removed.
  ///
  /// See also:
  ///   - [removeListener] to remove a specific global listener.
  ///   - [removeAllListeners] to clear all listeners.
  void removeAllKeyListeners(String key) => _keyedListeners.remove(key);

  /// Removes all registered listeners, both global and key-specific.
  ///
  /// This method clears all listener registrations, both global listeners and
  /// all key-specific listeners. After calling this method, no listeners will
  /// be notified of storage changes until new listeners are registered.
  ///
  /// This is typically called when closing a storage container to prevent
  /// memory leaks and ensure clean shutdown.
  ///
  /// See also:
  /// - [removeListener] to remove a specific global listener
  /// - [removeKeyListener] to remove a specific key-specific listener
  void removeAllListeners() {
    _listeners.clear();
    _keyedListeners.clear();
  }

  /// Notifies all registered listeners of a change.
  ///
  /// This method invokes all global listeners first, then if a [key] is
  /// provided, it also invokes all listeners registered for that specific key.
  /// Each listener is called within a try-catch block, so exceptions thrown
  /// by one listener don't prevent other listeners from being notified.
  ///
  /// Parameters:
  ///   * [key] - Optional. The specific key that changed. If provided, both
  ///     global listeners and key-specific listeners for this key will be
  ///     notified. If null, only global listeners are notified.
  ///
  /// ## Error Handling
  ///
  /// All listener exceptions are silently caught and ignored. This ensures
  /// that a misbehaving listener cannot:
  /// - Prevent other listeners from being notified
  /// - Break the storage operation that triggered the notification
  /// - Cause cascading failures in the application
  ///
  /// See also:
  /// - [notifyKeyListeners] which is called internally if a key is provided
  /// - [addListener] to register global listeners
  /// - [addKeyListener] to register key-specific listeners
  @protected
  @mustCallSuper
  void notifyListeners([String? key]) {
    if (key != null) notifyKeyListeners(key);
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {
        // Silently ignore listener exceptions to prevent breaking other listeners
      }
    }
  }

  /// Notifies all listeners that are registered for a specific [key].
  ///
  /// This method is called internally by [notifyListeners] when a key is
  /// provided. It can also be called directly to notify only key-specific
  /// listeners without triggering global listeners.
  ///
  /// Each listener is invoked within a try-catch block to ensure exceptions
  /// in one listener don't affect others. If no listeners are registered for
  /// the specified key, this method has no effect.
  ///
  /// Parameters:
  ///   * [key] - The storage key whose listeners should be notified. Must be
  ///     a non-empty string.
  ///
  /// See also:
  /// - [notifyListeners] which calls this method when a key is provided
  /// - [addKeyListener] to register key-specific listeners
  @mustCallSuper
  @internal
  @protected
  void notifyKeyListeners(String key) {
    final listeners = _keyedListeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener();
        } catch (_) {
          // Silently ignore listener exceptions to prevent breaking other listeners
        }
      }
    }
  }
}

/// A mixin that provides functionality for listening..
///
/// This mixin implements the observer pattern, allowing components to be
/// notified when data changes.
@protected
mixin BaseListenable {
  /// A storage for keeping registry of listeners;
  ///
  /// Uses a [Set] to ensure each listener is only registered once.
  final Set<ListenableCallback> _listeners = <ListenableCallback>{};

  /// Returns `true` if there are any listeners registered
  bool get hasListeners => _listeners.isNotEmpty;

  /// Registers a listener to be called when any data changes.
  ///
  /// If the same listener function is added multiple times, it will
  /// only be registered once (due to set semantics).
  ///
  /// Parameters:
  ///   * [listener] - The callback function to register. Will be called with
  ///     no arguments whenever the data changes.
  ///
  /// See also:
  /// - [removeListener] to unregister a listener
  /// - [removeAllListeners] to clear all listeners
  void addListener(ListenableCallback listener) => _listeners.add(listener);

  /// Removes a previously registered listener.
  ///
  /// If the [listener] is not currently registered, this method has no effect.
  /// After removal, the listener will no longer be notified of any changes.
  ///
  /// Parameters:
  ///   * [listener] - The callback function to unregister.
  ///
  /// See also:
  /// - [addListener] to register a listener
  void removeListener(ListenableCallback listener) => _listeners.remove(listener);

  /// Removes all registered listeners..
  ///
  /// After calling this method, no listeners will be notified of
  /// storage changes until new listeners are registered.
  ///
  /// This is typically called when disposing data or closing.
  ///
  /// See also:
  /// - [removeListener] to remove a specific global listener
  void removeAllListeners() => _listeners.clear();

  /// Notifies all registered listeners of a change.
  ///
  /// This method invokes all listeners sequentially.
  /// Each listener is called within a try-catch block, so exceptions thrown
  /// by one listener don't prevent other listeners from being notified.
  ///
  /// ## Error Handling
  ///
  /// All listener exceptions are silently caught and ignored. This ensures
  /// that a misbehaving listener cannot:
  /// - Prevent other listeners from being notified
  /// - Break the storage operation that triggered the notification
  /// - Cause cascading failures in the application
  ///
  /// See also:
  /// - [addListener] to register global listeners
  @protected
  @mustCallSuper
  @internal
  void notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {
        // Silently ignore listener exceptions to prevent breaking other listeners
      }
    }
  }
}

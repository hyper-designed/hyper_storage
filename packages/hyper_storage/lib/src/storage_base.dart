part of 'hyper_storage.dart';

/// An internal base class that implements storage operations with validation and listener support.
///
/// [_StorageBase] provides the foundational implementation of
/// [StorageOperationsApi] with automatic key validation and change notifications.
/// This class serves as the base for [HyperStorage], delegating actual storage
/// operations to a [StorageBackend] while handling cross-cutting concerns like
/// validation and event notifications.
///
/// ## Purpose
///
/// This class exists to:
/// - **Centralize Validation**: Ensure all keys are valid before operations
/// - **Delegate to Backend**: Forward validated operations to the backend
/// - **Manage Notifications**: Notify listeners of all data changes
/// - **Reduce Boilerplate**: Provide reusable implementation for storage operations
///
/// ## Implementation Details
///
/// The class uses a decorator pattern, wrapping a [StorageBackend] and adding
/// validation and notification behavior to each operation. All methods follow
/// this pattern:
///
/// 1. Validate input (keys, values)
/// 2. Delegate to backend
/// 3. Notify listeners (if data changed)
///
/// ## Key Validation Rules
///
/// Keys are validated using [_validateKey] and [_validateKeys]:
/// - Keys cannot be empty strings
/// - Keys cannot consist only of whitespace
/// - Validation occurs before any backend operation
///
/// ## Change Notifications
///
/// The class uses [ListenableStorage] mixin to provide:
/// - Global listeners (notified on any change)
/// - Key-specific listeners (notified when specific keys change)
///
/// Listeners are notified after successful backend operations.
///
/// ## Internal Use
///
/// This class is marked [@internal] and should not be used directly outside
/// the hyper_storage package. It is extended by [HyperStorage] to provide
/// the public API.
///
/// See also:
/// - [HyperStorage] which extends this class
/// - [StorageOperationsApi] for the interface definition
/// - [ListenableStorage] for the listener functionality
/// - [StorageBackend] for the backend interface
abstract class _StorageBase
    with ItemHolderMixin, ListenableStorage, GenericStorageOperationsMixin
    implements StorageOperationsApi {
  /// The storage backend that handles actual data persistence.
  ///
  /// All storage operations are delegated to this backend after validation.
  /// The backend determines where and how data is actually stored (e.g., Hive,
  /// SharedPreferences, in-memory, etc.).
  final StorageBackend backend;

  /// Creates a new [_StorageBase] with the specified backend.
  ///
  /// Parameters:
  ///   * [backend] - The storage backend to delegate operations to. This
  ///     backend should already be initialized before creating this instance.
  _StorageBase(this.backend);

  /// Validates that a single key is acceptable for storage operations.
  ///
  /// This method checks that the key meets basic requirements for storage:
  /// - Must not be empty
  /// - Must not consist only of whitespace characters
  ///
  /// Parameters:
  ///   * [key] - The key to validate.
  ///
  /// Throws:
  ///   * [ArgumentError] if the key is empty.
  ///   * [ArgumentError] if the key contains only whitespace.
  ///
  /// Example:
  /// ```dart
  /// _validateKey('validKey');      // OK
  /// _validateKey('');              // Throws ArgumentError: Key cannot be empty
  /// _validateKey('   ');           // Throws ArgumentError: Key cannot be only whitespace
  /// _validateKey(' key ');         // OK - has non-whitespace content
  /// ```
  void _validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('Key cannot be empty');
    if (key.trim().isEmpty) throw ArgumentError('Key cannot be only whitespace');
  }

  /// Validates that all keys in a collection are acceptable for storage operations.
  ///
  /// This method validates multiple keys using [_validateKey]. If the iterable
  /// is null or empty, no validation is performed (this is not an error). If
  /// any key in the iterable fails validation, an [ArgumentError] is thrown.
  ///
  /// Parameters:
  ///   * [keys] - Optional iterable of keys to validate. Can be null or empty.
  ///
  /// Throws:
  ///   * [ArgumentError] if any key is empty or consists only of whitespace.
  ///
  /// Example:
  /// ```dart
  /// _validateKeys(['key1', 'key2']);       // OK
  /// _validateKeys(null);                   // OK - no validation needed
  /// _validateKeys([]);                     // OK - no validation needed
  /// _validateKeys(['valid', '']);          // Throws ArgumentError
  /// _validateKeys(['valid', '   ']);       // Throws ArgumentError
  /// ```
  void _validateKeys(Iterable<String>? keys) {
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      _validateKey(key);
    }
  }

  @override
  Future<bool> containsKey(String key) {
    _validateKey(key);
    return backend.containsKey(key);
  }

  @override
  Future<Map<String, dynamic>> getAll([Iterable<String>? allowList]) {
    _validateKeys(allowList);
    return backend.getAll(allowList);
  }

  @override
  Future<bool?> getBool(String key) {
    _validateKey(key);
    return backend.getBool(key);
  }

  @override
  Future<DateTime?> getDateTime(String key, {bool isUtc = false}) {
    _validateKey(key);
    return backend.getDateTime(key, isUtc: isUtc);
  }

  @override
  Future<double?> getDouble(String key) {
    _validateKey(key);
    return backend.getDouble(key);
  }

  @override
  Future<Duration?> getDuration(String key) {
    _validateKey(key);
    return backend.getDuration(key);
  }

  @override
  Future<int?> getInt(String key) {
    _validateKey(key);
    return backend.getInt(key);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) {
    _validateKey(key);
    return backend.getJson(key);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) {
    _validateKey(key);
    return backend.getJsonList(key);
  }

  @override
  Future<Set<String>> getKeys() => backend.getKeys();

  @override
  Future<String?> getString(String key) {
    _validateKey(key);
    return backend.getString(key);
  }

  @override
  Future<List<String>?> getStringList(String key) {
    _validateKey(key);
    return backend.getStringList(key);
  }

  @override
  Future<bool> get isEmpty => backend.isEmpty;

  @override
  Future<bool> get isNotEmpty => backend.isNotEmpty;

  @override
  Future<void> remove(String key) async {
    _validateKey(key);
    await backend.remove(key);
    notifyListeners(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    _validateKeys(keys);
    await backend.removeAll(keys);
    for (final key in keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setAll(Map<String, dynamic> values) async {
    _validateKeys(values.keys);
    await backend.setAll(values);
    for (final key in values.keys) {
      notifyKeyListeners(key);
    }
    notifyListeners();
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _validateKey(key);
    await backend.setBool(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    _validateKey(key);
    await backend.setDateTime(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _validateKey(key);
    await backend.setDouble(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setDuration(String key, Duration value) async {
    _validateKey(key);
    await backend.setDuration(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    _validateKey(key);
    await backend.setInt(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _validateKey(key);
    await backend.setJson(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    _validateKey(key);
    await backend.setJsonList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _validateKey(key);
    await backend.setString(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _validateKey(key);
    await backend.setStringList(key, value);
    notifyListeners(key);
  }

  @override
  Future<void> clear() async {
    await backend.clear();
    notifyListeners();
    removeAllListeners();
  }

  @override
  Future<void> close() => backend.close();
}

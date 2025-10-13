import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// An abstract base class for creating broadcast streams with managed lifecycle.
///
/// [ManagedStream] provides a robust foundation for implementing streams that:
/// - Support multiple concurrent listeners (broadcast stream)
/// - Automatically cache and emit the latest value to new listeners
/// - Provide lifecycle hooks for resource management
/// - Handle subscription counting and cleanup automatically
///
/// ## Key Features
///
/// ### Automatic Value Caching
/// Uses [BehaviorSubject] internally to automatically cache the latest emitted
/// value. New listeners immediately receive this cached value upon subscription.
///
/// ### Lifecycle Management
/// Provides three lifecycle hooks that subclasses can override:
/// - [onFirstListener]: Called when the first subscription is added (count: 0 → 1)
/// - [onNewListener]: Called every time a new subscription is added
/// - [onNoListeners]: Called when the last subscription is cancelled (count: 1 → 0)
///
/// These hooks enable efficient resource management by allowing subclasses to
/// activate/deactivate expensive operations only when needed.
///
/// ### Thread-Safe Disposal
/// Properly handles disposal even with active subscriptions, preventing negative
/// subscription counts and ensuring clean resource cleanup.
///
/// ## Usage Example
///
/// ```dart
/// class ValueStream extends ManagedStream<int> {
///   Timer? _timer;
///   int _counter = 0;
///
///   @override
///   void onFirstListener() {
///     // Start generating values only when someone is listening
///     _timer = Timer.periodic(Duration(seconds: 1), (_) {
///       emit(++_counter);
///     });
///   }
///
///   @override
///   void onNoListeners() {
///     // Stop generating values when no one is listening
///     _timer?.cancel();
///     _timer = null;
///   }
/// }
///
/// // Usage
/// final stream = ValueStream();
/// final sub1 = stream.listen(print); // Triggers onFirstListener
/// final sub2 = stream.listen(print); // Gets cached value immediately
/// await sub1.cancel();
/// await sub2.cancel(); // Triggers onNoListeners
/// stream.dispose(); // Clean up
/// ```
///
/// ## Implementation Notes
///
/// - Subclasses should call [emit] to add values to the stream
/// - The [dispose] method must be called to clean up resources
/// - If overriding [dispose], call `super.dispose()` first
/// - The stream becomes unusable after disposal
///
/// Type parameter:
/// - [E]: The type of values emitted by this stream
@internal
abstract class ManagedStream<E> with Stream<E> {
  bool _isClosed = false;

  /// Whether this stream has been disposed and is no longer usable.
  ///
  /// Once disposed, attempts to listen will throw a [StateError], and
  /// attempts to emit values will be silently ignored.
  bool get isClosed => _isClosed;

  late final BehaviorSubject<E> _streamController = BehaviorSubject<E>();

  /// Protected getter for accessing the stream controller from subclasses.
  ///
  /// This allows subclasses to check if a value has been cached using
  /// `streamController.hasValue` to implement custom error handling logic.
  @protected
  BehaviorSubject<E> get streamController => _streamController;

  int _subscriptionCount = 0;

  /// Lifecycle hook called when the first listener subscribes to this stream.
  ///
  /// This is called when the subscription count transitions from 0 to 1.
  /// Override this method to activate expensive resources (e.g., timers,
  /// database connections, network listeners) only when needed.
  ///
  /// This method is called before [onNewListener] and before the subscription
  /// is returned to the caller.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onFirstListener() {
  ///   _startPolling();
  ///   _connectToWebSocket();
  /// }
  /// ```
  void onFirstListener() {
    // Override in implementing class
  }

  /// Lifecycle hook called when the last listener unsubscribes from this stream.
  ///
  /// This is called when the subscription count transitions from 1 to 0.
  /// Override this method to deactivate expensive resources and perform cleanup.
  ///
  /// This method is also called during [dispose] if there are active subscriptions.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onNoListeners() {
  ///   _stopPolling();
  ///   _disconnectFromWebSocket();
  /// }
  /// ```
  void onNoListeners() {
    // Override in implementing class
  }

  /// Lifecycle hook called every time a new listener subscribes to this stream.
  ///
  /// Unlike [onFirstListener] which is only called once when going from 0 to 1
  /// listeners, this is called for every new subscription regardless of count.
  ///
  /// This is called after the subscription count is incremented but before the
  /// subscription is returned to the caller. The [BehaviorSubject] will emit
  /// its cached value after this method returns.
  ///
  /// This is useful for triggering a fresh data fetch for each new listener
  /// to ensure they receive the most up-to-date value in addition to the
  /// cached value.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onNewListener() {
  ///   _fetchLatestValue(); // Fetch fresh data for this listener
  /// }
  /// ```
  void onNewListener() {}

  /// Subscribes to this stream and returns a [StreamSubscription].
  ///
  /// This method manages the subscription lifecycle automatically:
  /// 1. Throws [StateError] if the stream has been disposed
  /// 2. Calls [onFirstListener] if this is the first subscription (count: 0 → 1)
  /// 3. Increments the subscription count
  /// 4. Calls [onNewListener] for this new subscription
  /// 5. Returns a subscription that receives the cached value immediately,
  ///    then any subsequent values
  /// 6. Sets up automatic cleanup via [StreamSubscription.onDone] that:
  ///    - Decrements the subscription count when cancelled
  ///    - Calls [onNoListeners] if this was the last subscription (count: 1 → 0)
  ///
  /// The returned subscription receives:
  /// - The latest cached value immediately (if one exists)
  /// - All subsequent values emitted via [emit]
  ///
  /// Parameters:
  /// - [onData]: Called for each data event received
  /// - [onError]: Called when an error is emitted
  /// - [onDone]: Called when the subscription is cancelled or stream is closed
  /// - [cancelOnError]: Whether to cancel the subscription on first error
  ///
  /// Throws:
  /// - [StateError] if the stream has been disposed
  ///
  /// Example:
  /// ```dart
  /// final subscription = stream.listen(
  ///   (value) => print('Received: $value'),
  ///   onError: (error) => print('Error: $error'),
  ///   onDone: () => print('Done'),
  /// );
  ///
  /// // Later...
  /// await subscription.cancel();
  /// ```
  @override
  @mustCallSuper
  StreamSubscription<E> listen(
    void Function(E event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Guard against listening to a disposed holder
    if (_isClosed) {
      throw StateError('Cannot listen to a disposed ItemHolder');
    }
    // Lazy activation: add parent listener on first subscription
    if (_subscriptionCount == 0) onFirstListener();

    _subscriptionCount++;

    onNewListener();

    // BehaviorSubject automatically emits cached value to new listeners
    final subscription = _streamController.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    // Track subscription lifecycle for cleanup
    subscription.onDone(() {
      _subscriptionCount--;
      // Lazy deactivation: remove parent listener when last subscription ends
      if (_subscriptionCount == 0) onNoListeners();
    });

    return subscription;
  }

  /// Emits a value to all active listeners.
  ///
  /// This value is cached by the internal [BehaviorSubject] and will be
  /// immediately emitted to any future listeners that subscribe.
  ///
  /// If the stream has been disposed ([isClosed] is true), this method
  /// does nothing silently.
  ///
  /// Subclasses should call this method whenever they have a new value to emit.
  ///
  /// Example:
  /// ```dart
  /// class Counter extends ManagedStream<int> {
  ///   int _value = 0;
  ///
  ///   void increment() {
  ///     emit(++_value);
  ///   }
  /// }
  /// ```
  @protected
  void emit(E event) {
    if (_isClosed) return;
    _streamController.add(event);
  }

  /// Emits an error to all active listeners.
  ///
  /// Unlike [emit], errors are NOT cached. They are only delivered to
  /// currently active listeners and will not be replayed to future listeners.
  ///
  /// If the stream has been disposed ([isClosed] is true), this method
  /// does nothing silently.
  ///
  /// Parameters:
  /// - [error]: The error object to emit
  /// - [stackTrace]: Optional stack trace associated with the error
  ///
  /// Example:
  /// ```dart
  /// class DataStream extends ManagedStream<String> {
  ///   Future<void> fetchData() async {
  ///     try {
  ///       final data = await api.fetch();
  ///       emit(data);
  ///     } catch (error, stackTrace) {
  ///       emitError(error, stackTrace);
  ///     }
  ///   }
  /// }
  /// ```
  @protected
  void emitError(Object error, [StackTrace? stackTrace]) {
    if (_isClosed) return;
    _streamController.addError(error, stackTrace);
  }

  /// Disposes this stream and releases all resources.
  ///
  /// After disposal:
  /// - The stream cannot be listened to (throws [StateError])
  /// - All active subscriptions are cancelled
  /// - [emit] and [emitError] become no-ops
  /// - [isClosed] returns true
  ///
  /// If there are active subscriptions when dispose is called:
  /// 1. [onNoListeners] is called to clean up resources
  /// 2. The internal stream is closed, triggering onDone for all subscriptions
  /// 3. Each subscription's onDone callback naturally decrements the count
  ///
  /// This design prevents negative subscription counts that could occur if
  /// the count was reset to 0 before closing the stream.
  ///
  /// Subclasses that override this method MUST call `super.dispose()` to
  /// ensure proper cleanup of the base class resources.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   super.dispose(); // Always call first
  ///   _timer?.cancel();
  ///   _connection?.close();
  /// }
  /// ```
  @mustCallSuper
  void dispose() {
    // Remove the internal parent listener if there are active subscriptions
    if (_subscriptionCount > 0) {
      onNoListeners();
      // Don't reset count - let onDone callbacks decrement naturally to avoid negative count
    }
    // Close the BehaviorSubject (this triggers onDone for all active subscriptions)
    _streamController.close();
    _isClosed = true;
  }
}

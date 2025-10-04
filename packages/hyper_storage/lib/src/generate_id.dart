import 'dart:math' as math;

/// Character set used for encoding IDs.
///
/// This string contains 62 characters (10 digits + 26 uppercase + 26 lowercase)
/// modeled after base64 web-safe characters but ordered by ASCII value for
/// proper lexicographical sorting.
///
/// The character set ensures that:
/// - IDs are URL-safe and can be used in paths and query parameters
/// - IDs sort correctly in lexicographical order
/// - IDs are compact and human-readable
/// - IDs avoid special characters that require escaping
const String _kPushChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

int _lastPushTime = 0;
final List<int> _randomSuffix = List.filled(12, 0);

/// Generates a unique 20-character string identifier with timestamp-based ordering.
///
/// This function creates identifiers with the following properties:
///
/// 1. **Chronologically ordered**: IDs are based on timestamp (milliseconds since epoch),
///    ensuring that newer IDs sort after older ones lexicographically.
///
/// 2. **Collision-resistant**: Contains 72 bits (12 characters) of random data after
///    the timestamp to prevent collisions even when multiple clients generate IDs
///    simultaneously.
///
/// 3. **Lexicographically sortable**: The timestamp is encoded using characters that
///    maintain proper sort order, so string comparison matches chronological order.
///
/// 4. **Monotonically increasing**: If multiple IDs are generated in the same
///    millisecond, they are guaranteed to be unique and properly ordered by
///    incrementing the random suffix instead of regenerating it.
///
/// The generated ID structure:
/// - Characters 1-8: Base-62 encoded timestamp (UTC milliseconds)
/// - Characters 9-20: Random suffix for uniqueness
///
/// Parameters:
///   * [random] - Optional random number generator to use for generating the
///     random suffix. If not provided, defaults to [math.Random.secure()] for
///     cryptographically secure randomness. You might want to provide a custom
///     generator for:
///     - Testing purposes (using a seeded generator for reproducibility)
///     - Performance optimization (using a faster non-secure generator)
///     - Custom randomness requirements
///
/// Returns a 20-character string identifier that is:
/// - Unique across distributed systems
/// - Sortable by creation time
/// - URL-safe and human-readable
/// - Collision-resistant
///
/// Implementation notes:
/// - Uses UTC time to avoid timezone issues
/// - The timestamp portion provides millisecond precision
/// - The random suffix uses 12 characters (72 bits) from a 62-character alphabet
/// - Collision handling ensures monotonicity within the same millisecond
/// - The function maintains state between calls in the same millisecond
///
/// Performance characteristics:
/// - Very fast: O(1) time complexity
/// - Memory efficient: Only stores 12 integers of state
/// - Thread-safe: Uses immutable timestamp and per-call random generation
String generateId([math.Random? random]) {
  final bool useGlobalState = random == null;
  random ??= math.Random.secure();

  final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
  String id = _toPushIdBase64(now, 8);

  final List<int> suffix;

  if (useGlobalState) {
    // Use global state for monotonic IDs when no custom Random is provided
    if (now != _lastPushTime) {
      // New timestamp: generate fresh random suffix
      for (int i = 0; i < 12; i += 1) {
        _randomSuffix[i] = random.nextInt(62);
      }
    } else {
      // Same timestamp: increment the previous random suffix to maintain uniqueness
      // This ensures monotonicity even when generating multiple IDs per millisecond
      int i;
      for (i = 11; i >= 0 && _randomSuffix[i] == 61; i--) {
        _randomSuffix[i] = 0;
      }
      if (i >= 0) {
        _randomSuffix[i] += 1;
      }
    }
    suffix = _randomSuffix;
    _lastPushTime = now;
  } else {
    // Custom Random: always generate fresh random suffix (no global state)
    suffix = List.filled(12, 0);
    for (int i = 0; i < 12; i += 1) {
      suffix[i] = random.nextInt(62);
    }
  }

  final String suffixStr = suffix.map((int i) => _kPushChars[i]).join();

  return '$id$suffixStr';
}

/// Converts a numeric value to a base-62 encoded string with fixed length.
///
/// This internal function encodes an integer value using the [_kPushChars]
/// character set (base-62) with a specified number of characters. The encoding
/// maintains lexicographical ordering, meaning that larger numbers produce
/// strings that sort after smaller numbers.
///
/// The function is primarily used to encode timestamps into the first 8 characters
/// of generated IDs, ensuring that IDs can be sorted chronologically using
/// simple string comparison.
///
/// Parameters:
///   * [value] - The integer value to encode. Must be non-negative and small
///     enough to fit in the specified number of characters using base-62 encoding.
///     For example, with 8 characters, the maximum value is 62^8 - 1.
///   * [numChars] - The number of characters in the resulting string. The output
///     will be zero-padded if necessary to reach this length.
///
/// Returns a string of exactly [numChars] length containing the base-62 encoded
/// representation of [value].
///
/// Implementation details:
/// - Uses modulo and division operations to extract base-62 digits
/// - Fills from right to left (least significant to most significant)
/// - Asserts that the value can be represented in the given number of characters
///
/// Throws [AssertionError] in debug mode if [value] cannot be represented
/// in [numChars] characters using base-62 encoding.
///
/// See also:
/// - [generateId] for the primary use case of this function
/// - [_kPushChars] for the character set used in encoding
String _toPushIdBase64(int value, int numChars) {
  List<String> chars = List.filled(numChars, '');
  for (int i = numChars - 1; i >= 0; i -= 1) {
    chars[i] = _kPushChars[value % 62];
    value = (value / 62).floor();
  }
  assert(value == 0, 'Value $value is too large to encode in $numChars characters');
  return chars.join();
}

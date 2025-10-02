import 'dart:convert';

import 'package:meta/meta.dart';

/// Attempts to decode a JSON string with safe error handling.
///
/// If decoding is successful, the resulting object is returned.
/// If decoding fails (e.g., due to invalid JSON), null is returned.
@internal
Object? tryJsonDecode(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

import 'dart:convert';
import 'package:meta/meta.dart';

/// Attempts to decode a JSON string into a Dart object, returning null on failure.
@internal
Object? tryJsonDecode(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

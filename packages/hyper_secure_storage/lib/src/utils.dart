import 'dart:convert';

Object? tryJsonDecode(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

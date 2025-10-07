// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

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

@internal
void checkEnumType<E extends Object>(List<Enum> enumValues) {
  if (enumValues is List<E>) {
    if (enumValues.isEmpty) {
      throw ArgumentError('The enumValues parameter cannot be empty.');
    }
    if (enumValues.first.runtimeType != E) {
      throw ArgumentError('The enumValues parameter must be of type $E. Found: ${enumValues.first.runtimeType}.');
    }
  } else {
    throw ArgumentError('The enumValues parameter must be of type List<$E>. Found: ${enumValues.runtimeType}.');
  }
}

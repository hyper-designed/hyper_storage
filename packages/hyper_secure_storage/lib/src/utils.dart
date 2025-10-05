// Copyright © 2025 Hyperdesigned. All rights reserved.
// Use of this source code is governed by a BSD license that can be
// found in the LICENSE file.

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

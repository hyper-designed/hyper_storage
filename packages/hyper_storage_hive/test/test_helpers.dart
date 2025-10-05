import 'dart:io';

import 'package:hive_ce/hive.dart';

/// Sets up Hive with a temporary directory for testing.
Future<Directory> setupHive() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
  return tempDir;
}

/// Cleans up Hive and deletes temporary directory.
Future<void> cleanupHive(Directory tempDir) async {
  await Hive.close();
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}

/// Generates a unique box name for testing to avoid conflicts.
String uniqueBoxName([String prefix = 'test']) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}

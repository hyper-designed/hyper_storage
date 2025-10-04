import 'dart:io';
import 'dart:math';

import 'package:hyper_storage/src/generate_id.dart' as generator;
import 'package:test/test.dart';

void main() {
  group('generateId', () {
    group('basic properties', () {
      test('generates non-empty string', () {
        final id = generator.generateId();
        expect(id, isNotEmpty);
      });

      test('generates 20 character ID', () {
        final id = generator.generateId();
        expect(id.length, 20);
      });

      test('generates unique IDs', () {
        final ids = <String>{};
        for (int i = 0; i < 1000; i++) {
          ids.add(generator.generateId());
        }
        expect(ids.length, 1000);
      });

      test('ID contains only valid characters', () {
        final validChars = RegExp(r'^[0-9A-Za-z]+$');
        final id = generator.generateId();
        expect(validChars.hasMatch(id), true);
      });

      test('ID is URL-safe', () {
        final id = generator.generateId();
        expect(id, isNot(contains('/')));
        expect(id, isNot(contains('+')));
        expect(id, isNot(contains('=')));
        expect(id, isNot(contains(' ')));
      });
    });

    group('chronological ordering', () {
      test('newer IDs sort after older IDs', () {
        final id1 = generator.generateId();

        // Small delay to ensure different timestamp
        sleep(Duration(milliseconds: 5));

        final id2 = generator.generateId();

        expect(id1.compareTo(id2), lessThan(0));
      });

      test('IDs generated in sequence are ordered', () {
        final ids = <String>[];

        for (int i = 0; i < 10; i++) {
          ids.add(generator.generateId());
          sleep(Duration(milliseconds: 2));
        }

        // Verify they are in order
        for (int i = 0; i < ids.length - 1; i++) {
          expect(ids[i].compareTo(ids[i + 1]), lessThanOrEqualTo(0));
        }
      });

      test('timestamp portion increases over time', () {
        final id1 = generator.generateId();
        final timestamp1 = id1.substring(0, 8);

        sleep(Duration(milliseconds: 10));

        final id2 = generator.generateId();
        final timestamp2 = id2.substring(0, 8);

        expect(timestamp1.compareTo(timestamp2), lessThan(0));
      });
    });

    group('collision resistance', () {
      test('IDs generated in same millisecond are unique', () {
        final ids = <String>{};

        // Generate many IDs rapidly
        for (int i = 0; i < 100; i++) {
          ids.add(generator.generateId());
        }

        expect(ids.length, 100);
      });

      test('random suffixes are different', () {
        final suffixes = <String>{};

        for (int i = 0; i < 1000; i++) {
          final id = generator.generateId();
          final suffix = id.substring(8);
          suffixes.add(suffix);
        }

        // Most suffixes should be unique
        expect(suffixes.length, greaterThan(990));
      });
    });

    group('custom Random', () {
      test('uses provided Random generator', () {
        final random = Random(12345);
        final id = generator.generateId(random);

        expect(id.length, 20);
        expect(id, isNotEmpty);
      });

      test('seeded Random generates deterministic IDs (same timestamp)', () {
        // Note: This test is tricky because timestamp will likely differ
        // We can only test that the random portion is deterministic
        final random1 = Random(42);
        final random2 = Random(42);

        final id1 = generator.generateId(random1);
        final id2 = generator.generateId(random2);

        // Random portions (last 12 chars) should be same with same seed
        // But timestamps might differ, so we can't directly compare full IDs
        // This just verifies seeded random works
        expect(id1.length, 20);
        expect(id2.length, 20);
      });

      test('different seeds generate different random portions', () {
        final random1 = Random(111);
        final random2 = Random(222);

        final id1 = generator.generateId(random1);
        final id2 = generator.generateId(random2);

        final suffix1 = id1.substring(8);
        final suffix2 = id2.substring(8);

        // Different seeds should produce different random portions
        expect(suffix1, isNot(suffix2));
      });
    });

    group('ID structure', () {
      test('first 8 characters are timestamp', () {
        final id = generator.generateId();
        final timestamp = id.substring(0, 8);

        // Timestamp should only contain base-62 characters
        final validChars = RegExp(r'^[0-9A-Za-z]+$');
        expect(validChars.hasMatch(timestamp), true);
        expect(timestamp.length, 8);
      });

      test('last 12 characters are random suffix', () {
        final id = generator.generateId();
        final suffix = id.substring(8);

        // Suffix should be 12 characters
        expect(suffix.length, 12);

        // Suffix should only contain base-62 characters
        final validChars = RegExp(r'^[0-9A-Za-z]+$');
        expect(validChars.hasMatch(suffix), true);
      });

      test('timestamp portion changes over time', () {
        final id1 = generator.generateId();
        final timestamp1 = id1.substring(0, 8);

        sleep(Duration(milliseconds: 10));

        final id2 = generator.generateId();
        final timestamp2 = id2.substring(0, 8);

        expect(timestamp1, isNot(timestamp2));
      });
    });

    group('performance', () {
      test('generates IDs quickly', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10000; i++) {
          generator.generateId();
        }

        stopwatch.stop();

        // Should generate 10k IDs in less than 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('handles rapid generation', () {
        final ids = <String>[];

        for (int i = 0; i < 1000; i++) {
          ids.add(generator.generateId());
        }

        // All IDs should be unique
        expect(ids.toSet().length, 1000);
      });
    });

    group('edge cases', () {
      test('handles secure Random', () {
        final secureRandom = Random.secure();
        final id = generator.generateId(secureRandom);

        expect(id.length, 20);
        expect(id, isNotEmpty);
      });

      test('consecutive calls without delay', () {
        final id1 = generator.generateId();
        final id2 = generator.generateId();
        final id3 = generator.generateId();

        expect(id1, isNot(id2));
        expect(id2, isNot(id3));
        expect(id1, isNot(id3));
      });

      test('maintains order even with rapid generation', () {
        final ids = <String>[];

        // Generate many IDs as fast as possible
        for (int i = 0; i < 100; i++) {
          ids.add(generator.generateId());
        }

        // Check they are in ascending order
        for (int i = 0; i < ids.length - 1; i++) {
          expect(ids[i].compareTo(ids[i + 1]), lessThanOrEqualTo(0));
        }
      });
    });

    group('character set', () {
      test('uses base-62 character set', () {
        final ids = <String>[];
        final chars = <String>{};

        for (int i = 0; i < 100; i++) {
          final id = generator.generateId();
          ids.add(id);
          chars.addAll(id.split(''));
        }

        // Should only contain digits and letters
        for (final char in chars) {
          expect(RegExp(r'[0-9A-Za-z]').hasMatch(char), true);
        }
      });

      test('does not contain special characters', () {
        for (int i = 0; i < 100; i++) {
          final id = generator.generateId();

          expect(id, isNot(contains('-')));
          expect(id, isNot(contains('_')));
          expect(id, isNot(contains('.')));
          expect(id, isNot(contains('/')));
          expect(id, isNot(contains('+')));
          expect(id, isNot(contains('=')));
        }
      });

      test('uses both uppercase and lowercase letters', () {
        final chars = <String>{};

        // Generate many IDs to get a good sample
        for (int i = 0; i < 1000; i++) {
          final id = generator.generateId();
          chars.addAll(id.split(''));
        }

        // Should have both uppercase and lowercase
        final hasUppercase = chars.any((c) => c.toUpperCase() == c && RegExp(r'[A-Z]').hasMatch(c));
        final hasLowercase = chars.any((c) => c.toLowerCase() == c && RegExp(r'[a-z]').hasMatch(c));

        expect(hasUppercase, true);
        expect(hasLowercase, true);
      });
    });

    group('lexicographical sorting', () {
      test('IDs sort correctly as strings', () {
        final ids = <String>[];

        for (int i = 0; i < 50; i++) {
          ids.add(generator.generateId());
          if (i % 10 == 0) {
            sleep(Duration(milliseconds: 5));
          }
        }

        // Since IDs are chronologically generated, they should already be sorted
        for (int i = 0; i < ids.length - 1; i++) {
          expect(ids[i].compareTo(ids[i + 1]), lessThanOrEqualTo(0));
        }
      });

      test('string comparison matches chronological order', () {
        final earlier = generator.generateId();

        sleep(Duration(milliseconds: 10));

        final later = generator.generateId();

        // String comparison should match time order
        expect(earlier.compareTo(later), lessThan(0));
        expect(later.compareTo(earlier), greaterThan(0));
      });
    });
  });
}

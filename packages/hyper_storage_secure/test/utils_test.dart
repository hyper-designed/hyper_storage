import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_storage_secure/src/utils.dart';

void main() {
  group('tryJsonDecode', () {
    test('decodes valid JSON object', () {
      final result = tryJsonDecode('{"name":"test","value":42}');
      expect(result, {'name': 'test', 'value': 42});
    });

    test('decodes valid JSON array', () {
      final result = tryJsonDecode('[1,2,3]');
      expect(result, [1, 2, 3]);
    });

    test('decodes nested JSON', () {
      final result = tryJsonDecode('{"user":{"id":1,"name":"Alice"}}');
      expect(result, {
        'user': {'id': 1, 'name': 'Alice'},
      });
    });

    test('decodes empty JSON object', () {
      final result = tryJsonDecode('{}');
      expect(result, {});
    });

    test('decodes empty JSON array', () {
      final result = tryJsonDecode('[]');
      expect(result, []);
    });

    test('returns null for invalid JSON', () {
      final result = tryJsonDecode('not json');
      expect(result, isNull);
    });

    test('returns null for incomplete JSON', () {
      final result = tryJsonDecode('{"incomplete":');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = tryJsonDecode('');
      expect(result, isNull);
    });

    test('returns null for plain string without quotes', () {
      final result = tryJsonDecode('hello');
      expect(result, isNull);
    });

    test('decodes JSON string', () {
      final result = tryJsonDecode('"hello world"');
      expect(result, 'hello world');
    });

    test('decodes JSON boolean', () {
      expect(tryJsonDecode('true'), true);
      expect(tryJsonDecode('false'), false);
    });

    test('decodes JSON number', () {
      expect(tryJsonDecode('42'), 42);
      expect(tryJsonDecode('3.14'), 3.14);
    });

    test('decodes JSON null', () {
      final result = tryJsonDecode('null');
      expect(result, isNull);
    });

    test('handles complex nested structures', () {
      final json = '{"users":[{"id":1,"active":true},{"id":2,"active":false}],"count":2}';
      final result = tryJsonDecode(json);
      expect(result, {
        'users': [
          {'id': 1, 'active': true},
          {'id': 2, 'active': false},
        ],
        'count': 2,
      });
    });
  });
}

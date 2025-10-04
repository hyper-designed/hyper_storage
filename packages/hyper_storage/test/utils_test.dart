import 'package:hyper_storage/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('tryJsonDecode', () {
    group('valid JSON', () {
      test('decodes simple JSON object', () {
        final result = tryJsonDecode('{"key":"value"}');
        expect(result, isA<Map>());
        expect((result as Map)['key'], 'value');
      });

      test('decodes JSON array', () {
        final result = tryJsonDecode('[1,2,3]');
        expect(result, isA<List>());
        expect((result as List).length, 3);
        expect(result, [1, 2, 3]);
      });

      test('decodes simple string', () {
        final result = tryJsonDecode('"hello"');
        expect(result, 'hello');
      });

      test('decodes number', () {
        final result = tryJsonDecode('42');
        expect(result, 42);
      });

      test('decodes boolean true', () {
        final result = tryJsonDecode('true');
        expect(result, true);
      });

      test('decodes boolean false', () {
        final result = tryJsonDecode('false');
        expect(result, false);
      });

      test('decodes null', () {
        final result = tryJsonDecode('null');
        expect(result, null);
      });

      test('decodes nested JSON', () {
        final json = '{"user":{"name":"John","age":30},"active":true}';
        final result = tryJsonDecode(json);
        expect(result, isA<Map>());

        final map = result as Map;
        expect(map['user'], isA<Map>());
        expect((map['user'] as Map)['name'], 'John');
        expect((map['user'] as Map)['age'], 30);
        expect(map['active'], true);
      });

      test('decodes array of objects', () {
        final json = '[{"id":1},{"id":2}]';
        final result = tryJsonDecode(json);
        expect(result, isA<List>());

        final list = result as List;
        expect(list.length, 2);
        expect((list[0] as Map)['id'], 1);
        expect((list[1] as Map)['id'], 2);
      });

      test('decodes empty object', () {
        final result = tryJsonDecode('{}');
        expect(result, isA<Map>());
        expect((result as Map).isEmpty, true);
      });

      test('decodes empty array', () {
        final result = tryJsonDecode('[]');
        expect(result, isA<List>());
        expect((result as List).isEmpty, true);
      });
    });

    group('invalid JSON', () {
      test('returns null for malformed JSON', () {
        final result = tryJsonDecode('{invalid}');
        expect(result, null);
      });

      test('returns null for incomplete JSON object', () {
        final result = tryJsonDecode('{"key":"value"');
        expect(result, null);
      });

      test('returns null for incomplete JSON array', () {
        final result = tryJsonDecode('[1,2,3');
        expect(result, null);
      });

      test('returns null for invalid string', () {
        final result = tryJsonDecode('not json at all');
        expect(result, null);
      });

      test('returns null for empty string', () {
        final result = tryJsonDecode('');
        expect(result, null);
      });

      test('returns null for unquoted string', () {
        final result = tryJsonDecode('hello');
        expect(result, null);
      });

      test('returns null for single quote strings', () {
        final result = tryJsonDecode("{'key':'value'}");
        expect(result, null);
      });

      test('returns null for trailing comma', () {
        final result = tryJsonDecode('{"key":"value",}');
        expect(result, null);
      });

      test('returns null for missing quotes on key', () {
        final result = tryJsonDecode('{key:"value"}');
        expect(result, null);
      });

      test('returns null for extra characters after JSON', () {
        final result = tryJsonDecode('{"key":"value"}extra');
        expect(result, null);
      });

      test('returns null for comments in JSON', () {
        final result = tryJsonDecode('{"key":"value"} // comment');
        expect(result, null);
      });
    });

    group('special cases', () {
      test('handles whitespace in JSON', () {
        final result = tryJsonDecode('  {  "key"  :  "value"  }  ');
        expect(result, isA<Map>());
        expect((result as Map)['key'], 'value');
      });

      test('handles newlines in JSON', () {
        final json = '''
{
  "key": "value",
  "number": 42
}
''';
        final result = tryJsonDecode(json);
        expect(result, isA<Map>());
        final map = result as Map;
        expect(map['key'], 'value');
        expect(map['number'], 42);
      });

      test('handles escaped characters', () {
        final result = tryJsonDecode('{"text":"line1\\nline2"}');
        expect(result, isA<Map>());
        expect((result as Map)['text'], 'line1\nline2');
      });

      test('handles unicode characters', () {
        final result = tryJsonDecode('{"text":"Hello 世界"}');
        expect(result, isA<Map>());
        expect((result as Map)['text'], 'Hello 世界');
      });

      test('handles escaped unicode', () {
        final result = tryJsonDecode('{"text":"\\u0048\\u0065\\u006C\\u006C\\u006F"}');
        expect(result, isA<Map>());
        expect((result as Map)['text'], 'Hello');
      });

      test('handles large numbers', () {
        final result = tryJsonDecode('{"big":9007199254740991}');
        expect(result, isA<Map>());
        expect((result as Map)['big'], 9007199254740991);
      });

      test('handles negative numbers', () {
        final result = tryJsonDecode('{"negative":-42}');
        expect(result, isA<Map>());
        expect((result as Map)['negative'], -42);
      });

      test('handles decimal numbers', () {
        final result = tryJsonDecode('{"decimal":3.14159}');
        expect(result, isA<Map>());
        expect((result as Map)['decimal'], 3.14159);
      });

      test('handles scientific notation', () {
        final result = tryJsonDecode('{"scientific":1.23e10}');
        expect(result, isA<Map>());
        expect((result as Map)['scientific'], 1.23e10);
      });

      test('handles special characters in strings', () {
        final result = tryJsonDecode('{"special":"!@#\$%^&*()"}');
        expect(result, isA<Map>());
        expect((result as Map)['special'], '!@#\$%^&*()');
      });
    });

    group('edge cases', () {
      test('handles very long JSON string', () {
        final longArray = List.generate(1000, (i) => i);
        final jsonString = '[${longArray.join(',')}]';

        final result = tryJsonDecode(jsonString);
        expect(result, isA<List>());
        expect((result as List).length, 1000);
      });

      test('handles deeply nested JSON', () {
        final nested = '{"a":{"b":{"c":{"d":{"e":"value"}}}}}';
        final result = tryJsonDecode(nested);
        expect(result, isA<Map>());

        var current = result as Map;
        expect(current['a'], isA<Map>());
        current = current['a'];
        expect(current['b'], isA<Map>());
        current = current['b'];
        expect(current['c'], isA<Map>());
        current = current['c'];
        expect(current['d'], isA<Map>());
        current = current['d'];
        expect(current['e'], 'value');
      });

      test('handles mixed types in array', () {
        final result = tryJsonDecode('[1,"string",true,null,{"key":"value"}]');
        expect(result, isA<List>());

        final list = result as List;
        expect(list[0], 1);
        expect(list[1], 'string');
        expect(list[2], true);
        expect(list[3], null);
        expect(list[4], isA<Map>());
      });
    });

    group('error resilience', () {
      test('does not throw for any input', () {
        final invalidInputs = [
          'random text',
          '{',
          '}',
          '[',
          ']',
          'undefined',
          'NaN',
          'Infinity',
          '   ',
          '\n\t',
          '12.34.56',
          '{key:value}',
          "{'key':'value'}",
          '{"key":undefined}',
        ];

        for (final input in invalidInputs) {
          expect(() => tryJsonDecode(input), returnsNormally);
          expect(tryJsonDecode(input), null);
        }
      });

      test('handles very large invalid strings gracefully', () {
        final largeInvalidString = 'x' * 100000;
        expect(() => tryJsonDecode(largeInvalidString), returnsNormally);
        expect(tryJsonDecode(largeInvalidString), null);
      });
    });
  });
}

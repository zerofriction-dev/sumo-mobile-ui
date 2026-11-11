import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/pretty_print.dart';

void main() {
  group('prettyPrint — Map input', () {
    test('simple map → indented JSON', () {
      final result = prettyPrint({'key': 'value', 'num': 1});
      expect(result, contains('"key": "value"'));
      expect(result, contains('"num": 1'));
    });

    test('nested map → multi-line indented output', () {
      final result = prettyPrint({
        'outer': {'inner': 'x'},
      });
      expect(result, contains('"outer"'));
      expect(result, contains('"inner": "x"'));
    });

    test('empty map → {}', () {
      expect(prettyPrint({}), '{}');
    });
  });

  group('prettyPrint — List input', () {
    test('list of strings → JSON array', () {
      final result = prettyPrint(['a', 'b', 'c']);
      expect(result, contains('"a"'));
      expect(result, contains('"b"'));
    });

    test('empty list → []', () {
      expect(prettyPrint([]), '[]');
    });
  });

  group('prettyPrint — String input', () {
    test('valid JSON string → pretty-printed', () {
      final result = prettyPrint('{"foo":"bar"}');
      expect(result, contains('"foo": "bar"'));
    });

    test('non-JSON string → returned as-is', () {
      expect(prettyPrint('hello world'), 'hello world');
    });

    test('empty string → returned as-is (not valid JSON)', () {
      expect(prettyPrint(''), '');
    });
  });

  group('prettyPrint — other types', () {
    test('integer → toString', () {
      expect(prettyPrint(42), '42');
    });

    test('double → toString', () {
      expect(prettyPrint(3.14), '3.14');
    });

    test('bool true → toString', () {
      expect(prettyPrint(true), 'true');
    });

    test('null → toString ("null")', () {
      expect(prettyPrint(null), 'null');
    });
  });
}

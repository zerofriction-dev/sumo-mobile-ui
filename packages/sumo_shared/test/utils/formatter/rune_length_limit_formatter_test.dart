import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/formatter/rune_length_limit_formatter.dart';

TextEditingValue _v(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('RuneLengthLimitFormatter', () {
    final formatter = RuneLengthLimitFormatter(5);

    test('passes through input under the limit', () {
      final next = _v('abc');
      expect(formatter.formatEditUpdate(_v('ab'), next), same(next));
    });

    test('passes through input exactly at the limit', () {
      final next = _v('abcde');
      expect(formatter.formatEditUpdate(_v('abcd'), next), same(next));
    });

    test('keeps the old value when it is already at the limit', () {
      final old = _v('abcde');
      expect(formatter.formatEditUpdate(old, _v('abcdef')), same(old));
    });

    test('truncates a paste that overshoots the limit', () {
      final result = formatter.formatEditUpdate(_v('ab'), _v('abcdefgh'));
      expect(result.text, 'abcde');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('counts runes, not UTF-16 code units (emoji)', () {
      // each emoji is 1 rune but 2 code units
      const emoji = '😀😀😀😀😀😀';
      final result = formatter.formatEditUpdate(_v(''), _v(emoji));
      expect(result.text.runes.length, 5);
      expect(result.text, '😀😀😀😀😀');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('empty input is passed through', () {
      final next = _v('');
      expect(formatter.formatEditUpdate(_v('a'), next), same(next));
    });
  });
}

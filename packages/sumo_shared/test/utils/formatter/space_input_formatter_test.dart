import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/formatter/space_input_formatter.dart';

// Helper to build a simple TextEditingValue from plain text
TextEditingValue _val(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  final formatter = NoInitialSpaceInputFormatter();

  group('NoInitialSpaceInputFormatter.formatEditUpdate', () {
    test('non-space first char → returns newValue unchanged', () {
      final old = _val('');
      final next = _val('a');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, 'a');
    });

    test('single space typed into empty field → returns oldValue (empty)', () {
      final old = _val('');
      final next = _val(' ');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, '');
    });

    test('space at start of multi-char text → returns oldValue', () {
      final old = _val('hello');
      final next = _val(' hello');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, 'hello');
    });

    test('internal space is allowed (not at start) → returns newValue', () {
      final old = _val('hello');
      final next = _val('hello ');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, 'hello ');
    });

    test('space in middle of word → allowed', () {
      final old = _val('hel');
      final next = _val('hel lo');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, 'hel lo');
    });

    test(
      'empty string newValue → not starting with space → returns newValue',
      () {
        final old = _val('a');
        final next = _val('');
        final result = formatter.formatEditUpdate(old, next);
        expect(result.text, '');
      },
    );

    test('newValue starts with multiple spaces → returns oldValue', () {
      final old = _val('');
      final next = _val('   ');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, '');
    });

    test('newValue is a digit → passes through', () {
      final old = _val('');
      final next = _val('1');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, '1');
    });

    test('thai characters → allowed (not a space)', () {
      final old = _val('');
      final next = _val('สวัสดี');
      final result = formatter.formatEditUpdate(old, next);
      expect(result.text, 'สวัสดี');
    });
  });
}

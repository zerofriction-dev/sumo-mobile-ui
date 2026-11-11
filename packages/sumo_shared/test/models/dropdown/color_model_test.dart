import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/color_model.dart';

void main() {
  group('ColorModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = ColorModel.fromJson({
        'id': 'c1',
        'name': 'ขาว',
        'colorHex': '#FFFFFF',
      });
      expect(m.id, 'c1');
      expect(m.name, 'ขาว');
      expect(m.colorHex, '#FFFFFF');
    });

    test('missing fields → default empty string', () {
      final m = ColorModel.fromJson({});
      expect(m.id, '');
      expect(m.name, '');
      expect(m.colorHex, '');
    });

    test('null values → default empty string', () {
      final m = ColorModel.fromJson({
        'id': null,
        'name': null,
        'colorHex': null,
      });
      expect(m.id, '');
      expect(m.name, '');
      expect(m.colorHex, '');
    });
  });

  group('ColorModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {'id': 'c5', 'name': 'แดง', 'colorHex': '#FF0000'};
      final m = ColorModel.fromJson(original);
      final json = m.toJson();
      expect(json['id'], 'c5');
      expect(json['name'], 'แดง');
      expect(json['colorHex'], '#FF0000');
    });

    test('null fields serialize as null', () {
      final m = ColorModel();
      final json = m.toJson();
      expect(json['id'], isNull);
      expect(json['name'], isNull);
      expect(json['colorHex'], isNull);
    });
  });

  group('colorModelFromJson / colorModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {'id': '1', 'name': 'ขาว', 'colorHex': '#FFFFFF'},
        {'id': '2', 'name': 'ดำ', 'colorHex': '#000000'},
      ]);
      final list = colorModelFromJson(str);
      expect(list.length, 2);
      expect(list[0].id, '1');
      expect(list[1].name, 'ดำ');
    });

    test('encodes list to JSON string', () {
      final list = [
        ColorModel(id: '1', name: 'ขาว', colorHex: '#FFFFFF'),
        ColorModel(id: '2', name: 'ดำ', colorHex: '#000000'),
      ];
      final str = colorModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 2);
      expect(decoded[0]['id'], '1');
      expect(decoded[1]['colorHex'], '#000000');
    });

    test('empty list round-trip', () {
      final str = colorModelToJson([]);
      final list = colorModelFromJson(str);
      expect(list, isEmpty);
    });
  });

  group('ColorModel.defaultColors', () {
    test('contains 20 entries', () {
      expect(ColorModel.defaultColors.length, 20);
    });

    test('first entry is ขาว #FFFFFF', () {
      final first = ColorModel.defaultColors.first;
      expect(first.id, '1');
      expect(first.name, 'ขาว');
      expect(first.colorHex, '#FFFFFF');
    });

    test('last entry is แดงเข้ม #8B0000', () {
      final last = ColorModel.defaultColors.last;
      expect(last.id, '20');
      expect(last.name, 'แดงเข้ม');
      expect(last.colorHex, '#8B0000');
    });
  });
}

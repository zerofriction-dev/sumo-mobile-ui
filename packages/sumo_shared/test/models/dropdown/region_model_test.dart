import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/region_model.dart';

void main() {
  group('RegionModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = RegionModel.fromJson({
        'regionId': 1,
        'regionNameTh': 'ภาคกลาง',
        'regionNameEn': 'Central',
      });
      expect(m.regionId, 1);
      expect(m.regionNameTh, 'ภาคกลาง');
      expect(m.regionNameEn, 'Central');
    });

    test('missing fields → defaults: 0 for int, "" for strings', () {
      final m = RegionModel.fromJson({});
      expect(m.regionId, 0);
      expect(m.regionNameTh, '');
      expect(m.regionNameEn, '');
    });

    test('null values → defaults', () {
      final m = RegionModel.fromJson({
        'regionId': null,
        'regionNameTh': null,
        'regionNameEn': null,
      });
      expect(m.regionId, 0);
      expect(m.regionNameTh, '');
      expect(m.regionNameEn, '');
    });
  });

  group('RegionModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {
        'regionId': 3,
        'regionNameTh': 'ภาคเหนือ',
        'regionNameEn': 'Northern',
      };
      final m = RegionModel.fromJson(original);
      final j = m.toJson();
      expect(j['regionId'], 3);
      expect(j['regionNameTh'], 'ภาคเหนือ');
      expect(j['regionNameEn'], 'Northern');
    });

    test('null fields serialize as null', () {
      final m = RegionModel(
        regionId: null,
        regionNameTh: null,
        regionNameEn: null,
      );
      final j = m.toJson();
      expect(j['regionId'], isNull);
      expect(j['regionNameTh'], isNull);
      expect(j['regionNameEn'], isNull);
    });
  });

  group('regionModelFromJson / regionModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {'regionId': 1, 'regionNameTh': 'ภาคกลาง', 'regionNameEn': 'Central'},
        {'regionId': 2, 'regionNameTh': 'ภาคเหนือ', 'regionNameEn': 'Northern'},
        {'regionId': 3, 'regionNameTh': 'ภาคใต้', 'regionNameEn': 'Southern'},
      ]);
      final list = regionModelFromJson(str);
      expect(list.length, 3);
      expect(list[0].regionId, 1);
      expect(list[2].regionNameEn, 'Southern');
    });

    test('encodes list to JSON string', () {
      final list = [
        RegionModel(
          regionId: 4,
          regionNameTh: 'ภาคตะวันออก',
          regionNameEn: 'Eastern',
        ),
      ];
      final str = regionModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['regionId'], 4);
      expect(decoded[0]['regionNameEn'], 'Eastern');
    });

    test('empty list round-trip', () {
      final str = regionModelToJson([]);
      final list = regionModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

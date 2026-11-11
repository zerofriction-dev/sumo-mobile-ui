import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/company_model.dart';

void main() {
  group('CompanyModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = CompanyModel.fromJson({
        'companyId': 'co1',
        'companyName': 'บริษัท เทสต์',
        'companyLocation': 'กรุงเทพฯ',
        'isInternal': true,
        'isLegal': false,
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-06-01T00:00:00Z',
      });
      expect(m.companyId, 'co1');
      expect(m.companyName, 'บริษัท เทสต์');
      expect(m.companyLocation, 'กรุงเทพฯ');
      expect(m.isInternal, true);
      expect(m.isLegal, false);
      expect(m.createdAt, '2024-01-01T00:00:00Z');
      expect(m.updatedAt, '2024-06-01T00:00:00Z');
    });

    test('missing fields → all null (no ?? defaults in source)', () {
      final m = CompanyModel.fromJson({});
      expect(m.companyId, isNull);
      expect(m.companyName, isNull);
      expect(m.companyLocation, isNull);
      expect(m.isInternal, isNull);
      expect(m.isLegal, isNull);
      expect(m.createdAt, isNull);
      expect(m.updatedAt, isNull);
    });

    test('dynamic createdAt/updatedAt accepts int timestamp', () {
      final m = CompanyModel.fromJson({
        'companyId': 'co2',
        'companyName': 'test',
        'companyLocation': '',
        'isInternal': false,
        'isLegal': true,
        'createdAt': 1700000000,
        'updatedAt': 1700000001,
      });
      expect(m.createdAt, 1700000000);
      expect(m.updatedAt, 1700000001);
    });
  });

  group('CompanyModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {
        'companyId': 'co1',
        'companyName': 'ABC',
        'companyLocation': 'นนทบุรี',
        'isInternal': true,
        'isLegal': true,
        'createdAt': '2024-01-01',
        'updatedAt': '2024-06-01',
      };
      final m = CompanyModel.fromJson(original);
      final j = m.toJson();
      expect(j['companyId'], 'co1');
      expect(j['companyName'], 'ABC');
      expect(j['companyLocation'], 'นนทบุรี');
      expect(j['isInternal'], true);
      expect(j['isLegal'], true);
      expect(j['createdAt'], '2024-01-01');
      expect(j['updatedAt'], '2024-06-01');
    });

    test('null fields serialize as null', () {
      final m = CompanyModel.fromJson({});
      final j = m.toJson();
      expect(j['companyId'], isNull);
      expect(j['isInternal'], isNull);
    });
  });

  group('companyModelFromJson / companyModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {
          'companyId': 'c1',
          'companyName': 'A',
          'companyLocation': '',
          'isInternal': false,
          'isLegal': true,
          'createdAt': null,
          'updatedAt': null,
        },
        {
          'companyId': 'c2',
          'companyName': 'B',
          'companyLocation': '',
          'isInternal': true,
          'isLegal': false,
          'createdAt': null,
          'updatedAt': null,
        },
      ]);
      final list = companyModelFromJson(str);
      expect(list.length, 2);
      expect(list[0].companyId, 'c1');
      expect(list[1].isInternal, true);
    });

    test('encodes list to JSON string', () {
      final list = [
        CompanyModel(
          companyId: 'c1',
          companyName: 'A',
          companyLocation: '',
          isInternal: false,
          isLegal: true,
          createdAt: null,
          updatedAt: null,
        ),
      ];
      final str = companyModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['companyId'], 'c1');
    });

    test('empty list round-trip', () {
      final str = companyModelToJson([]);
      final list = companyModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/document/license_type_model.dart';

void main() {
  group('LicenseTypeModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = LicenseTypeModel.fromJson({
        'valueListId': 'vl1',
        'valueListCode': 'TYPE_B',
        'valueListName': 'ใบขับขี่ประเภท ข',
        'valueListTypeId': 5,
        'valueListImage': '/img/license_b.png',
        'description': 'รถยนต์ส่วนบุคคล',
      });
      expect(m.valueListId, 'vl1');
      expect(m.valueListCode, 'TYPE_B');
      expect(m.valueListName, 'ใบขับขี่ประเภท ข');
      expect(m.valueListTypeId, 5);
      expect(m.valueListImage, '/img/license_b.png');
      expect(m.description, 'รถยนต์ส่วนบุคคล');
    });

    test('missing fields → defaults ("" / 0)', () {
      final m = LicenseTypeModel.fromJson({});
      expect(m.valueListId, '');
      expect(m.valueListCode, '');
      expect(m.valueListName, '');
      expect(m.valueListTypeId, 0);
      expect(m.valueListImage, '');
      expect(m.description, '');
    });

    test('valueListTypeId=0 is preserved', () {
      final m = LicenseTypeModel.fromJson({'valueListTypeId': 0});
      expect(m.valueListTypeId, 0);
    });

    test('large int is parsed correctly', () {
      final m = LicenseTypeModel.fromJson({'valueListTypeId': 999});
      expect(m.valueListTypeId, 999);
    });
  });

  group('LicenseTypeModel.toJson', () {
    test('round-trip fromJson → toJson preserves all values', () {
      final src = {
        'valueListId': 'vl2',
        'valueListCode': 'TYPE_C',
        'valueListName': 'ใบขับขี่ประเภท ค',
        'valueListTypeId': 7,
        'valueListImage': '/img/license_c.png',
        'description': 'รถบรรทุก',
      };
      final m = LicenseTypeModel.fromJson(src);
      final j = m.toJson();
      expect(j['valueListId'], 'vl2');
      expect(j['valueListCode'], 'TYPE_C');
      expect(j['valueListName'], 'ใบขับขี่ประเภท ค');
      expect(j['valueListTypeId'], 7);
      expect(j['valueListImage'], '/img/license_c.png');
      expect(j['description'], 'รถบรรทุก');
    });
  });

  group('licenseTypeModelFromJson / licenseTypeModelToJson', () {
    test('decodes JSON string to list', () {
      final jsonStr = json.encode([
        {
          'valueListId': 'v1',
          'valueListCode': 'A',
          'valueListName': 'NA',
          'valueListTypeId': 1,
          'valueListImage': '',
          'description': '',
        },
        {
          'valueListId': 'v2',
          'valueListCode': 'B',
          'valueListName': 'NB',
          'valueListTypeId': 2,
          'valueListImage': '',
          'description': '',
        },
      ]);
      final list = licenseTypeModelFromJson(jsonStr);
      expect(list.length, 2);
      expect(list[0].valueListId, 'v1');
      expect(list[1].valueListTypeId, 2);
    });

    test('encodes list to JSON string', () {
      final list = [
        LicenseTypeModel.fromJson({
          'valueListId': 'x1',
          'valueListCode': 'X',
          'valueListName': 'NX',
          'valueListTypeId': 3,
          'valueListImage': '',
          'description': '',
        }),
      ];
      final str = licenseTypeModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['valueListId'], 'x1');
      expect(decoded[0]['valueListTypeId'], 3);
    });
  });
}

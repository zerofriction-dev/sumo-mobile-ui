import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/license_plate_model.dart';

void main() {
  group('LicensePlateModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = LicensePlateModel.fromJson({
        'id': 'lp1',
        'name': 'ป้ายทะเบียนรถยนต์',
        'imagePath': '/images/plate.png',
        'slug': 'car-plate',
        'isActive': true,
        'sequent': 3,
        'color': 'white',
      });
      expect(m.id, 'lp1');
      expect(m.name, 'ป้ายทะเบียนรถยนต์');
      expect(m.imagePath, '/images/plate.png');
      expect(m.slug, 'car-plate');
      expect(m.isActive, true);
      expect(m.sequent, 3);
      expect(m.color, 'white');
    });

    test(
      'missing fields → defaults: "" for strings, false for bool, 0 for int',
      () {
        final m = LicensePlateModel.fromJson({});
        expect(m.id, '');
        expect(m.name, '');
        expect(m.imagePath, '');
        expect(m.slug, '');
        expect(m.isActive, false);
        expect(m.sequent, 0);
        expect(m.color, '');
      },
    );

    test('null values → defaults', () {
      final m = LicensePlateModel.fromJson({
        'id': null,
        'name': null,
        'imagePath': null,
        'slug': null,
        'isActive': null,
        'sequent': null,
        'color': null,
      });
      expect(m.id, '');
      expect(m.isActive, false);
      expect(m.sequent, 0);
      expect(m.color, '');
    });

    test('isActive=false parsed correctly', () {
      final m = LicensePlateModel.fromJson({'isActive': false});
      expect(m.isActive, false);
    });

    test('sequent=0 parsed correctly', () {
      final m = LicensePlateModel.fromJson({'sequent': 0});
      expect(m.sequent, 0);
    });
  });

  group('LicensePlateModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {
        'id': 'lp2',
        'name': 'ป้ายเหลือง',
        'imagePath': '/img/y.png',
        'slug': 'yellow',
        'isActive': true,
        'sequent': 5,
        'color': 'yellow',
      };
      final m = LicensePlateModel.fromJson(original);
      final j = m.toJson();
      expect(j['id'], 'lp2');
      expect(j['name'], 'ป้ายเหลือง');
      expect(j['imagePath'], '/img/y.png');
      expect(j['slug'], 'yellow');
      expect(j['isActive'], true);
      expect(j['sequent'], 5);
      expect(j['color'], 'yellow');
    });

    test('null fields serialize as null', () {
      final m = LicensePlateModel();
      final j = m.toJson();
      expect(j['id'], isNull);
      expect(j['isActive'], isNull);
      expect(j['sequent'], isNull);
    });
  });

  group('licensePlateModelFromJson / licensePlateModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {
          'id': '1',
          'name': 'A',
          'imagePath': '',
          'slug': 's1',
          'isActive': true,
          'sequent': 1,
          'color': 'white',
        },
        {
          'id': '2',
          'name': 'B',
          'imagePath': '',
          'slug': 's2',
          'isActive': false,
          'sequent': 2,
          'color': 'yellow',
        },
      ]);
      final list = licensePlateModelFromJson(str);
      expect(list.length, 2);
      expect(list[0].id, '1');
      expect(list[1].isActive, false);
      expect(list[1].sequent, 2);
    });

    test('encodes list to JSON string', () {
      final list = [
        LicensePlateModel(
          id: 'x',
          name: 'X',
          imagePath: '',
          slug: 'sx',
          isActive: true,
          sequent: 10,
          color: 'red',
        ),
      ];
      final str = licensePlateModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['id'], 'x');
      expect(decoded[0]['isActive'], true);
      expect(decoded[0]['sequent'], 10);
    });

    test('empty list round-trip', () {
      final str = licensePlateModelToJson([]);
      final list = licensePlateModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

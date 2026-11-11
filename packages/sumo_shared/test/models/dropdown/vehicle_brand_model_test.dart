import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/vehicle_brand_model.dart';

void main() {
  group('VehicleBrandModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = VehicleBrandModel.fromJson({
        'id': 'vb1',
        'name': 'Toyota',
        'imagePath': '/images/toyota.png',
        'thumbnailPath': '/thumbnails/toyota.png',
      });
      expect(m.id, 'vb1');
      expect(m.name, 'Toyota');
      expect(m.imagePath, '/images/toyota.png');
      expect(m.thumbnailPath, '/thumbnails/toyota.png');
    });

    test('missing fields → default empty string', () {
      final m = VehicleBrandModel.fromJson({});
      expect(m.id, '');
      expect(m.name, '');
      expect(m.imagePath, '');
      expect(m.thumbnailPath, '');
    });

    test('null values → default empty string', () {
      final m = VehicleBrandModel.fromJson({
        'id': null,
        'name': null,
        'imagePath': null,
        'thumbnailPath': null,
      });
      expect(m.id, '');
      expect(m.name, '');
      expect(m.imagePath, '');
      expect(m.thumbnailPath, '');
    });
  });

  group('VehicleBrandModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {
        'id': 'vb2',
        'name': 'Honda',
        'imagePath': '/images/honda.png',
        'thumbnailPath': '/thumbnails/honda.png',
      };
      final m = VehicleBrandModel.fromJson(original);
      final j = m.toJson();
      expect(j['id'], 'vb2');
      expect(j['name'], 'Honda');
      expect(j['imagePath'], '/images/honda.png');
      expect(j['thumbnailPath'], '/thumbnails/honda.png');
    });

    test('null fields serialize as null', () {
      final m = VehicleBrandModel();
      final j = m.toJson();
      expect(j['id'], isNull);
      expect(j['name'], isNull);
      expect(j['imagePath'], isNull);
      expect(j['thumbnailPath'], isNull);
    });
  });

  group('vehicleBrandModelFromJson / vehicleBrandModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {
          'id': '1',
          'name': 'Toyota',
          'imagePath': '/t.png',
          'thumbnailPath': '/tt.png',
        },
        {
          'id': '2',
          'name': 'Isuzu',
          'imagePath': '/i.png',
          'thumbnailPath': '/it.png',
        },
      ]);
      final list = vehicleBrandModelFromJson(str);
      expect(list.length, 2);
      expect(list[0].id, '1');
      expect(list[1].name, 'Isuzu');
      expect(list[1].thumbnailPath, '/it.png');
    });

    test('encodes list to JSON string', () {
      final list = [
        VehicleBrandModel(
          id: 'b1',
          name: 'Ford',
          imagePath: '/f.png',
          thumbnailPath: '/ft.png',
        ),
      ];
      final str = vehicleBrandModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['id'], 'b1');
      expect(decoded[0]['thumbnailPath'], '/ft.png');
    });

    test('empty list round-trip', () {
      final str = vehicleBrandModelToJson([]);
      final list = vehicleBrandModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/dropdown/vehicle_model_model.dart';

void main() {
  group('VehicleModelModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = VehicleModelModel.fromJson({
        'id': 'vm1',
        'name': 'Hilux Revo',
        'brandId': 'vb1',
      });
      expect(m.id, 'vm1');
      expect(m.name, 'Hilux Revo');
      expect(m.brandId, 'vb1');
    });

    test('missing fields → default empty string', () {
      final m = VehicleModelModel.fromJson({});
      expect(m.id, '');
      expect(m.name, '');
      expect(m.brandId, '');
    });

    test('null values → default empty string', () {
      final m = VehicleModelModel.fromJson({
        'id': null,
        'name': null,
        'brandId': null,
      });
      expect(m.id, '');
      expect(m.name, '');
      expect(m.brandId, '');
    });
  });

  group('VehicleModelModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final original = {'id': 'vm2', 'name': 'Civic', 'brandId': 'vb2'};
      final m = VehicleModelModel.fromJson(original);
      final j = m.toJson();
      expect(j['id'], 'vm2');
      expect(j['name'], 'Civic');
      expect(j['brandId'], 'vb2');
    });

    test('null fields serialize as null', () {
      final m = VehicleModelModel();
      final j = m.toJson();
      expect(j['id'], isNull);
      expect(j['name'], isNull);
      expect(j['brandId'], isNull);
    });
  });

  group('vehicleModelModelFromJson / vehicleModelModelToJson helpers', () {
    test('decodes JSON string to list', () {
      final str = json.encode([
        {'id': '1', 'name': 'Hilux Revo', 'brandId': 'toyota'},
        {'id': '2', 'name': 'D-Max', 'brandId': 'isuzu'},
        {'id': '3', 'name': 'Ranger', 'brandId': 'ford'},
      ]);
      final list = vehicleModelModelFromJson(str);
      expect(list.length, 3);
      expect(list[0].id, '1');
      expect(list[1].name, 'D-Max');
      expect(list[2].brandId, 'ford');
    });

    test('encodes list to JSON string', () {
      final list = [
        VehicleModelModel(id: 'x1', name: 'Triton', brandId: 'mitsubishi'),
      ];
      final str = vehicleModelModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['id'], 'x1');
      expect(decoded[0]['brandId'], 'mitsubishi');
    });

    test('empty list round-trip', () {
      final str = vehicleModelModelToJson([]);
      final list = vehicleModelModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

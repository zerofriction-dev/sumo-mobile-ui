import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/service/service_add_on_model.dart';

void main() {
  group('ServiceAddOnModel.fromJson', () {
    test('fully populated maps every field', () {
      final json = {
        'id': 'a1',
        'name': 'Winch',
        'slug': 'winch',
        'imagePath': '/img/winch.png',
        'thumbnailPath': '/thumb/winch.png',
        'isActive': true,
        'serviceId': 'svc-1',
      };
      final m = ServiceAddOnModel.fromJson(json);
      expect(m.id, 'a1');
      expect(m.name, 'Winch');
      expect(m.slug, 'winch');
      expect(m.imagePath, '/img/winch.png');
      expect(m.thumbnailPath, '/thumb/winch.png');
      expect(m.isActive, true);
      expect(m.serviceId, 'svc-1');
    });

    test('empty map applies defaults', () {
      final m = ServiceAddOnModel.fromJson({});
      expect(m.id, '');
      expect(m.name, '');
      expect(m.slug, '');
      expect(m.imagePath, '');
      expect(m.thumbnailPath, '');
      expect(m.isActive, false);
      expect(m.serviceId, '');
    });

    test('explicit nulls fall back to defaults', () {
      final m = ServiceAddOnModel.fromJson({
        'id': null,
        'name': null,
        'slug': null,
        'imagePath': null,
        'thumbnailPath': null,
        'isActive': null,
        'serviceId': null,
      });
      expect(m.id, '');
      expect(m.name, '');
      expect(m.isActive, false);
      expect(m.serviceId, '');
    });
  });

  group('ServiceAddOnModel.toJson', () {
    test('emits all fields', () {
      final m = ServiceAddOnModel(
        id: 'a1',
        name: 'Winch',
        slug: 'winch',
        imagePath: '/img.png',
        thumbnailPath: '/thumb.png',
        isActive: true,
        serviceId: 'svc-1',
      );
      expect(m.toJson(), {
        'id': 'a1',
        'name': 'Winch',
        'slug': 'winch',
        'imagePath': '/img.png',
        'thumbnailPath': '/thumb.png',
        'isActive': true,
        'serviceId': 'svc-1',
      });
    });
  });

  group('ServiceAddOnModel round-trip', () {
    test('fromJson(toJson) preserves key fields', () {
      final original = ServiceAddOnModel.fromJson({
        'id': 'a1',
        'name': 'Winch',
        'slug': 'winch',
        'isActive': true,
        'serviceId': 'svc-1',
      });
      final round = ServiceAddOnModel.fromJson(original.toJson());
      expect(round.id, 'a1');
      expect(round.name, 'Winch');
      expect(round.slug, 'winch');
      expect(round.isActive, true);
      expect(round.serviceId, 'svc-1');
    });
  });

  group('top-level helpers', () {
    test('serviceAddOnModelFromJson parses a JSON array string', () {
      final str = jsonEncode([
        {'id': 'a1', 'name': 'Winch', 'isActive': true},
        {'id': 'a2', 'name': 'Strap', 'isActive': false},
      ]);
      final list = serviceAddOnModelFromJson(str);
      expect(list, isA<List<ServiceAddOnModel>>());
      expect(list.length, 2);
      expect(list[0].id, 'a1');
      expect(list[1].name, 'Strap');
      expect(list[1].isActive, false);
    });

    test('serviceAddOnModelToJson serializes a list to a JSON string', () {
      final list = [ServiceAddOnModel(id: 'a1', name: 'Winch', isActive: true)];
      final str = serviceAddOnModelToJson(list);
      final decoded = jsonDecode(str) as List;
      expect(decoded.first['id'], 'a1');
      expect(decoded.first['name'], 'Winch');
      expect(decoded.first['isActive'], true);
    });
  });
}

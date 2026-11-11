import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/service/service_main_type_model.dart';

void main() {
  group('ServiceMainTypeModel.fromJson', () {
    test('fully populated maps every field', () {
      final json = {
        'id': 'm1',
        'code': 'MT01',
        'serviceId': 'svc-1',
        'name': 'Slide-on',
        'slug': 'slide-on',
        'isActive': true,
        'imagePath': '/img.png',
        'thumbnailPath': '/thumb.png',
      };
      final m = ServiceMainTypeModel.fromJson(json);
      expect(m.id, 'm1');
      expect(m.code, 'MT01');
      expect(m.serviceId, 'svc-1');
      expect(m.name, 'Slide-on');
      expect(m.slug, 'slide-on');
      expect(m.isActive, true);
      expect(m.imagePath, '/img.png');
      expect(m.thumbnailPath, '/thumb.png');
    });

    test('empty map applies defaults', () {
      final m = ServiceMainTypeModel.fromJson({});
      expect(m.id, '');
      expect(m.code, '');
      expect(m.serviceId, '');
      expect(m.name, '');
      expect(m.slug, '');
      expect(m.isActive, false);
      expect(m.imagePath, '');
      expect(m.thumbnailPath, '');
    });

    test('explicit nulls fall back to defaults', () {
      final m = ServiceMainTypeModel.fromJson({
        'id': null,
        'code': null,
        'isActive': null,
      });
      expect(m.id, '');
      expect(m.code, '');
      expect(m.isActive, false);
    });
  });

  group('ServiceMainTypeModel.toJson', () {
    test('emits all fields', () {
      final m = ServiceMainTypeModel(
        id: 'm1',
        code: 'MT01',
        serviceId: 'svc-1',
        name: 'Slide-on',
        slug: 'slide-on',
        isActive: true,
        imagePath: '/img.png',
        thumbnailPath: '/thumb.png',
      );
      expect(m.toJson(), {
        'id': 'm1',
        'code': 'MT01',
        'serviceId': 'svc-1',
        'name': 'Slide-on',
        'slug': 'slide-on',
        'isActive': true,
        'imagePath': '/img.png',
        'thumbnailPath': '/thumb.png',
      });
    });
  });

  group('ServiceMainTypeModel round-trip', () {
    test('fromJson(toJson) preserves key fields', () {
      final original = ServiceMainTypeModel.fromJson({
        'id': 'm1',
        'code': 'MT01',
        'name': 'Slide-on',
        'isActive': true,
      });
      final round = ServiceMainTypeModel.fromJson(original.toJson());
      expect(round.id, 'm1');
      expect(round.code, 'MT01');
      expect(round.name, 'Slide-on');
      expect(round.isActive, true);
    });
  });

  group('top-level helpers', () {
    test('serviceMainTypeModelFromJson parses a JSON array string', () {
      final str = jsonEncode([
        {'id': 'm1', 'code': 'MT01', 'isActive': true},
        {'id': 'm2', 'code': 'MT02', 'isActive': false},
      ]);
      final list = serviceMainTypeModelFromJson(str);
      expect(list, isA<List<ServiceMainTypeModel>>());
      expect(list.length, 2);
      expect(list[0].id, 'm1');
      expect(list[1].code, 'MT02');
    });

    test('serviceMainTypeModelToJson serializes a list to a JSON string', () {
      final list = [
        ServiceMainTypeModel(id: 'm1', code: 'MT01', isActive: true),
      ];
      final str = serviceMainTypeModelToJson(list);
      final decoded = jsonDecode(str) as List;
      expect(decoded.first['id'], 'm1');
      expect(decoded.first['code'], 'MT01');
      expect(decoded.first['isActive'], true);
    });
  });
}

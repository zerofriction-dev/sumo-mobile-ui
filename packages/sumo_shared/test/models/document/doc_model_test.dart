import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/document/doc_model.dart';

void main() {
  group('Status', () {
    test('fromJson fully populated', () {
      final s = Status.fromJson({
        'id': 's1',
        'name': 'Active',
        'color': '#FF0000',
      });
      expect(s.id, 's1');
      expect(s.name, 'Active');
      expect(s.color, '#FF0000');
    });

    test('fromJson empty -> defaults', () {
      final s = Status.fromJson({});
      expect(s.id, '');
      expect(s.name, '');
      expect(s.color, '');
    });

    test('toJson', () {
      final s = Status.fromJson({'id': 'a', 'name': 'b', 'color': 'c'});
      expect(s.toJson(), {'id': 'a', 'name': 'b', 'color': 'c'});
    });
  });

  group('Type', () {
    test('fromJson fully populated', () {
      final t = Type.fromJson({'id': 't1', 'name': 'License'});
      expect(t.id, 't1');
      expect(t.name, 'License');
    });

    test('fromJson empty -> defaults', () {
      final t = Type.fromJson({});
      expect(t.id, '');
      expect(t.name, '');
    });

    test('toJson', () {
      expect(Type.fromJson({'id': 'x', 'name': 'y'}).toJson(), {
        'id': 'x',
        'name': 'y',
      });
    });
  });

  group('LicenseType', () {
    test('fromJson fully populated', () {
      final l = LicenseType.fromJson({'id': 'l1', 'name': 'Type A'});
      expect(l.id, 'l1');
      expect(l.name, 'Type A');
    });

    test('fromJson empty -> defaults', () {
      final l = LicenseType.fromJson({});
      expect(l.id, '');
      expect(l.name, '');
    });

    test('toJson', () {
      expect(LicenseType.fromJson({'id': 'p', 'name': 'q'}).toJson(), {
        'id': 'p',
        'name': 'q',
      });
    });
  });

  group('Documents', () {
    final fullJson = {
      'id': 'doc1',
      'route': '/route',
      'name': 'Driving License',
      'path': '/path/file.png',
      'thumbnailPath': '/thumb.png',
      'imgEx': 'png',
      'status': {'id': 's', 'name': 'OK', 'color': '#000'},
      'type': {'id': 't', 'name': 'TypeName'},
      'licenseType': {'id': 'lt', 'name': 'A'},
      'createdAt': '2024-01-01T00:00:00Z',
      'createdBy': 'admin',
      'expiredAt': '2025-01-01T00:00:00Z',
      'expiredStatus': 'valid',
    };

    test('fromJson fully populated incl nested models', () {
      final d = Documents.fromJson(fullJson);
      expect(d.id, 'doc1');
      expect(d.route, '/route');
      expect(d.name, 'Driving License');
      expect(d.path, '/path/file.png');
      expect(d.thumbnailPath, '/thumb.png');
      expect(d.imgEx, 'png');
      expect(d.status!.name, 'OK');
      expect(d.type!.name, 'TypeName');
      expect(d.licenseType!.name, 'A');
      expect(d.createdAt, '2024-01-01T00:00:00Z');
      expect(d.createdBy, 'admin');
      expect(d.expiredAt, '2025-01-01T00:00:00Z');
      expect(d.expiredStatus, 'valid');
    });

    test('fromJson empty -> defaults and non-null nested', () {
      final d = Documents.fromJson({});
      expect(d.id, '');
      expect(d.route, '');
      expect(d.name, '');
      expect(d.path, '');
      expect(d.thumbnailPath, '');
      expect(d.imgEx, '');
      expect(d.status, isA<Status>());
      expect(d.status!.id, '');
      expect(d.type, isA<Type>());
      expect(d.licenseType, isA<LicenseType>());
      expect(d.createdAt, '');
      expect(d.createdBy, '');
      expect(d.expiredAt, '');
      expect(d.expiredStatus, '');
    });

    test('toJson includes nested', () {
      final d = Documents.fromJson(fullJson);
      final json = d.toJson();
      expect(json['id'], 'doc1');
      expect(json['status'], {'id': 's', 'name': 'OK', 'color': '#000'});
      expect(json['type'], {'id': 't', 'name': 'TypeName'});
      expect(json['licenseType'], {'id': 'lt', 'name': 'A'});
    });
  });

  group('DocumentAllModel', () {
    test('fromJson with documents list', () {
      final m = DocumentAllModel.fromJson({
        'documents': [
          {'id': 'd1'},
          {'id': 'd2'},
        ],
      });
      expect(m.documents!.length, 2);
      expect(m.documents![0], isA<Documents>());
      expect(m.documents![1].id, 'd2');
    });

    test('fromJson without documents -> empty list', () {
      final m = DocumentAllModel.fromJson({});
      expect(m.documents, isEmpty);
    });

    test('fromJson null documents -> empty list', () {
      final m = DocumentAllModel.fromJson({'documents': null});
      expect(m.documents, isEmpty);
    });

    test('toJson serializes documents', () {
      final m = DocumentAllModel(
        documents: [
          Documents.fromJson({'id': 'd1'}),
        ],
      );
      final json = m.toJson();
      expect((json['documents'] as List)[0]['id'], 'd1');
    });

    test('documentAllModelFromJson string helper', () {
      final str = jsonEncode({
        'documents': [
          {'id': 'x'},
        ],
      });
      final m = documentAllModelFromJson(str);
      expect(m.documents![0].id, 'x');
    });

    test('documentAllModelToJson string helper', () {
      final m = DocumentAllModel(
        documents: [
          Documents.fromJson({'id': 'z'}),
        ],
      );
      final decoded = jsonDecode(documentAllModelToJson(m));
      expect(decoded['documents'][0]['id'], 'z');
    });
  });
}

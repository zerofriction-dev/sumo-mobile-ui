import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/driver/gender_model.dart';

void main() {
  group('Prefix.fromJson', () {
    test('parses prefixName', () {
      final p = Prefix.fromJson({'prefixName': 'นาย'});
      expect(p.prefixName, 'นาย');
    });

    test('missing prefixName defaults to empty string', () {
      final p = Prefix.fromJson({});
      expect(p.prefixName, '');
    });
  });

  group('Prefix.toJson', () {
    test('round-trip preserves prefixName', () {
      final p = Prefix.fromJson({'prefixName': 'นาง'});
      expect(p.toJson()['prefixName'], 'นาง');
    });
  });

  group('GenderModel.fromJson', () {
    test('parses full payload with prefix list', () {
      final g = GenderModel.fromJson({
        'type': 'male',
        'name': 'ชาย',
        'prefix': [
          {'prefixName': 'นาย'},
          {'prefixName': 'เด็กชาย'},
        ],
      });
      expect(g.type, 'male');
      expect(g.name, 'ชาย');
      expect(g.prefix, hasLength(2));
      expect(g.prefix![0].prefixName, 'นาย');
      expect(g.prefix![1].prefixName, 'เด็กชาย');
    });

    test('missing type/name default to empty string', () {
      final g = GenderModel.fromJson({'prefix': []});
      expect(g.type, '');
      expect(g.name, '');
      expect(g.prefix, isEmpty);
    });

    test('missing prefix key defaults to empty list', () {
      final g = GenderModel.fromJson({'type': 'female', 'name': 'หญิง'});
      expect(g.prefix, isEmpty);
    });

    test('explicit null prefix defaults to empty list', () {
      final g = GenderModel.fromJson({'type': 'x', 'prefix': null});
      expect(g.prefix, isEmpty);
    });
  });

  group('GenderModel.toJson', () {
    test('round-trip preserves all fields', () {
      final g = GenderModel.fromJson({
        'type': 'female',
        'name': 'หญิง',
        'prefix': [
          {'prefixName': 'นาง'},
          {'prefixName': 'นางสาว'},
        ],
      });
      final out = g.toJson();
      expect(out['type'], 'female');
      expect(out['name'], 'หญิง');
      final list = out['prefix'] as List;
      expect(list, hasLength(2));
      expect((list[0] as Map)['prefixName'], 'นาง');
    });
  });

  group('genderModelFromJson / genderModelToJson (list string helpers)', () {
    test('decodes JSON array string to list', () {
      final list = genderModelFromJson(
        '[{"type":"male","name":"ชาย","prefix":[{"prefixName":"นาย"}]},{"type":"female","name":"หญิง","prefix":[]}]',
      );
      expect(list, hasLength(2));
      expect(list[0].type, 'male');
      expect(list[1].type, 'female');
    });

    test('encodes list to JSON string', () {
      final g = GenderModel(
        type: 'male',
        name: 'ชาย',
        prefix: [Prefix(prefixName: 'นาย')],
      );
      final s = genderModelToJson([g]);
      final decoded = json.decode(s) as List;
      expect(decoded, hasLength(1));
      expect(decoded[0]['type'], 'male');
    });
  });
}

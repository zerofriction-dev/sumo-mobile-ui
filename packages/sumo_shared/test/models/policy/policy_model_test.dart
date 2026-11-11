import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/policy/policy_model.dart';

void main() {
  group('PolicyModel', () {
    test('fromJson fully populated maps every field', () {
      final p = PolicyModel.fromJson({
        'id': 'p1',
        'name': 'นโยบายความเป็นส่วนตัว',
        'description': 'รายละเอียด',
        'sequent': 2,
        'version': 5,
      });
      expect(p.id, 'p1');
      expect(p.name, 'นโยบายความเป็นส่วนตัว');
      expect(p.description, 'รายละเอียด');
      expect(p.sequent, 2);
      expect(p.version, 5);
    });

    test('fromJson empty map applies defaults', () {
      final p = PolicyModel.fromJson({});
      expect(p.id, '');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.sequent, 0);
      expect(p.version, 0);
    });

    test('fromJson null values fall back to defaults', () {
      final p = PolicyModel.fromJson({
        'id': null,
        'name': null,
        'description': null,
        'sequent': null,
        'version': null,
      });
      expect(p.id, '');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.sequent, 0);
      expect(p.version, 0);
    });

    test('toJson emits all fields', () {
      final p = PolicyModel(
        id: 'p1',
        name: 'n',
        description: 'd',
        sequent: 1,
        version: 3,
      );
      expect(p.toJson(), {
        'id': 'p1',
        'name': 'n',
        'description': 'd',
        'sequent': 1,
        'version': 3,
      });
    });

    test('round-trip fromJson(toJson) preserves fields', () {
      final original = PolicyModel.fromJson({
        'id': 'p9',
        'name': 'name',
        'description': 'desc',
        'sequent': 7,
        'version': 8,
      });
      final round = PolicyModel.fromJson(original.toJson());
      expect(round.id, 'p9');
      expect(round.name, 'name');
      expect(round.description, 'desc');
      expect(round.sequent, 7);
      expect(round.version, 8);
    });
  });

  group('policyModelFromJson / policyModelToJson helpers', () {
    test(
      'policyModelFromJson parses a JSON array string into List<PolicyModel>',
      () {
        final str = jsonEncode([
          {'id': 'p1', 'name': 'a', 'sequent': 1, 'version': 1},
          {'id': 'p2', 'name': 'b', 'sequent': 2, 'version': 2},
        ]);
        final list = policyModelFromJson(str);
        expect(list, isA<List<PolicyModel>>());
        expect(list.length, 2);
        expect(list[0].id, 'p1');
        expect(list[0].name, 'a');
        expect(list[1].sequent, 2);
      },
    );

    test(
      'policyModelToJson serializes a List<PolicyModel> to a JSON string',
      () {
        final list = [
          PolicyModel(
            id: 'p1',
            name: 'a',
            description: 'd',
            sequent: 1,
            version: 1,
          ),
        ];
        final str = policyModelToJson(list);
        final decoded = jsonDecode(str) as List;
        expect(decoded.first['id'], 'p1');
        expect(decoded.first['name'], 'a');
        expect(decoded.first['version'], 1);
      },
    );

    test('policyModelFromJson on empty array yields empty list', () {
      expect(policyModelFromJson('[]'), isEmpty);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/contract_documents/cancel_select_model.dart';

void main() {
  group('SelectCancelModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = SelectCancelModel.fromJson({'id': 3, 'detail': 'ไม่สะดวก'});
      expect(m.id, 3);
      expect(m.detail, 'ไม่สะดวก');
    });

    test('missing fields → defaults (0 / "")', () {
      final m = SelectCancelModel.fromJson({});
      expect(m.id, 0);
      expect(m.detail, '');
    });

    test('id=0 preserved', () {
      final m = SelectCancelModel.fromJson({'id': 0, 'detail': ''});
      expect(m.id, 0);
    });

    test('large id value parsed', () {
      final m = SelectCancelModel.fromJson({'id': 999, 'detail': 'reason'});
      expect(m.id, 999);
    });
  });

  group('SelectCancelModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final src = {'id': 5, 'detail': 'เปลี่ยนใจ'};
      final m = SelectCancelModel.fromJson(src);
      final j = m.toJson();
      expect(j['id'], 5);
      expect(j['detail'], 'เปลี่ยนใจ');
    });
  });

  group('selectCancelModelFromJson / selectCancelModelToJson', () {
    test('decodes JSON string to list', () {
      final jsonStr = json.encode([
        {'id': 1, 'detail': 'ราคาแพง'},
        {'id': 2, 'detail': 'ไม่พอใจ'},
      ]);
      final list = selectCancelModelFromJson(jsonStr);
      expect(list.length, 2);
      expect(list[0].id, 1);
      expect(list[0].detail, 'ราคาแพง');
      expect(list[1].id, 2);
    });

    test('encodes list to JSON string', () {
      final list = [
        SelectCancelModel.fromJson({'id': 7, 'detail': 'test reason'}),
      ];
      final str = selectCancelModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['id'], 7);
      expect(decoded[0]['detail'], 'test reason');
    });

    test('empty list round-trip', () {
      final str = selectCancelModelToJson([]);
      final list = selectCancelModelFromJson(str);
      expect(list, isEmpty);
    });
  });
}

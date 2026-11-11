import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/error/api_error_model.dart';

void main() {
  group('ApiErrorModel.fromJson', () {
    test('fully populated', () {
      final m = ApiErrorModel.fromJson({
        'success': true,
        'message': 'something failed',
      });
      expect(m.success, true);
      expect(m.message, 'something failed');
    });

    test('empty map defaults success=false, message=""', () {
      final m = ApiErrorModel.fromJson({});
      expect(m.success, false);
      expect(m.message, '');
    });

    test('explicit nulls fall back to defaults', () {
      final m = ApiErrorModel.fromJson({'success': null, 'message': null});
      expect(m.success, false);
      expect(m.message, '');
    });

    test('success=false is preserved (?? only triggers on null)', () {
      final m = ApiErrorModel.fromJson({'success': false, 'message': 'x'});
      expect(m.success, false);
      expect(m.message, 'x');
    });
  });

  group('ApiErrorModel.toJson', () {
    test('round-trips the fields', () {
      final m = ApiErrorModel(success: true, message: 'ok');
      expect(m.toJson(), {'success': true, 'message': 'ok'});
    });

    test('emits nulls when constructed empty', () {
      final m = ApiErrorModel();
      expect(m.toJson(), {'success': null, 'message': null});
    });
  });

  group('top-level helpers', () {
    test('apiErrorModelFromJson parses a JSON string', () {
      final m = apiErrorModelFromJson('{"success": true, "message": "hi"}');
      expect(m.success, true);
      expect(m.message, 'hi');
    });

    test('apiErrorModelToJson serializes back to a JSON string', () {
      final m = ApiErrorModel(success: false, message: 'err');
      final str = apiErrorModelToJson(m);
      expect(json.decode(str), {'success': false, 'message': 'err'});
    });
  });
}

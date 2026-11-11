import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/error/api_error_old_model.dart';

void main() {
  group('ApiErrorOldModel.fromJson', () {
    test('parses full json incl. message lists', () {
      final m = ApiErrorOldModel.fromJson({
        'titleTh': 'หัวข้อ',
        'titleEn': 'Title',
        'messageTh': ['ก', 'ข'],
        'messageEn': ['a', 'b'],
        'serviceCode': 'SVC001',
      });
      expect(m.titleTh, 'หัวข้อ');
      expect(m.titleEn, 'Title');
      expect(m.messageTh, ['ก', 'ข']);
      expect(m.messageEn, ['a', 'b']);
      expect(m.serviceCode, 'SVC001');
    });

    test('applies defaults on empty json', () {
      final m = ApiErrorOldModel.fromJson({});
      expect(m.titleTh, '');
      expect(m.titleEn, '');
      expect(m.messageTh, <String>[]);
      expect(m.messageEn, <String>[]);
      expect(m.serviceCode, '');
    });

    test('null message arrays become empty lists', () {
      final m = ApiErrorOldModel.fromJson({
        'titleTh': 't',
        'messageTh': null,
        'messageEn': null,
      });
      expect(m.messageTh, <String>[]);
      expect(m.messageEn, <String>[]);
    });
  });

  group('ApiErrorOldModel.toJson', () {
    test('serialises all fields', () {
      final m = ApiErrorOldModel(
        titleTh: 'ท',
        titleEn: 'T',
        messageTh: ['ก'],
        messageEn: ['a'],
        serviceCode: 'C',
      );
      expect(m.toJson(), {
        'titleTh': 'ท',
        'titleEn': 'T',
        'messageTh': ['ก'],
        'messageEn': ['a'],
        'serviceCode': 'C',
      });
    });

    test('roundtrip from full json', () {
      final json = {
        'titleTh': 'ท',
        'titleEn': 'T',
        'messageTh': ['ก', 'ข'],
        'messageEn': ['a'],
        'serviceCode': 'C',
      };
      final out = ApiErrorOldModel.fromJson(json).toJson();
      expect(out['titleTh'], 'ท');
      expect(out['messageTh'], ['ก', 'ข']);
      expect(out['messageEn'], ['a']);
      expect(out['serviceCode'], 'C');
    });
  });

  group('top-level helpers', () {
    test('apiErrorModelFromJson parses string', () {
      final m = apiErrorModelFromJson(
        '{"titleTh":"t","messageTh":["x"],"messageEn":["y"],"serviceCode":"S"}',
      );
      expect(m.titleTh, 't');
      expect(m.messageTh, ['x']);
      expect(m.messageEn, ['y']);
      expect(m.serviceCode, 'S');
    });

    test('apiErrorModelToJson encodes to string', () {
      final str = apiErrorModelToJson(
        ApiErrorOldModel(
          titleTh: 't',
          titleEn: 'T',
          messageTh: ['x'],
          messageEn: ['y'],
          serviceCode: 'S',
        ),
      );
      expect(str.contains('"titleTh":"t"'), true);
      expect(str.contains('"messageTh":["x"]'), true);
    });
  });
}

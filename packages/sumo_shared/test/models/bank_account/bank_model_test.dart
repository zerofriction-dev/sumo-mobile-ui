import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/bank_account/bank_model.dart';

void main() {
  group('BankModel', () {
    test('fromJson with primary alias keys (id/name/imagePath/slug)', () {
      final b = BankModel.fromJson({
        'id': 'b1',
        'name': 'กสิกรไทย',
        'imagePath': 'http://img/kbank.png',
        'slug': 'kbank',
        'isActive': true,
        'sequence': 3,
      });
      expect(b.bankId, 'b1');
      expect(b.bankName, 'กสิกรไทย');
      expect(b.bankImage, 'http://img/kbank.png');
      expect(b.bankCode, 'kbank');
      expect(b.isActive, isTrue);
      expect(b.sequence, 3);
    });

    test(
      'fromJson with secondary alias keys (bankId/bankName/bankImage/bankCode)',
      () {
        final b = BankModel.fromJson({
          'bankId': 'b2',
          'bankName': 'ไทยพาณิชย์',
          'bankImage': 'http://img/scb.png',
          'bankCode': 'scb',
          'isActive': false,
          'sequence': 7,
        });
        expect(b.bankId, 'b2');
        expect(b.bankName, 'ไทยพาณิชย์');
        expect(b.bankImage, 'http://img/scb.png');
        expect(b.bankCode, 'scb');
        expect(b.isActive, isFalse);
        expect(b.sequence, 7);
      },
    );

    test('primary alias key takes precedence over secondary', () {
      final b = BankModel.fromJson({
        'id': 'primary',
        'bankId': 'secondary',
        'name': 'primaryName',
        'bankName': 'secondaryName',
        'imagePath': 'primaryImg',
        'bankImage': 'secondaryImg',
        'slug': 'primarySlug',
        'bankCode': 'secondaryCode',
      });
      expect(b.bankId, 'primary');
      expect(b.bankName, 'primaryName');
      expect(b.bankImage, 'primaryImg');
      expect(b.bankCode, 'primarySlug');
    });

    test('fromJson empty map applies defaults', () {
      final b = BankModel.fromJson({});
      expect(b.bankId, '');
      expect(b.bankName, '');
      expect(b.bankImage, '');
      expect(b.bankCode, '');
      expect(b.isActive, isTrue); // default true
      expect(b.sequence, 0);
    });

    test('fromJson null values fall back to defaults', () {
      final b = BankModel.fromJson({
        'id': null,
        'name': null,
        'imagePath': null,
        'slug': null,
        'isActive': null,
        'sequence': null,
      });
      expect(b.bankId, '');
      expect(b.bankName, '');
      expect(b.bankImage, '');
      expect(b.bankCode, '');
      expect(b.isActive, isTrue);
      expect(b.sequence, 0);
    });

    test('toJson emits canonical keys (id/name/imagePath/slug)', () {
      final b = BankModel(
        bankId: 'b1',
        bankName: 'กสิกรไทย',
        bankImage: 'img',
        bankCode: 'kbank',
        isActive: true,
        sequence: 2,
      );
      expect(b.toJson(), {
        'id': 'b1',
        'name': 'กสิกรไทย',
        'imagePath': 'img',
        'slug': 'kbank',
        'isActive': true,
        'sequence': 2,
      });
    });

    test('round-trip fromJson(toJson) preserves fields via canonical keys', () {
      final original = BankModel.fromJson({
        'id': 'b1',
        'name': 'กสิกรไทย',
        'imagePath': 'img',
        'slug': 'kbank',
        'isActive': false,
        'sequence': 5,
      });
      final round = BankModel.fromJson(original.toJson());
      expect(round.bankId, 'b1');
      expect(round.bankName, 'กสิกรไทย');
      expect(round.bankImage, 'img');
      expect(round.bankCode, 'kbank');
      expect(round.isActive, isFalse);
      expect(round.sequence, 5);
    });
  });
}

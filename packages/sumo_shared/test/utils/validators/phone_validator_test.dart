import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/validators/phone_validator.dart';

void main() {
  group('PhoneValidator.validate', () {
    test('empty string is invalid with no error message', () {
      final r = PhoneValidator.validate('');
      expect(r.isValid, false);
      expect(r.errorMessage, '');
    });

    test('string of only spaces/dashes is treated as empty', () {
      final r = PhoneValidator.validate('  -- ');
      expect(r.isValid, false);
      expect(r.errorMessage, '');
    });

    test('non-numeric input returns digits-only error', () {
      final r = PhoneValidator.validate('08abc12345');
      expect(r.isValid, false);
      expect(r.errorMessage, 'กรุณากรอกเฉพาะตัวเลข');
    });

    group('mobile numbers (08/09/06) require exactly 10 digits', () {
      test('valid 08 number with 10 digits', () {
        final r = PhoneValidator.validate('0861234567');
        expect(r.isValid, true);
        expect(r.errorMessage, '');
      });

      test('valid 09 number with 10 digits', () {
        final r = PhoneValidator.validate('0912345678');
        expect(r.isValid, true);
      });

      test('valid 06 number with 10 digits', () {
        final r = PhoneValidator.validate('0612345678');
        expect(r.isValid, true);
      });

      test('mobile with 9 digits is invalid', () {
        final r = PhoneValidator.validate('086123456');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์มือถือต้องมี 10 หลัก');
      });

      test('mobile with 11 digits is invalid', () {
        final r = PhoneValidator.validate('08612345678');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์มือถือต้องมี 10 หลัก');
      });

      test('strips spaces and dashes before validating', () {
        final r = PhoneValidator.validate('086-123-4567');
        expect(r.isValid, true);
      });

      test('strips spaces (XXX XXX XXXX) before validating', () {
        final r = PhoneValidator.validate('086 123 4567');
        expect(r.isValid, true);
      });
    });

    group('Bangkok landline (02) requires exactly 9 digits', () {
      test('valid 02 number with 9 digits', () {
        final r = PhoneValidator.validate('021234567');
        expect(r.isValid, true);
        expect(r.errorMessage, '');
      });

      test('02 with 10 digits is invalid', () {
        final r = PhoneValidator.validate('0212345678');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์บ้าน 02 ต้องมี 9 หลัก');
      });

      test('02 with 8 digits is invalid', () {
        final r = PhoneValidator.validate('02123456');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์บ้าน 02 ต้องมี 9 หลัก');
      });
    });

    group('provincial landline (03/04/05/07) requires 9-10 digits', () {
      test('valid 03 with 9 digits', () {
        final r = PhoneValidator.validate('031234567');
        expect(r.isValid, true);
      });

      test('valid 04 with 10 digits', () {
        final r = PhoneValidator.validate('0412345678');
        expect(r.isValid, true);
      });

      test('valid 05 with 9 digits', () {
        final r = PhoneValidator.validate('051234567');
        expect(r.isValid, true);
      });

      test('valid 07 with 10 digits', () {
        final r = PhoneValidator.validate('0712345678');
        expect(r.isValid, true);
      });

      test('provincial with 8 digits is invalid', () {
        final r = PhoneValidator.validate('03123456');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์บ้านต่างจังหวัดต้องมี 9-10 หลัก');
      });

      test('provincial with 11 digits is invalid', () {
        final r = PhoneValidator.validate('07123456789');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์บ้านต่างจังหวัดต้องมี 9-10 หลัก');
      });
    });

    group('forbidden / malformed starters', () {
      test('01 prefix is forbidden', () {
        final r = PhoneValidator.validate('0123456789');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์ขึ้นต้นด้วย 01 ไม่มีในประเทศไทย');
      });

      test('numbers not starting with 0 are invalid', () {
        final r = PhoneValidator.validate('1234567890');
        expect(r.isValid, false);
        expect(r.errorMessage, 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0');
      });

      test('00 prefix falls into generic invalid format', () {
        final r = PhoneValidator.validate('0012345678');
        expect(r.isValid, false);
        expect(r.errorMessage, 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
      });

      test('single 0 falls into generic invalid format', () {
        final r = PhoneValidator.validate('0');
        expect(r.isValid, false);
        expect(r.errorMessage, 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
      });
    });
  });

  group('PhoneValidator.isMobile', () {
    test('true for 08/09/06 prefixes', () {
      expect(PhoneValidator.isMobile('0861234567'), true);
      expect(PhoneValidator.isMobile('0912345678'), true);
      expect(PhoneValidator.isMobile('0612345678'), true);
    });

    test('false for landline prefixes', () {
      expect(PhoneValidator.isMobile('021234567'), false);
      expect(PhoneValidator.isMobile('031234567'), false);
    });

    test('strips spaces and dashes first', () {
      expect(PhoneValidator.isMobile('086-123-4567'), true);
    });

    test('false for empty', () {
      expect(PhoneValidator.isMobile(''), false);
    });
  });

  group('PhoneValidator.isLandline', () {
    test('true for 02/03/04/05/07 prefixes', () {
      expect(PhoneValidator.isLandline('021234567'), true);
      expect(PhoneValidator.isLandline('031234567'), true);
      expect(PhoneValidator.isLandline('041234567'), true);
      expect(PhoneValidator.isLandline('051234567'), true);
      expect(PhoneValidator.isLandline('071234567'), true);
    });

    test('false for mobile prefixes (06 not landline)', () {
      expect(PhoneValidator.isLandline('0861234567'), false);
      expect(PhoneValidator.isLandline('0612345678'), false);
    });

    test('strips spaces and dashes first', () {
      expect(PhoneValidator.isLandline('02-123-4567'), true);
    });

    test('false for empty', () {
      expect(PhoneValidator.isLandline(''), false);
    });
  });
}

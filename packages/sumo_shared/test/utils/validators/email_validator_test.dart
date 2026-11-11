import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/validators/email_validator.dart';

void main() {
  group('EmailValidator.validate — empty / whitespace', () {
    test('empty string → invalid, no error message', () {
      final r = EmailValidator.validate('');
      expect(r.isValid, false);
      expect(r.errorMessage, '');
    });

    test('whitespace-only → trims to empty → invalid, no error message', () {
      final r = EmailValidator.validate('   ');
      expect(r.isValid, false);
      expect(r.errorMessage, '');
    });
  });

  group('EmailValidator.validate — space check', () {
    test('email with embedded space → "อีเมลต้องไม่มีช่องว่าง"', () {
      // After trim, still contains internal space
      final r = EmailValidator.validate('user name@example.com');
      expect(r.isValid, false);
      expect(r.errorMessage, 'อีเมลต้องไม่มีช่องว่าง');
    });
  });

  group('EmailValidator.validate — missing @ check', () {
    test('no @ symbol → "อีเมลต้องมี @"', () {
      final r = EmailValidator.validate('usernameexample.com');
      expect(r.isValid, false);
      expect(r.errorMessage, 'อีเมลต้องมี @');
    });
  });

  group('EmailValidator.validate — regex format check', () {
    test('invalid format (no TLD) → "รูปแบบอีเมลไม่ถูกต้อง"', () {
      // Has @ but doesn't pass regex (no domain dot → regex fails before domain check)
      final r = EmailValidator.validate('user@domain');
      expect(r.isValid, false);
      expect(r.errorMessage, 'รูปแบบอีเมลไม่ถูกต้อง');
    });

    test('double @ → "รูปแบบอีเมลไม่ถูกต้อง"', () {
      final r = EmailValidator.validate('user@@example.com');
      expect(r.isValid, false);
      expect(r.errorMessage, 'รูปแบบอีเมลไม่ถูกต้อง');
    });

    test('starts with @ → "รูปแบบอีเมลไม่ถูกต้อง"', () {
      final r = EmailValidator.validate('@example.com');
      expect(r.isValid, false);
      expect(r.errorMessage, 'รูปแบบอีเมลไม่ถูกต้อง');
    });
  });

  group('EmailValidator.validate — length boundaries', () {
    // Length < 5 check comes AFTER regex check. A valid email shape is at minimum ~5 chars.
    // To hit the length < 5 branch we need something that passes regex but is < 5 chars.
    // The regex requires at least 1 local + @ + 1 domain + . + 2 TLD = 7 chars minimum,
    // so the < 5 branch is unreachable in practice via regex-passing inputs.
    // We test the > 254 boundary directly.
    test('email longer than 254 chars → "อีเมลยาวเกินไป"', () {
      // Build local part of 243 chars to total > 254 with @a.com (6 chars) → 249 chars is fine,
      // need > 254 so use 249 + @a.com = 255 total.
      final localPart = 'a' * 249;
      final longEmail = '$localPart@a.com'; // 249 + 6 = 255 chars
      expect(longEmail.length, greaterThan(254));
      final r = EmailValidator.validate(longEmail);
      expect(r.isValid, false);
      expect(r.errorMessage, 'อีเมลยาวเกินไป');
    });

    test('email exactly 254 chars → valid (boundary)', () {
      // 248 local + @a.com(6) = 254
      final localPart = 'a' * 248;
      final exactEmail = '$localPart@a.com';
      expect(exactEmail.length, 254);
      final r = EmailValidator.validate(exactEmail);
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });
  });

  group('EmailValidator.validate — happy path', () {
    test('standard valid email → valid', () {
      final r = EmailValidator.validate('user@example.com');
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });

    test('email with leading/trailing spaces is trimmed → valid', () {
      final r = EmailValidator.validate('  user@example.com  ');
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });

    test('email with subdomains → valid', () {
      final r = EmailValidator.validate('user@mail.example.co.th');
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });

    test('email with plus sign in local part → valid', () {
      final r = EmailValidator.validate('user+tag@example.com');
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });

    test('email with dots in local part → valid', () {
      final r = EmailValidator.validate('first.last@example.com');
      expect(r.isValid, true);
      expect(r.errorMessage, '');
    });
  });

  group('EmailValidator.getDomain', () {
    test('valid email → returns domain part', () {
      expect(EmailValidator.getDomain('user@example.com'), 'example.com');
    });

    test('no @ → returns null', () {
      expect(EmailValidator.getDomain('userexample.com'), isNull);
    });

    test('double @ → returns null (split length != 2)', () {
      expect(EmailValidator.getDomain('user@@example.com'), isNull);
    });

    test('empty string → returns null', () {
      expect(EmailValidator.getDomain(''), isNull);
    });
  });

  group('EmailValidator.getUsername', () {
    test('valid email → returns local part', () {
      expect(EmailValidator.getUsername('user@example.com'), 'user');
    });

    test('no @ → returns null', () {
      expect(EmailValidator.getUsername('userexample.com'), isNull);
    });

    test('double @ → returns null', () {
      expect(EmailValidator.getUsername('user@@example.com'), isNull);
    });

    test('empty string → returns null', () {
      expect(EmailValidator.getUsername(''), isNull);
    });

    test('leading space is trimmed before splitting', () {
      expect(EmailValidator.getUsername('  user@example.com'), 'user');
    });
  });
}

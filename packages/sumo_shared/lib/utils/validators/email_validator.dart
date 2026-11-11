/// Email validation utility
class EmailValidator {
  /// Regular expression for email validation
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email address and returns validation result
  ///
  /// Returns a [EmailValidationResult] containing:
  /// - isValid: whether the email is valid
  /// - errorMessage: error message if invalid, empty string if valid
  static EmailValidationResult validate(String email) {
    String trimmedEmail = email.trim();

    // ถ้าว่างเปล่า ไม่แสดง error
    if (trimmedEmail.isEmpty) {
      return EmailValidationResult(isValid: false, errorMessage: '');
    }

    // ต้องไม่มีช่องว่าง
    if (trimmedEmail.contains(' ')) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'อีเมลต้องไม่มีช่องว่าง',
      );
    }

    // ต้องมี @ symbol
    if (!trimmedEmail.contains('@')) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'อีเมลต้องมี @',
      );
    }

    // ตรวจสอบรูปแบบอีเมล
    if (!_emailRegExp.hasMatch(trimmedEmail)) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'รูปแบบอีเมลไม่ถูกต้อง',
      );
    }

    // ตรวจสอบความยาว
    if (trimmedEmail.length < 5) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'อีเมลสั้นเกินไป',
      );
    }

    if (trimmedEmail.length > 254) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'อีเมลยาวเกินไป',
      );
    }

    // ตรวจสอบว่ามี domain
    List<String> parts = trimmedEmail.split('@');
    if (parts.length != 2) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'รูปแบบอีเมลไม่ถูกต้อง',
      );
    }

    String domain = parts[1];
    if (!domain.contains('.')) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'โดเมนอีเมลไม่ถูกต้อง',
      );
    }

    // ผ่านการ validate
    return EmailValidationResult(isValid: true, errorMessage: '');
  }

  /// Extract domain from email
  /// Returns null if email is invalid
  static String? getDomain(String email) {
    String trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@')) return null;

    List<String> parts = trimmedEmail.split('@');
    if (parts.length != 2) return null;

    return parts[1];
  }

  /// Extract username from email
  /// Returns null if email is invalid
  static String? getUsername(String email) {
    String trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@')) return null;

    List<String> parts = trimmedEmail.split('@');
    if (parts.length != 2) return null;

    return parts[0];
  }
}

/// Result class for email validation
class EmailValidationResult {
  final bool isValid;
  final String errorMessage;

  EmailValidationResult({required this.isValid, required this.errorMessage});
}

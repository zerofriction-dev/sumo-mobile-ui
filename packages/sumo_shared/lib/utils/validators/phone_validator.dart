/// Phone number validation utility for Thai phone numbers
class PhoneValidator {
  /// Validates Thai phone number and returns validation result
  ///
  /// Returns a [PhoneValidationResult] containing:
  /// - isValid: whether the phone number is valid
  /// - errorMessage: error message if invalid, empty string if valid
  static PhoneValidationResult validate(String phoneNumber) {
    String phone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

    // ถ้าว่างเปล่า ไม่แสดง error
    if (phone.isEmpty) {
      return PhoneValidationResult(isValid: false, errorMessage: '');
    }

    // ต้องเป็นตัวเลขเท่านั้น
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'กรุณากรอกเฉพาะตัวเลข',
      );
    }

    // เบอร์มือถือ (08, 09, 06) - 10 หลัก
    if (phone.startsWith('08') ||
        phone.startsWith('09') ||
        phone.startsWith('06')) {
      if (phone.length != 10) {
        return PhoneValidationResult(
          isValid: false,
          errorMessage: 'เบอร์มือถือต้องมี 10 หลัก',
        );
      }
    }
    // เบอร์บ้าน กทม. (02) - 9 หลัก
    else if (phone.startsWith('02')) {
      if (phone.length != 9) {
        return PhoneValidationResult(
          isValid: false,
          errorMessage: 'เบอร์บ้าน 02 ต้องมี 9 หลัก',
        );
      }
    }
    // เบอร์บ้านต่างจังหวัด (03-07 ยกเว้น 06) - 9-10 หลัก
    else if (phone.startsWith('03') ||
        phone.startsWith('04') ||
        phone.startsWith('05') ||
        phone.startsWith('07')) {
      if (phone.length < 9 || phone.length > 10) {
        return PhoneValidationResult(
          isValid: false,
          errorMessage: 'เบอร์บ้านต่างจังหวัดต้องมี 9-10 หลัก',
        );
      }
    }
    // เบอร์ที่ไม่อนุญาต (01)
    else if (phone.startsWith('01')) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'เบอร์ขึ้นต้นด้วย 01 ไม่มีในประเทศไทย',
      );
    }
    // เบอร์อื่นๆ ที่ไม่ถูกต้อง
    else if (!phone.startsWith('0')) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0',
      );
    } else {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง',
      );
    }

    // ผ่านการ validate
    return PhoneValidationResult(isValid: true, errorMessage: '');
  }

  /// Check if the phone number is a mobile number (starts with 08, 09, or 06)
  static bool isMobile(String phoneNumber) {
    String phone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    return phone.startsWith('08') ||
        phone.startsWith('09') ||
        phone.startsWith('06');
  }

  /// Check if the phone number is a landline (starts with 02-07, excluding 06)
  static bool isLandline(String phoneNumber) {
    String phone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    return phone.startsWith('02') ||
        phone.startsWith('03') ||
        phone.startsWith('04') ||
        phone.startsWith('05') ||
        phone.startsWith('07');
  }
}

/// Result class for phone validation
class PhoneValidationResult {
  final bool isValid;
  final String errorMessage;

  PhoneValidationResult({required this.isValid, required this.errorMessage});
}

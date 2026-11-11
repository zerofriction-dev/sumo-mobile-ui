import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/constants/pin_verify_mode.dart';

void main() {
  group('PinVerifyMode', () {
    test('arguments carry the mode name under argumentKey', () {
      expect(PinVerifyMode.confirm.arguments, {'pinVerifyMode': 'confirm'});
      expect(PinVerifyMode.gate.arguments, {'pinVerifyMode': 'gate'});
    });

    test('fromArguments round-trips confirm', () {
      expect(
        PinVerifyMode.fromArguments(PinVerifyMode.confirm.arguments),
        PinVerifyMode.confirm,
      );
    });

    test('fromArguments falls back to gate', () {
      expect(PinVerifyMode.fromArguments(null), PinVerifyMode.gate);
      expect(PinVerifyMode.fromArguments('confirm'), PinVerifyMode.gate);
      expect(
        PinVerifyMode.fromArguments(<String, dynamic>{}),
        PinVerifyMode.gate,
      );
      expect(
        PinVerifyMode.fromArguments({'pinVerifyMode': 'other'}),
        PinVerifyMode.gate,
      );
      expect(
        PinVerifyMode.fromArguments(PinVerifyMode.gate.arguments),
        PinVerifyMode.gate,
      );
    });
  });
}

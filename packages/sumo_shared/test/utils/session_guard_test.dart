import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/session_guard.dart';

void main() {
  tearDown(() => SessionGuard.expiredInProgress = false);

  test('expiredInProgress defaults to false and is mutable', () {
    expect(SessionGuard.expiredInProgress, isFalse);
    SessionGuard.expiredInProgress = true;
    expect(SessionGuard.expiredInProgress, isTrue);
  });

  test('SessionEndReason values', () {
    expect(SessionEndReason.values, [
      SessionEndReason.expired,
      SessionEndReason.replaced,
    ]);
  });
}

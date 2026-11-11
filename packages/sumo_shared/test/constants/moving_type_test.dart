import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/constants/moving_type.dart';

void main() {
  group('MovingType enum values', () {
    test('etc has correct value and label', () {
      expect(MovingType.etc.value, 'etc');
      expect(MovingType.etc.label, 'อื่นๆ');
    });

    test('knockdownHouse has correct value and label', () {
      expect(MovingType.knockdownHouse.value, 'knockdown-house');
      expect(MovingType.knockdownHouse.label, 'บ้านน็อคดาว์น');
    });

    test('container has correct value and label', () {
      expect(MovingType.container.value, 'container');
      expect(MovingType.container.label, 'ตู้คอนเทรนเนอร์');
    });

    test('earthCompactor has correct value and label', () {
      expect(MovingType.earthCompactor.value, 'earth-compactor');
      expect(MovingType.earthCompactor.label, 'รถบดดิน');
    });

    test('machine has correct value and label', () {
      expect(MovingType.machine.value, 'machine');
      expect(MovingType.machine.label, 'เครื่องจักร');
    });

    test('car has correct value and label', () {
      expect(MovingType.car.value, 'car');
      expect(MovingType.car.label, 'รถยนต์');
    });

    test('motorcycle has correct value and label', () {
      expect(MovingType.motorcycle.value, 'motorcycle');
      expect(MovingType.motorcycle.label, 'รถมอเตอร์ไซค์');
    });

    test('all 7 values exist', () {
      expect(MovingType.values.length, 7);
    });
  });

  group('MovingType.fromString', () {
    test('returns correct enum for known values', () {
      expect(MovingType.fromString('etc'), MovingType.etc);
      expect(
        MovingType.fromString('knockdown-house'),
        MovingType.knockdownHouse,
      );
      expect(MovingType.fromString('container'), MovingType.container);
      expect(
        MovingType.fromString('earth-compactor'),
        MovingType.earthCompactor,
      );
      expect(MovingType.fromString('machine'), MovingType.machine);
      expect(MovingType.fromString('car'), MovingType.car);
      expect(MovingType.fromString('motorcycle'), MovingType.motorcycle);
    });

    test('is case-sensitive (no toLowerCase applied)', () {
      // fromString does NOT lowercase: 'car' matches but 'CAR' does not
      expect(MovingType.fromString('car'), MovingType.car);
      expect(MovingType.fromString('CAR'), isNull);
    });

    test('returns null for null input', () {
      expect(MovingType.fromString(null), isNull);
    });

    test('returns null for unknown string', () {
      expect(MovingType.fromString('unknown'), isNull);
      expect(MovingType.fromString(''), isNull);
    });
  });
}

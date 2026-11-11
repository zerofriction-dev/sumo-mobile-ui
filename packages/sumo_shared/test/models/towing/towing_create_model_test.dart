import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/towing/towing_create_model.dart';

void main() {
  group('TowingCreateModel.fromJson', () {
    test('fully populated maps every field', () {
      final json = {
        'licensePlateColor': 1,
        'licensePlateProvince': 10,
        'licensePlateNumber': 'กข 1234',
        'vehicleType': 'slide',
        'vehicleModel': 'Isuzu',
        'vehicleBrand': 'Isuzu',
        'vehicleColor': 3,
        'operatorId': 'op-1',
        'vehicleAddon': ['a', 'b'],
        'isFloorTray': true,
        'platformLength': 6.5,
        'platformWidth': 2.4,
        'platformWeight': 1500,
        'registrationDate': '2024-01-01',
      };
      final m = TowingCreateModel.fromJson(json);
      expect(m.licensePlateColor, 1);
      expect(m.licensePlateProvince, 10);
      expect(m.licensePlateNumber, 'กข 1234');
      expect(m.vehicleType, 'slide');
      expect(m.vehicleModel, 'Isuzu');
      expect(m.vehicleBrand, 'Isuzu');
      expect(m.vehicleColor, 3);
      expect(m.operatorId, 'op-1');
      expect(m.vehicleAddon, ['a', 'b']);
      expect(m.isFloorTray, true);
      expect(m.platformLength, 6.5);
      expect(m.platformWidth, 2.4);
      expect(m.platformWeight, 1500);
      expect(m.registrationDate, '2024-01-01');
    });

    test('empty map applies defaults', () {
      final m = TowingCreateModel.fromJson({});
      expect(m.licensePlateColor, 0);
      expect(m.licensePlateProvince, 0);
      expect(m.licensePlateNumber, '');
      expect(m.vehicleType, '');
      expect(m.vehicleModel, '');
      expect(m.vehicleBrand, '');
      expect(m.vehicleColor, 0);
      expect(m.operatorId, isNull);
      expect(m.vehicleAddon, isNull);
      expect(m.isFloorTray, false);
      expect(m.platformLength, 0);
      expect(m.platformWidth, 0);
      expect(m.platformWeight, 0);
      expect(m.registrationDate, '');
    });

    test('operatorId/vehicleAddon are passed through without default', () {
      final m = TowingCreateModel.fromJson({
        'operatorId': 'op-9',
        'vehicleAddon': 42,
      });
      expect(m.operatorId, 'op-9');
      expect(m.vehicleAddon, 42);
      // vehicleAddOn (capital O) is a separate field not read from JSON.
      expect(m.vehicleAddOn, isNull);
    });
  });

  group('TowingCreateModel.toJson', () {
    test('emits all fields', () {
      final m = TowingCreateModel(
        licensePlateColor: 1,
        licensePlateProvince: 10,
        licensePlateNumber: 'กข 1234',
        vehicleType: 'slide',
        vehicleModel: 'Isuzu',
        vehicleBrand: 'Isuzu',
        vehicleColor: 3,
        operatorId: 'op-1',
        vehicleAddon: ['a'],
        isFloorTray: true,
        platformLength: 6.5,
        platformWidth: 2.4,
        platformWeight: 1500,
        registrationDate: '2024-01-01',
      );
      final out = m.toJson();
      expect(out['licensePlateColor'], 1);
      expect(out['licensePlateProvince'], 10);
      expect(out['licensePlateNumber'], 'กข 1234');
      expect(out['vehicleType'], 'slide');
      expect(out['vehicleModel'], 'Isuzu');
      expect(out['vehicleBrand'], 'Isuzu');
      expect(out['vehicleColor'], 3);
      expect(out['operatorId'], 'op-1');
      expect(out['vehicleAddon'], ['a']);
      expect(out['isFloorTray'], true);
      expect(out['platformLength'], 6.5);
      expect(out['platformWidth'], 2.4);
      expect(out['platformWeight'], 1500);
      expect(out['registrationDate'], '2024-01-01');
    });

    test('registrationDate passes through when null', () {
      final m = TowingCreateModel(
        licensePlateColor: 0,
        licensePlateProvince: 0,
        licensePlateNumber: '',
        vehicleType: '',
        vehicleModel: '',
        vehicleBrand: '',
        vehicleColor: 0,
        operatorId: null,
        registrationDate: null,
      );
      expect(m.toJson()['registrationDate'], isNull);
    });
  });

  group('TowingCreateModel round-trip', () {
    test('fromJson(toJson) preserves key fields', () {
      final original = TowingCreateModel.fromJson({
        'licensePlateColor': 2,
        'licensePlateNumber': 'ขค 5678',
        'vehicleBrand': 'Hino',
        'platformWeight': 2000,
        'registrationDate': '2023-05-05',
      });
      final round = TowingCreateModel.fromJson(original.toJson());
      expect(round.licensePlateColor, 2);
      expect(round.licensePlateNumber, 'ขค 5678');
      expect(round.vehicleBrand, 'Hino');
      expect(round.platformWeight, 2000);
      expect(round.registrationDate, '2023-05-05');
    });
  });

  group('top-level helpers', () {
    test('towingModelFromJson parses a JSON object string', () {
      final str = jsonEncode({'licensePlateColor': 1, 'vehicleBrand': 'Isuzu'});
      final m = towingModelFromJson(str);
      expect(m, isA<TowingCreateModel>());
      expect(m.licensePlateColor, 1);
      expect(m.vehicleBrand, 'Isuzu');
    });

    test('towingModelToJson serializes a single model to a JSON string', () {
      final m = TowingCreateModel(
        licensePlateColor: 1,
        licensePlateProvince: 0,
        licensePlateNumber: 'กข 1234',
        vehicleType: 'slide',
        vehicleModel: 'Isuzu',
        vehicleBrand: 'Isuzu',
        vehicleColor: 0,
        operatorId: 'op-1',
      );
      final str = towingModelToJson(m);
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      expect(decoded['licensePlateColor'], 1);
      expect(decoded['vehicleBrand'], 'Isuzu');
      expect(decoded['operatorId'], 'op-1');
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/device/device_model.dart';

void main() {
  group('DeviceModel', () {
    test('fromJson fully populated maps every field', () {
      final d = DeviceModel.fromJson({
        'deviceId': 'dev-1',
        'brand': 'Samsung',
        'model': 'A34',
        'firebaseToken': 'fcm-token',
        'version': '2.1.5',
        'location': '13.75,100.5',
      });
      expect(d.deviceId, 'dev-1');
      expect(d.brand, 'Samsung');
      expect(d.model, 'A34');
      expect(d.firebaseToken, 'fcm-token');
      expect(d.version, '2.1.5');
      expect(d.location, '13.75,100.5');
    });

    test('fromJson empty map defaults every field to ""', () {
      final d = DeviceModel.fromJson({});
      expect(d.deviceId, '');
      expect(d.brand, '');
      expect(d.model, '');
      expect(d.firebaseToken, '');
      expect(d.version, '');
      expect(d.location, '');
    });

    test('fromJson null values fall back to ""', () {
      final d = DeviceModel.fromJson({
        'deviceId': null,
        'brand': null,
        'model': null,
        'firebaseToken': null,
        'version': null,
        'location': null,
      });
      expect(d.deviceId, '');
      expect(d.brand, '');
      expect(d.model, '');
      expect(d.firebaseToken, '');
      expect(d.version, '');
      expect(d.location, '');
    });

    test('toJson emits all fields', () {
      final d = DeviceModel(
        deviceId: 'dev-1',
        brand: 'Samsung',
        model: 'A34',
        firebaseToken: 'fcm',
        version: '2.1.5',
        location: 'loc',
      );
      expect(d.toJson(), {
        'deviceId': 'dev-1',
        'brand': 'Samsung',
        'model': 'A34',
        'firebaseToken': 'fcm',
        'version': '2.1.5',
        'location': 'loc',
      });
    });

    test('toJson coalesces null fields to "" (default constructor)', () {
      final d = DeviceModel();
      expect(d.toJson(), {
        'deviceId': '',
        'brand': '',
        'model': '',
        'firebaseToken': '',
        'version': '',
        'location': '',
      });
    });

    test('round-trip fromJson(toJson) preserves fields', () {
      final original = DeviceModel.fromJson({
        'deviceId': 'dev-9',
        'brand': 'Xiaomi',
        'model': 'Note 12',
        'firebaseToken': 'tok',
        'version': '1.0.0',
        'location': 'bkk',
      });
      final round = DeviceModel.fromJson(original.toJson());
      expect(round.deviceId, 'dev-9');
      expect(round.brand, 'Xiaomi');
      expect(round.model, 'Note 12');
      expect(round.firebaseToken, 'tok');
      expect(round.version, '1.0.0');
      expect(round.location, 'bkk');
    });
  });

  group('deviceModelFromJson / deviceModelToJson helpers', () {
    test('deviceModelFromJson parses a JSON object string', () {
      final str = jsonEncode({'deviceId': 'dev-1', 'brand': 'Samsung'});
      final d = deviceModelFromJson(str);
      expect(d, isA<DeviceModel>());
      expect(d.deviceId, 'dev-1');
      expect(d.brand, 'Samsung');
    });

    test('deviceModelToJson serializes to a JSON string', () {
      final d = DeviceModel(deviceId: 'dev-1', brand: 'Samsung');
      final str = deviceModelToJson(d);
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      expect(decoded['deviceId'], 'dev-1');
      expect(decoded['brand'], 'Samsung');
      expect(decoded['model'], '');
    });
  });
}

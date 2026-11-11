import 'dart:convert';

DeviceModel deviceModelFromJson(String str) =>
    DeviceModel.fromJson(json.decode(str));
String deviceModelToJson(DeviceModel data) => json.encode(data.toJson());

class DeviceModel {
  String? deviceId;
  String? brand;
  String? model;
  String? firebaseToken;
  String? version;
  String? location;

  DeviceModel({
    this.deviceId,
    this.brand,
    this.model,
    this.firebaseToken,
    this.version,
    this.location,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
    deviceId: json["deviceId"] ?? '',
    brand: json["brand"] ?? '',
    model: json["model"] ?? '',
    firebaseToken: json["firebaseToken"] ?? '',
    version: json["version"] ?? '',
    location: json["location"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId ?? '',
    "brand": brand ?? '',
    "model": model ?? '',
    "firebaseToken": firebaseToken ?? '',
    "version": version ?? '',
    "location": location ?? '',
  };
}

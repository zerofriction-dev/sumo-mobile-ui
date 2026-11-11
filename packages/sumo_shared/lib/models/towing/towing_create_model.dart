import 'dart:convert';

TowingCreateModel towingModelFromJson(String str) =>
    TowingCreateModel.fromJson(json.decode(str));
String towingModelToJson(TowingCreateModel data) => json.encode(data.toJson());

class TowingCreateModel {
  final int? licensePlateColor;
  final int? licensePlateProvince;
  final String? licensePlateNumber;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleBrand;
  final int? vehicleColor;
  final int? vehicleAddOn;
  // final dynamic companyId;
  final dynamic operatorId;
  final dynamic vehicleAddon;

  final bool? isFloorTray;
  final num? platformLength;
  final num? platformWidth;
  final num? platformWeight;
  final String? registrationDate;

  TowingCreateModel({
    required this.licensePlateColor,
    required this.licensePlateProvince,
    required this.licensePlateNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleBrand,
    required this.vehicleColor,
    this.vehicleAddOn,
    // required this.companyId,
    required this.operatorId,
    this.vehicleAddon,
    this.isFloorTray,
    this.platformLength,
    this.platformWidth,
    this.platformWeight,
    this.registrationDate,
  });

  factory TowingCreateModel.fromJson(Map<String, dynamic> json) =>
      TowingCreateModel(
        licensePlateColor: json["licensePlateColor"] ?? 0,
        licensePlateProvince: json["licensePlateProvince"] ?? 0,
        licensePlateNumber: json["licensePlateNumber"] ?? '',
        vehicleType: json["vehicleType"] ?? '',
        vehicleModel: json["vehicleModel"] ?? '',
        vehicleBrand: json["vehicleBrand"] ?? '',
        vehicleColor: json["vehicleColor"] ?? 0,
        // companyId: json["companyId"],
        operatorId: json["operatorId"],
        vehicleAddon: json["vehicleAddon"],

        isFloorTray: json["isFloorTray"] ?? false,
        platformLength: json["platformLength"] ?? 0,
        platformWidth: json["platformWidth"] ?? 0,
        platformWeight: json["platformWeight"] ?? 0,
        registrationDate: json["registrationDate"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "licensePlateColor": licensePlateColor,
    "licensePlateProvince": licensePlateProvince,
    "licensePlateNumber": licensePlateNumber,
    "vehicleType": vehicleType,
    "vehicleModel": vehicleModel,
    "vehicleBrand": vehicleBrand,
    "vehicleColor": vehicleColor,
    // "companyId": companyId,
    "operatorId": operatorId,
    "vehicleAddon": vehicleAddon,

    "isFloorTray": isFloorTray,
    "platformLength": platformLength,
    "platformWidth": platformWidth,
    "platformWeight": platformWeight,
    "registrationDate": registrationDate,
  };
}

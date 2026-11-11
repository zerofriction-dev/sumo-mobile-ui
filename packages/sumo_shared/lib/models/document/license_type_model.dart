import 'dart:convert';

List<LicenseTypeModel> licenseTypeModelFromJson(String str) =>
    List<LicenseTypeModel>.from(
      json.decode(str).map((x) => LicenseTypeModel.fromJson(x)),
    );
String licenseTypeModelToJson(List<LicenseTypeModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LicenseTypeModel {
  final String? valueListId;
  final String? valueListCode;
  final String? valueListName;
  final int? valueListTypeId;
  final String? valueListImage;
  final String? description;

  LicenseTypeModel({
    this.valueListId,
    this.valueListCode,
    this.valueListName,
    this.valueListTypeId,
    this.valueListImage,
    this.description,
  });

  factory LicenseTypeModel.fromJson(Map<String, dynamic> json) =>
      LicenseTypeModel(
        valueListId: json["valueListId"] ?? '',
        valueListCode: json["valueListCode"] ?? '',
        valueListName: json["valueListName"] ?? '',
        valueListTypeId: json["valueListTypeId"] ?? 0,
        valueListImage: json["valueListImage"] ?? '',
        description: json["description"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "valueListId": valueListId,
    "valueListCode": valueListCode,
    "valueListName": valueListName,
    "valueListTypeId": valueListTypeId,
    "valueListImage": valueListImage,
    "description": description,
  };
}

import 'dart:convert';

List<CompanyModel> companyModelFromJson(String str) => List<CompanyModel>.from(
  json.decode(str).map((x) => CompanyModel.fromJson(x)),
);
String companyModelToJson(List<CompanyModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CompanyModel {
  final String? companyId;
  final String? companyName;
  final String? companyLocation;
  final bool? isInternal;
  final bool? isLegal;
  final dynamic createdAt;
  final dynamic updatedAt;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.companyLocation,
    required this.isInternal,
    required this.isLegal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    companyId: json["companyId"],
    companyName: json["companyName"],
    companyLocation: json["companyLocation"],
    isInternal: json["isInternal"],
    isLegal: json["isLegal"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
  );

  Map<String, dynamic> toJson() => {
    "companyId": companyId,
    "companyName": companyName,
    "companyLocation": companyLocation,
    "isInternal": isInternal,
    "isLegal": isLegal,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };
}

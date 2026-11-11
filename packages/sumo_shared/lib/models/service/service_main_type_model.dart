import 'dart:convert';

List<ServiceMainTypeModel> serviceMainTypeModelFromJson(String str) =>
    List<ServiceMainTypeModel>.from(
      json.decode(str).map((x) => ServiceMainTypeModel.fromJson(x)),
    );
String serviceMainTypeModelToJson(List<ServiceMainTypeModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ServiceMainTypeModel {
  final String? id;
  final String? code;
  final String? serviceId;
  final String? name;
  final String? slug;
  final bool? isActive;
  final String? imagePath;
  final String? thumbnailPath;

  ServiceMainTypeModel({
    this.id,
    this.code,
    this.serviceId,
    this.name,
    this.slug,
    this.isActive,
    this.imagePath,
    this.thumbnailPath,
  });

  factory ServiceMainTypeModel.fromJson(Map<String, dynamic> json) =>
      ServiceMainTypeModel(
        id: json["id"] ?? '',
        code: json["code"] ?? '',
        serviceId: json["serviceId"] ?? '',
        name: json["name"] ?? '',
        slug: json["slug"] ?? '',
        isActive: json["isActive"] ?? false,
        imagePath: json["imagePath"] ?? '',
        thumbnailPath: json["thumbnailPath"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "code": code,
    "serviceId": serviceId,
    "name": name,
    "slug": slug,
    "isActive": isActive,
    "imagePath": imagePath,
    "thumbnailPath": thumbnailPath,
  };
}

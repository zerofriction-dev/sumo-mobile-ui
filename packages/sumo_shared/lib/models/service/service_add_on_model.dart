import 'dart:convert';

List<ServiceAddOnModel> serviceAddOnModelFromJson(String str) =>
    List<ServiceAddOnModel>.from(
      json.decode(str).map((x) => ServiceAddOnModel.fromJson(x)),
    );

String serviceAddOnModelToJson(List<ServiceAddOnModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ServiceAddOnModel {
  final String? id;
  final String? name;
  final String? slug;
  final String? imagePath;
  final String? thumbnailPath;
  final bool? isActive;
  final String? serviceId;

  ServiceAddOnModel({
    this.id,
    this.name,
    this.slug,
    this.imagePath,
    this.thumbnailPath,
    this.isActive,
    this.serviceId,
  });

  factory ServiceAddOnModel.fromJson(Map<String, dynamic> json) =>
      ServiceAddOnModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        slug: json["slug"] ?? '',
        imagePath: json["imagePath"] ?? '',
        thumbnailPath: json["thumbnailPath"] ?? '',
        isActive: json["isActive"] ?? false,
        serviceId: json["serviceId"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "slug": slug,
    "imagePath": imagePath,
    "thumbnailPath": thumbnailPath,
    "isActive": isActive,
    "serviceId": serviceId,
  };
}

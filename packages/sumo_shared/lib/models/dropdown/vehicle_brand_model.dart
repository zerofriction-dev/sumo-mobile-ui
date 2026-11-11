import 'dart:convert';

List<VehicleBrandModel> vehicleBrandModelFromJson(String str) =>
    List<VehicleBrandModel>.from(
      json.decode(str).map((x) => VehicleBrandModel.fromJson(x)),
    );
String vehicleBrandModelToJson(List<VehicleBrandModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VehicleBrandModel {
  final String? id;
  final String? name;
  final String? imagePath;
  final String? thumbnailPath;

  VehicleBrandModel({this.id, this.name, this.imagePath, this.thumbnailPath});

  factory VehicleBrandModel.fromJson(Map<String, dynamic> json) =>
      VehicleBrandModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        imagePath: json["imagePath"] ?? '',
        thumbnailPath: json["thumbnailPath"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "imagePath": imagePath,
    "thumbnailPath": thumbnailPath,
  };
}

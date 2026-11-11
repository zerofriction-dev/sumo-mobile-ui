import 'dart:convert';

List<VehicleModelModel> vehicleModelModelFromJson(String str) =>
    List<VehicleModelModel>.from(
      json.decode(str).map((x) => VehicleModelModel.fromJson(x)),
    );
String vehicleModelModelToJson(List<VehicleModelModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VehicleModelModel {
  final String? id;
  final String? name;
  final String? brandId;

  VehicleModelModel({this.id, this.name, this.brandId});

  factory VehicleModelModel.fromJson(Map<String, dynamic> json) =>
      VehicleModelModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        brandId: json["brandId"] ?? '',
      );

  Map<String, dynamic> toJson() => {"id": id, "name": name, "brandId": brandId};
}

import 'dart:convert';

List<LicensePlateModel> licensePlateModelFromJson(String str) =>
    List<LicensePlateModel>.from(
      json.decode(str).map((x) => LicensePlateModel.fromJson(x)),
    );

String licensePlateModelToJson(List<LicensePlateModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LicensePlateModel {
  final String? id;
  final String? name;
  final String? imagePath;
  final String? slug;
  final bool? isActive;
  final int? sequent;
  final String? color;

  LicensePlateModel({
    this.id,
    this.name,
    this.imagePath,
    this.slug,
    this.isActive,
    this.sequent,
    this.color,
  });

  factory LicensePlateModel.fromJson(Map<String, dynamic> json) =>
      LicensePlateModel(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
        imagePath: json["imagePath"] ?? '',
        slug: json["slug"] ?? '',
        isActive: json["isActive"] ?? false,
        sequent: json["sequent"] ?? 0,
        color: json["color"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "imagePath": imagePath,
    "slug": slug,
    "isActive": isActive,
    "sequent": sequent,
    "color": color,
  };
}

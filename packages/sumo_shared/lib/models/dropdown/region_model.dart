import 'dart:convert';

List<RegionModel> regionModelFromJson(String str) => List<RegionModel>.from(
  json.decode(str).map((x) => RegionModel.fromJson(x)),
);

String regionModelToJson(List<RegionModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RegionModel {
  final int? regionId;
  final String? regionNameTh;
  final String? regionNameEn;

  RegionModel({
    required this.regionId,
    required this.regionNameTh,
    required this.regionNameEn,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) => RegionModel(
    regionId: json["regionId"] ?? 0,
    regionNameTh: json["regionNameTh"] ?? '',
    regionNameEn: json["regionNameEn"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "regionId": regionId,
    "regionNameTh": regionNameTh,
    "regionNameEn": regionNameEn,
  };
}

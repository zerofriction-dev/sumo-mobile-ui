import 'dart:convert';

List<GenderModel> genderModelFromJson(String str) => List<GenderModel>.from(
  json.decode(str).map((x) => GenderModel.fromJson(x)),
);

String genderModelToJson(List<GenderModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GenderModel {
  final String? type;
  final String? name;
  final List<Prefix>? prefix;

  GenderModel({this.type, this.name, this.prefix});

  factory GenderModel.fromJson(Map<String, dynamic> json) => GenderModel(
    type: json["type"] ?? '',
    name: json["name"] ?? '',
    prefix: json["prefix"] != null
        ? List<Prefix>.from(json["prefix"].map((x) => Prefix.fromJson(x)))
        : [],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "name": name,
    "prefix": List<dynamic>.from(prefix!.map((x) => x.toJson())),
  };
}

class Prefix {
  final String? prefixName;

  Prefix({this.prefixName});

  factory Prefix.fromJson(Map<String, dynamic> json) =>
      Prefix(prefixName: json["prefixName"] ?? '');

  Map<String, dynamic> toJson() => {"prefixName": prefixName};
}

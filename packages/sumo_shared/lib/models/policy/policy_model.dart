import 'dart:convert';

List<PolicyModel> policyModelFromJson(String str) => List<PolicyModel>.from(
  json.decode(str).map((x) => PolicyModel.fromJson(x)),
);
String policyModelToJson(List<PolicyModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PolicyModel {
  final String? id;
  final String? name;
  final String? description;
  final int? sequent;
  final int? version;

  PolicyModel({
    this.id,
    this.name,
    this.description,
    this.sequent,
    this.version,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) => PolicyModel(
    id: json["id"] ?? '',
    name: json["name"] ?? '',
    description: json["description"] ?? '',
    sequent: json["sequent"] ?? 0,
    version: json["version"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "sequent": sequent,
    "version": version,
  };
}

// To parse this JSON data, do
//
//     final selectCancelModel = selectCancelModelFromJson(jsonString);

import 'dart:convert';

List<SelectCancelModel> selectCancelModelFromJson(String str) =>
    List<SelectCancelModel>.from(
      json.decode(str).map((x) => SelectCancelModel.fromJson(x)),
    );

String selectCancelModelToJson(List<SelectCancelModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SelectCancelModel {
  int? id;
  String? detail;

  SelectCancelModel({this.id, this.detail});

  factory SelectCancelModel.fromJson(Map<String, dynamic> json) =>
      SelectCancelModel(id: json["id"] ?? 0, detail: json["detail"] ?? '');

  Map<String, dynamic> toJson() => {"id": id, "detail": detail};
}

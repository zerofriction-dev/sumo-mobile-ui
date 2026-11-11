import 'dart:convert';

ApiErrorOldModel apiErrorModelFromJson(String str) =>
    ApiErrorOldModel.fromJson(json.decode(str));
String apiErrorModelToJson(ApiErrorOldModel data) => json.encode(data.toJson());

class ApiErrorOldModel {
  String? titleTh;
  String? titleEn;
  List<String>? messageTh;
  List<String>? messageEn;
  String? serviceCode;

  ApiErrorOldModel({
    this.titleTh,
    this.titleEn,
    this.messageTh,
    this.messageEn,
    this.serviceCode,
  });

  factory ApiErrorOldModel.fromJson(Map<String, dynamic> json) =>
      ApiErrorOldModel(
        titleTh: json["titleTh"] ?? "",
        titleEn: json["titleEn"] ?? "",
        messageTh: json["messageTh"] != null
            ? List<String>.from(json["messageTh"].map((x) => x))
            : [],
        messageEn: json["messageEn"] != null
            ? List<String>.from(json["messageEn"].map((x) => x))
            : [],
        serviceCode: json["serviceCode"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "titleTh": titleTh,
    "titleEn": titleEn,
    "messageTh": List<dynamic>.from(messageTh!.map((x) => x)),
    "messageEn": List<dynamic>.from(messageEn!.map((x) => x)),
    "serviceCode": serviceCode,
  };
}

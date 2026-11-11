import 'dart:convert';

ApiErrorModel apiErrorModelFromJson(String str) =>
    ApiErrorModel.fromJson(json.decode(str));
String apiErrorModelToJson(ApiErrorModel data) => json.encode(data.toJson());

class ApiErrorModel {
  bool? success;
  String? message;

  ApiErrorModel({this.success, this.message});

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) => ApiErrorModel(
    success: json["success"] ?? false,
    message: json["message"] ?? '',
  );

  Map<String, dynamic> toJson() => {"success": success, "message": message};
}

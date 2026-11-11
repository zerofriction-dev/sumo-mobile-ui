import 'dart:convert';

List<NotificationModel> notificationModelFromJson(String str) =>
    List<NotificationModel>.from(
      json.decode(str).map((x) => NotificationModel.fromJson(x)),
    );
String notificationModelToJson(List<NotificationModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class NotificationModel {
  final String? id;
  final String? group;
  final String? type;
  final String? action;
  final String? title;
  final String? body;
  String? isAcknowledge;
  final String? createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    this.id,
    this.group,
    this.type,
    this.action,
    this.title,
    this.body,
    this.isAcknowledge,
    this.createdAt,
    this.data,
  });

  bool get isRead => isAcknowledge == 'true';

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json["id"] ?? '',
        group: json["group"] ?? '',
        type: json["type"] ?? '',
        action: json["action"] ?? '',
        title: json["title"] ?? '',
        body: json["body"] ?? '',
        isAcknowledge: json["isAcknowledge"] ?? '',
        createdAt: json["createdAt"] ?? '',
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'])
            : {},
      );

  Map<String, dynamic> toJson() => {
    "id": id ?? '',
    "group": group ?? '',
    "type": type ?? '',
    "action": action ?? '',
    "title": title ?? '',
    "body": body ?? '',
    "isAcknowledge": isAcknowledge ?? '',
    "createdAt": createdAt ?? '',
    "data": data,
  };
}

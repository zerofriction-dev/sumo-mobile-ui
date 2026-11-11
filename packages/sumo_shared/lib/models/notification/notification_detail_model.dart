import 'dart:convert';

NotificationDetailModel notificationDetailModelFromJson(String str) =>
    NotificationDetailModel.fromJson(json.decode(str));
String notificationDetailModelToJson(NotificationDetailModel data) =>
    json.encode(data.toJson());

class NotificationDetailModel {
  final String? id;
  final String? group;
  final String? type;
  final String? action;
  final String? title;
  final String? body;
  final String? isAcknowledge;
  final String? createdAt;
  final NotificationDetailData? data;

  NotificationDetailModel({
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

  factory NotificationDetailModel.fromJson(Map<String, dynamic> json) =>
      NotificationDetailModel(
        id: json["id"] ?? '',
        group: json["group"] ?? '',
        type: json["type"] ?? '',
        action: json["action"] ?? '',
        title: json["title"] ?? '',
        body: json["body"] ?? '',
        isAcknowledge: json["isAcknowledge"] ?? '',
        createdAt: json["createdAt"] ?? '',
        data: json["data"] != null
            ? NotificationDetailData.fromJson(json["data"])
            : null,
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
    "data": data?.toJson(),
  };
}

class NotificationDetailData {
  final String? buttonLabel;
  final String? buttonUrl;
  final String? category;
  final String? description;
  final String? imagePath;
  final String? notificationId;
  final String? notificationType;
  final String? showButton;
  final String? targetPath;

  NotificationDetailData({
    this.buttonLabel,
    this.buttonUrl,
    this.category,
    this.description,
    this.imagePath,
    this.notificationId,
    this.notificationType,
    this.showButton,
    this.targetPath,
  });

  factory NotificationDetailData.fromJson(Map<String, dynamic> json) =>
      NotificationDetailData(
        buttonLabel: json["buttonLabel"] ?? '',
        buttonUrl: json["buttonUrl"] ?? '',
        category: json["category"] ?? '',
        description: json["description"] ?? '',
        imagePath: json["imagePath"] ?? '',
        notificationId: json["notificationId"] ?? '',
        notificationType: json["notificationType"] ?? '',
        showButton: json["showButton"] ?? '',
        targetPath: json["targetPath"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "buttonLabel": buttonLabel ?? '',
    "buttonUrl": buttonUrl ?? '',
    "category": category ?? '',
    "description": description ?? '',
    "imagePath": imagePath ?? '',
    "notificationId": notificationId ?? '',
    "notificationType": notificationType ?? '',
    "showButton": showButton ?? '',
    "targetPath": targetPath ?? '',
  };
}

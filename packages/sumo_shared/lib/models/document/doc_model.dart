import 'dart:convert';

DocumentAllModel documentAllModelFromJson(String str) =>
    DocumentAllModel.fromJson(json.decode(str));
String documentAllModelToJson(DocumentAllModel data) =>
    json.encode(data.toJson());

class DocumentAllModel {
  List<Documents>? documents;

  DocumentAllModel({this.documents});

  factory DocumentAllModel.fromJson(Map<String, dynamic> json) =>
      DocumentAllModel(
        documents: json["documents"] != null
            ? List<Documents>.from(
                json["documents"].map((x) => Documents.fromJson(x)),
              )
            : [],
      );

  Map<String, dynamic> toJson() => {
    "documents": List<dynamic>.from(documents!.map((x) => x.toJson())),
  };
}

class Documents {
  String? id;
  String? route;
  String? name;
  String? path;
  String? thumbnailPath;
  String? imgEx;
  Status? status;
  Type? type;
  LicenseType? licenseType;
  String? createdAt;
  String? createdBy;
  String? expiredAt;
  String? expiredStatus;

  Documents({
    this.id,
    this.route,
    this.name,
    this.path,
    this.thumbnailPath,
    this.imgEx,
    this.status,
    this.type,
    this.licenseType,
    this.createdAt,
    this.createdBy,
    this.expiredAt,
    this.expiredStatus,
  });

  factory Documents.fromJson(Map<String, dynamic> json) => Documents(
    id: json["id"] ?? '',
    route: json["route"] ?? '',
    name: json["name"] ?? '',
    path: json["path"] ?? '',
    thumbnailPath: json["thumbnailPath"] ?? '',
    imgEx: json["imgEx"] ?? '',
    status: Status.fromJson(json["status"] ?? {}),
    type: Type.fromJson(json["type"] ?? {}),
    licenseType: LicenseType.fromJson(json["licenseType"] ?? {}),
    createdAt: json["createdAt"] ?? '',
    createdBy: json["createdBy"] ?? '',
    expiredAt: json["expiredAt"] ?? '',
    expiredStatus: json["expiredStatus"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "id": id ?? '',
    "route": route ?? '',
    "name": name ?? '',
    "path": path ?? '',
    "thumbnailPath": thumbnailPath ?? '',
    "imgEx": imgEx ?? '',
    "status": status!.toJson(),
    "type": type!.toJson(),
    "licenseType": licenseType!.toJson(),
    "createdAt": createdAt ?? '',
    "createdBy": createdBy ?? '',
    "expiredAt": expiredAt ?? '',
    "expiredStatus": expiredStatus ?? '',
  };
}

class Status {
  String? id;
  String? name;
  String? color;

  Status({this.id, this.name, this.color});

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    id: json["id"] ?? '',
    name: json["name"] ?? '',
    color: json["color"] ?? '',
  );

  Map<String, dynamic> toJson() => {"id": id, "name": name, "color": color};
}

class Type {
  String? id;
  String? name;

  Type({this.id, this.name});

  factory Type.fromJson(Map<String, dynamic> json) =>
      Type(id: json["id"] ?? '', name: json["name"] ?? '');

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class LicenseType {
  final String? id;
  final String? name;

  LicenseType({this.id, this.name});

  factory LicenseType.fromJson(Map<String, dynamic> json) =>
      LicenseType(id: json["id"] ?? '', name: json["name"] ?? '');

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

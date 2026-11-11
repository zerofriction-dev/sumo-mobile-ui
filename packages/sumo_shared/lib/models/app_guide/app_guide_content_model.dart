import 'dart:convert';

AppGuideContentModel appGuideContentModelFromJson(String str) =>
    AppGuideContentModel.fromJson(json.decode(str));

String appGuideContentModelToJson(AppGuideContentModel data) =>
    json.encode(data.toJson());

const String kAppGuideMediaTypeWebp = 'webp';

class AppGuideStepModel {
  final String? text;
  final int? startMs;

  const AppGuideStepModel({this.text, this.startMs});

  factory AppGuideStepModel.fromJson(Map<String, dynamic> json) =>
      AppGuideStepModel(
        text: json["text"] ?? '',
        startMs: appGuideToInt(json["startMs"]) ?? 0,
      );

  Map<String, dynamic> toJson() => {"text": text, "startMs": startMs};
}

class AppGuideMediaModel {
  final String? type;
  final String? url;
  final int? width;
  final int? height;
  final int? durationMs;
  final int? bytes;

  const AppGuideMediaModel({
    this.type,
    this.url,
    this.width,
    this.height,
    this.durationMs,
    this.bytes,
  });

  factory AppGuideMediaModel.fromJson(Map<String, dynamic> json) =>
      AppGuideMediaModel(
        type: json["type"] ?? '',
        url: json["url"] ?? '',
        width: appGuideToInt(json["width"]),
        height: appGuideToInt(json["height"]),
        durationMs: appGuideToInt(json["durationMs"]),
        bytes: appGuideToInt(json["bytes"]),
      );

  Map<String, dynamic> toJson() => {
    "type": type,
    "url": url,
    "width": width,
    "height": height,
    "durationMs": durationMs,
    "bytes": bytes,
  };

  bool get isWebp => type == kAppGuideMediaTypeWebp;

  bool get hasUrl => (url ?? '').isNotEmpty;
}

class AppGuideContentModel {
  final int? version;
  final int? revision;
  final String? title;
  final String? subtitle;
  final List<AppGuideStepModel>? steps;
  final AppGuideMediaModel? media;
  final String? minAppVersion;

  const AppGuideContentModel({
    this.version,
    this.revision,
    this.title,
    this.subtitle,
    this.steps,
    this.media,
    this.minAppVersion,
  });

  factory AppGuideContentModel.fromJson(Map<String, dynamic> json) =>
      AppGuideContentModel(
        version: appGuideToInt(json["version"]),
        revision: appGuideToInt(json["revision"]),
        title: json["title"] ?? '',
        subtitle: json["subtitle"] ?? '',
        steps: json["steps"] is List
            ? List<AppGuideStepModel>.from(
                (json["steps"] as List).whereType<Map>().map(
                  (x) =>
                      AppGuideStepModel.fromJson(Map<String, dynamic>.from(x)),
                ),
              )
            : <AppGuideStepModel>[],
        media: json["media"] is Map
            ? AppGuideMediaModel.fromJson(
                Map<String, dynamic>.from(json["media"]),
              )
            : null,
        minAppVersion: json["minAppVersion"] is String
            ? json["minAppVersion"]
            : null,
      );

  Map<String, dynamic> toJson() => {
    "version": version,
    "revision": revision,
    "title": title,
    "subtitle": subtitle,
    "steps": List<dynamic>.from(
      (steps ?? const <AppGuideStepModel>[]).map((x) => x.toJson()),
    ),
    "media": media?.toJson(),
    "minAppVersion": minAppVersion,
  };

  int get versionNumber => version ?? 0;

  List<AppGuideStepModel> get stepList => steps ?? const <AppGuideStepModel>[];

  bool get isPlayable =>
      versionNumber > 0 &&
      stepList.isNotEmpty &&
      (media?.isWebp ?? false) &&
      (media?.hasUrl ?? false);
}

int? appGuideToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

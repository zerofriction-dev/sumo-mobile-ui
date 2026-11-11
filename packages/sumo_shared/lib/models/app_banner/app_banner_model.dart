import 'dart:convert';

AppBannerModel appBannerModelFromJson(String str) =>
    AppBannerModel.fromJson(json.decode(str));

String appBannerModelToJson(AppBannerModel data) => json.encode(data.toJson());

abstract class AppBannerLinkType {
  AppBannerLinkType._();

  static const String app = 'app';
  static const String page = 'page';
  static const String internalUrl = 'internal_url';
}

/// ตำแหน่งที่แบนเนอร์ถูกวางในแอป — ส่งเป็น query param `placement` ตอนขอรายการ
/// (`GET /app-banners/active?placement=...`) ถ้าไม่ส่ง หลังบ้าน default เป็น
/// [popup] ⇒ หน้าที่ใช้คารูเซลต้องส่ง [homeCarousel] เองเสมอ ไม่งั้นจะได้
/// แบนเนอร์ของ popup มาแสดงผิดที่
abstract class AppBannerPlacement {
  AppBannerPlacement._();

  static const String popup = 'popup';
  static const String homeCarousel = 'home_carousel';
}

class AppBannerModel {
  final String? id;
  final String? imagePath;
  final String? linkType;
  final String? linkTarget;
  final String? buttonLabel;

  AppBannerModel({
    this.id,
    this.imagePath,
    this.linkType,
    this.linkTarget,
    this.buttonLabel,
  });

  factory AppBannerModel.fromJson(Map<String, dynamic> json) => AppBannerModel(
    id: json["id"]?.toString() ?? '',
    imagePath: json["imagePath"]?.toString() ?? '',
    linkType: json["linkType"]?.toString() ?? '',
    linkTarget: json["linkTarget"]?.toString() ?? '',
    buttonLabel: json["buttonLabel"]?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    "id": id ?? '',
    "imagePath": imagePath ?? '',
    "linkType": linkType ?? '',
    "linkTarget": linkTarget ?? '',
    "buttonLabel": buttonLabel ?? '',
  };

  bool get hasButton => (linkType ?? '').isNotEmpty;

  bool get isRenderable =>
      (id ?? '').isNotEmpty && (imagePath ?? '').isNotEmpty;
}

List<AppBannerModel> appBannerListFromResponse(dynamic body) {
  final dynamic raw = body is Map ? body['data'] : body;
  if (raw is! List) return <AppBannerModel>[];
  return raw
      .whereType<Map>()
      .map(
        (Map item) => AppBannerModel.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((AppBannerModel banner) => banner.isRenderable)
      .toList();
}

class BankModel {
  final String? bankId;
  final String? bankName;
  final String? bankImage;
  final String? bankCode;
  final bool? isActive;
  final int? sequence;

  BankModel({
    this.bankId,
    this.bankName,
    this.bankImage,
    this.bankCode,
    this.isActive,
    this.sequence,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
    bankId: json["id"] ?? json["bankId"] ?? "",
    bankName: json["name"] ?? json["bankName"] ?? "",
    bankImage: json["imagePath"] ?? json["bankImage"] ?? "",
    bankCode: json["slug"] ?? json["bankCode"] ?? "",
    isActive: json["isActive"] ?? true,
    sequence: json["sequence"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": bankId,
    "name": bankName,
    "imagePath": bankImage,
    "slug": bankCode,
    "isActive": isActive,
    "sequence": sequence,
  };
}

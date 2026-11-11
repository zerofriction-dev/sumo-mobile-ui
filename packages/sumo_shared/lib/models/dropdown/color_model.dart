import 'dart:convert';

List<ColorModel> colorModelFromJson(String str) =>
    List<ColorModel>.from(json.decode(str).map((x) => ColorModel.fromJson(x)));

String colorModelToJson(List<ColorModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ColorModel {
  final String? id;
  final String? name;
  final String? colorHex;

  ColorModel({this.id, this.name, this.colorHex});

  factory ColorModel.fromJson(Map<String, dynamic> json) => ColorModel(
    id: json["id"] ?? '',
    name: json["name"] ?? '',
    colorHex: json["colorHex"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "colorHex": colorHex,
  };

  static List<ColorModel> defaultColors = [
    ColorModel(id: '1', name: 'ขาว', colorHex: '#FFFFFF'),
    ColorModel(id: '2', name: 'ดำ', colorHex: '#000000'),
    ColorModel(id: '3', name: 'เงิน', colorHex: '#C0C0C0'),
    ColorModel(id: '4', name: 'เทา', colorHex: '#808080'),
    ColorModel(id: '5', name: 'แดง', colorHex: '#FF0000'),
    ColorModel(id: '6', name: 'น้ำเงิน', colorHex: '#0000FF'),
    ColorModel(id: '7', name: 'ฟ้า', colorHex: '#87CEEB'),
    ColorModel(id: '8', name: 'เขียว', colorHex: '#008000'),
    ColorModel(id: '9', name: 'เหลือง', colorHex: '#FFFF00'),
    ColorModel(id: '10', name: 'ส้ม', colorHex: '#FFA500'),
    ColorModel(id: '11', name: 'ชมพู', colorHex: '#FFC0CB'),
    ColorModel(id: '12', name: 'ม่วง', colorHex: '#800080'),
    ColorModel(id: '13', name: 'น้ำตาล', colorHex: '#8B4513'),
    ColorModel(id: '14', name: 'ทอง', colorHex: '#FFD700'),
    ColorModel(id: '15', name: 'ครีม', colorHex: '#FFFDD0'),
    ColorModel(id: '16', name: 'บรอนซ์', colorHex: '#CD7F32'),
    ColorModel(id: '17', name: 'เบจ', colorHex: '#F5F5DC'),
    ColorModel(id: '18', name: 'เขียวมะกอก', colorHex: '#556B2F'),
    ColorModel(id: '19', name: 'น้ำเงินเข้ม', colorHex: '#00008B'),
    ColorModel(id: '20', name: 'แดงเข้ม', colorHex: '#8B0000'),
  ];
}

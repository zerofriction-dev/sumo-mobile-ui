import 'dart:convert';

Map<String, dynamic> decodeJwtPayload(String? token) {
  if (token == null || token.isEmpty) return {};
  final parts = token.split('.');
  if (parts.length != 3) return {};
  try {
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decoded = utf8.decode(base64.decode(payload));
    final map = json.decode(decoded);
    return map is Map<String, dynamic> ? map : {};
  } catch (_) {
    return {};
  }
}

bool isDebugToken(String? token) => decodeJwtPayload(token)['mode'] == 'debug';

String? impersonatorNameFromToken(String? token) {
  final act = decodeJwtPayload(token)['act'];
  if (act is Map && act['name'] is String) {
    return act['name'] as String;
  }
  return null;
}

/// เวลาหมดอายุ (`exp`) ของ JWT หรือ `null` ถ้าถอดไม่ได้/ไม่มี `exp`
/// (ถอดเองจาก payload ไม่ตรวจลายเซ็น — ใช้ตัดสินว่าควรต่ออายุก่อนใช้เท่านั้น)
DateTime? jwtExpiry(String? token) {
  final exp = decodeJwtPayload(token)['exp'];
  if (exp is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt(), isUtc: true);
}

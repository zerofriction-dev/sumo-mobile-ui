import 'dart:convert';
import 'package:flutter/services.dart';

class JsonLoader {
  static const String _basePath = 'lib/assets/data';

  static Future<List<dynamic>> loadList(String fileName) async {
    final jsonString = await rootBundle.loadString('$_basePath/$fileName');
    return json.decode(jsonString) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> loadMap(String fileName) async {
    final jsonString = await rootBundle.loadString('$_basePath/$fileName');
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

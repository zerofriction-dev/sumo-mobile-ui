import 'dart:convert';
import 'package:dio/dio.dart';

String prettyPrint(dynamic data) {
  try {
    if (data is String) {
      try {
        final decoded = json.decode(data);
        return JsonEncoder.withIndent('  ').convert(decoded);
      } catch (e) {
        return data;
      }
    } else if (data is Map || data is List) {
      return JsonEncoder.withIndent('  ').convert(data);
    } else if (data is FormData) {
      Map<String, dynamic> formDataMap = {};
      for (final element in data.fields) {
        formDataMap[element.key] = element.value;
      }
      for (final element in data.files) {
        formDataMap[element.key] = "File: ${element.value.filename}";
      }
      return JsonEncoder.withIndent('  ').convert(formDataMap);
    } else {
      return data.toString();
    }
  } catch (e) {
    return 'Error formatting data: $e';
  }
}

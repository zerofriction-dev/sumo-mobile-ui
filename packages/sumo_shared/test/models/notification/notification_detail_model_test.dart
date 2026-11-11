import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/notification/notification_detail_model.dart';

void main() {
  group('NotificationDetailModel', () {
    const fullJson = {
      "id": "n1",
      "group": "promotion",
      "type": "info",
      "action": "open",
      "title": "หัวข้อ",
      "body": "เนื้อหา",
      "isAcknowledge": "true",
      "createdAt": "2026-06-12T10:00:00Z",
      "data": {
        "buttonLabel": "กดที่นี่",
        "buttonUrl": "https://example.com",
        "category": "news",
        "description": "รายละเอียด",
        "imagePath": "img/x.png",
        "notificationId": "nid-1",
        "notificationType": "promo",
        "showButton": "true",
        "targetPath": "/home",
      },
    };

    test('fromJson fully populated maps all fields and nested data', () {
      final model = NotificationDetailModel.fromJson(fullJson);
      expect(model.id, "n1");
      expect(model.group, "promotion");
      expect(model.type, "info");
      expect(model.action, "open");
      expect(model.title, "หัวข้อ");
      expect(model.body, "เนื้อหา");
      expect(model.isAcknowledge, "true");
      expect(model.createdAt, "2026-06-12T10:00:00Z");
      expect(model.data, isNotNull);
      expect(model.data!.buttonLabel, "กดที่นี่");
      expect(model.data!.buttonUrl, "https://example.com");
      expect(model.data!.category, "news");
      expect(model.data!.description, "รายละเอียด");
      expect(model.data!.imagePath, "img/x.png");
      expect(model.data!.notificationId, "nid-1");
      expect(model.data!.notificationType, "promo");
      expect(model.data!.showButton, "true");
      expect(model.data!.targetPath, "/home");
    });

    test('fromJson empty map uses empty-string defaults and null data', () {
      final model = NotificationDetailModel.fromJson({});
      expect(model.id, '');
      expect(model.group, '');
      expect(model.type, '');
      expect(model.action, '');
      expect(model.title, '');
      expect(model.body, '');
      expect(model.isAcknowledge, '');
      expect(model.createdAt, '');
      expect(model.data, isNull);
    });

    test('fromJson null data keeps data null', () {
      final model = NotificationDetailModel.fromJson({"data": null});
      expect(model.data, isNull);
    });

    test('toJson serializes data nested object', () {
      final model = NotificationDetailModel.fromJson(fullJson);
      final json = model.toJson();
      expect(json["id"], "n1");
      expect(json["data"], isA<Map<String, dynamic>>());
      expect((json["data"] as Map)["buttonLabel"], "กดที่นี่");
      expect((json["data"] as Map)["targetPath"], "/home");
    });

    test('toJson with null data emits null for data key', () {
      final model = NotificationDetailModel.fromJson({});
      final json = model.toJson();
      expect(json["data"], isNull);
      // defaults for the rest are empty strings, not null
      expect(json["id"], '');
      expect(json["title"], '');
    });

    test('round-trip fromJson(toJson) preserves values', () {
      final original = NotificationDetailModel.fromJson(fullJson);
      final restored = NotificationDetailModel.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.group, original.group);
      expect(restored.body, original.body);
      expect(restored.data!.buttonUrl, original.data!.buttonUrl);
      expect(restored.data!.notificationId, original.data!.notificationId);
      expect(restored.data!.showButton, original.data!.showButton);
    });
  });

  group('NotificationDetailData', () {
    test('fromJson empty map uses empty-string defaults for all fields', () {
      final data = NotificationDetailData.fromJson({});
      expect(data.buttonLabel, '');
      expect(data.buttonUrl, '');
      expect(data.category, '');
      expect(data.description, '');
      expect(data.imagePath, '');
      expect(data.notificationId, '');
      expect(data.notificationType, '');
      expect(data.showButton, '');
      expect(data.targetPath, '');
    });

    test('toJson produces all keys', () {
      final data = NotificationDetailData.fromJson({
        "buttonLabel": "L",
        "buttonUrl": "U",
        "category": "C",
        "description": "D",
        "imagePath": "I",
        "notificationId": "NID",
        "notificationType": "NT",
        "showButton": "SB",
        "targetPath": "TP",
      });
      expect(data.toJson(), {
        "buttonLabel": "L",
        "buttonUrl": "U",
        "category": "C",
        "description": "D",
        "imagePath": "I",
        "notificationId": "NID",
        "notificationType": "NT",
        "showButton": "SB",
        "targetPath": "TP",
      });
    });
  });

  group('notificationDetailModelFromJson / toJson string helpers', () {
    test('parses a JSON object string into a model', () {
      const str = '{"id":"z","title":"hello","data":{"category":"x"}}';
      final model = notificationDetailModelFromJson(str);
      expect(model.id, "z");
      expect(model.title, "hello");
      expect(model.data!.category, "x");
    });

    test('serializes a model to a JSON string and back', () {
      final model = NotificationDetailModel.fromJson({"id": "q", "body": "b"});
      final str = notificationDetailModelToJson(model);
      final restored = notificationDetailModelFromJson(str);
      expect(restored.id, "q");
      expect(restored.body, "b");
    });
  });
}

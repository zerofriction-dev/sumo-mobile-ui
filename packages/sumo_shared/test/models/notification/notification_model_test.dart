import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/notification/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('parses full payload correctly', () {
      final m = NotificationModel.fromJson({
        'id': 'noti1',
        'group': 'job',
        'type': 'push',
        'action': 'new_job',
        'title': 'มีงานใหม่',
        'body': 'คุณได้รับงานใหม่',
        'isAcknowledge': 'false',
        'createdAt': '2025-06-01T10:00:00Z',
        'data': {'jobId': 'job1', 'targetPath': '/job/job1'},
      });
      expect(m.id, 'noti1');
      expect(m.group, 'job');
      expect(m.type, 'push');
      expect(m.action, 'new_job');
      expect(m.title, 'มีงานใหม่');
      expect(m.body, 'คุณได้รับงานใหม่');
      expect(m.isAcknowledge, 'false');
      expect(m.createdAt, '2025-06-01T10:00:00Z');
      expect(m.data!['jobId'], 'job1');
    });

    test('missing fields → defaults ("")', () {
      final m = NotificationModel.fromJson({});
      expect(m.id, '');
      expect(m.group, '');
      expect(m.type, '');
      expect(m.action, '');
      expect(m.title, '');
      expect(m.body, '');
      expect(m.isAcknowledge, '');
      expect(m.createdAt, '');
      expect(m.data, isEmpty);
    });

    test('data=null → empty map', () {
      final m = NotificationModel.fromJson({'data': null});
      expect(m.data, isEmpty);
    });

    test('isRead getter: isAcknowledge="true" → true', () {
      final m = NotificationModel.fromJson({'isAcknowledge': 'true'});
      expect(m.isRead, true);
    });

    test('isRead getter: isAcknowledge="false" → false', () {
      final m = NotificationModel.fromJson({'isAcknowledge': 'false'});
      expect(m.isRead, false);
    });

    test('isRead getter: isAcknowledge="" → false', () {
      final m = NotificationModel.fromJson({});
      expect(m.isRead, false);
    });
  });

  group('NotificationModel.toJson', () {
    test('round-trip fromJson → toJson preserves values', () {
      final src = {
        'id': 'noti2',
        'group': 'system',
        'type': 'alert',
        'action': 'update',
        'title': 'อัพเดต',
        'body': 'มีอัพเดตใหม่',
        'isAcknowledge': 'true',
        'createdAt': '2025-06-02T08:00:00Z',
        'data': {'key': 'value'},
      };
      final m = NotificationModel.fromJson(src);
      final j = m.toJson();
      expect(j['id'], 'noti2');
      expect(j['group'], 'system');
      expect(j['title'], 'อัพเดต');
      expect(j['isAcknowledge'], 'true');
      expect(j['data']!['key'], 'value');
    });
  });

  group('notificationModelFromJson / notificationModelToJson', () {
    test('decodes JSON string to list', () {
      final jsonStr = json.encode([
        {
          'id': 'n1',
          'group': 'g1',
          'type': 't1',
          'action': 'a1',
          'title': 'T1',
          'body': 'B1',
          'isAcknowledge': 'false',
          'createdAt': '',
          'data': {},
        },
        {
          'id': 'n2',
          'group': 'g2',
          'type': 't2',
          'action': 'a2',
          'title': 'T2',
          'body': 'B2',
          'isAcknowledge': 'true',
          'createdAt': '',
          'data': {},
        },
      ]);
      final list = notificationModelFromJson(jsonStr);
      expect(list.length, 2);
      expect(list[0].id, 'n1');
      expect(list[1].isRead, true);
    });

    test('encodes list to JSON string', () {
      final list = [
        NotificationModel.fromJson({
          'id': 'x1',
          'group': '',
          'type': '',
          'action': '',
          'title': '',
          'body': '',
          'isAcknowledge': '',
          'createdAt': '',
          'data': {},
        }),
      ];
      final str = notificationModelToJson(list);
      final decoded = json.decode(str) as List;
      expect(decoded[0]['id'], 'x1');
    });
  });
}

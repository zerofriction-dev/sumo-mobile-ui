import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/google_map/distance_matrix_model.dart';

void main() {
  group('Distance', () {
    test('fromJson fully populated', () {
      final d = Distance.fromJson({'text': '5.2 km', 'value': 5200});
      expect(d.text, '5.2 km');
      expect(d.value, 5200);
    });

    test('fromJson empty -> defaults text empty, value 0', () {
      final d = Distance.fromJson({});
      expect(d.text, '');
      expect(d.value, 0);
    });
  });

  group('Elements', () {
    test('fromJson fully populated with nested distance/duration', () {
      final e = Elements.fromJson({
        'distance': {'text': '5 km', 'value': 5000},
        'duration': {'text': '10 mins', 'value': 600},
        'status': 'OK',
      });
      expect(e.distance, isA<Distance>());
      expect(e.distance!.text, '5 km');
      expect(e.distance!.value, 5000);
      expect(e.duration, isA<Distance>());
      expect(e.duration!.text, '10 mins');
      expect(e.duration!.value, 600);
      expect(e.status, 'OK');
    });

    test(
      'fromJson empty -> non-null distance/duration with defaults, empty status',
      () {
        final e = Elements.fromJson({});
        expect(e.distance, isA<Distance>());
        expect(e.distance!.text, '');
        expect(e.distance!.value, 0);
        expect(e.duration, isA<Distance>());
        expect(e.status, '');
      },
    );
  });

  group('Rows', () {
    test('fromJson parses elements list', () {
      final r = Rows.fromJson({
        'elements': [
          {
            'distance': {'text': '1 km', 'value': 1000},
            'duration': {'text': '2 mins', 'value': 120},
            'status': 'OK',
          },
          {
            'distance': {'text': '2 km', 'value': 2000},
            'duration': {'text': '4 mins', 'value': 240},
            'status': 'OK',
          },
        ],
      });
      expect(r.elements, isNotNull);
      expect(r.elements!.length, 2);
      expect(r.elements![0], isA<Elements>());
      expect(r.elements![0].distance!.value, 1000);
      expect(r.elements![1].duration!.value, 240);
    });

    test('fromJson empty elements list', () {
      final r = Rows.fromJson({'elements': []});
      expect(r.elements, isEmpty);
    });
  });

  group('DistanceMatrixModel', () {
    final fullJson = {
      'destination_addresses': ['Dest A', 'Dest B'],
      'origin_addresses': ['Origin A'],
      'rows': [
        {
          'elements': [
            {
              'distance': {'text': '5 km', 'value': 5000},
              'duration': {'text': '10 mins', 'value': 600},
              'status': 'OK',
            },
            {
              'distance': {'text': '8 km', 'value': 8000},
              'duration': {'text': '15 mins', 'value': 900},
              'status': 'OK',
            },
          ],
        },
      ],
      'status': 'OK',
    };

    test('fromJson fully populated with nested rows/elements', () {
      final m = DistanceMatrixModel.fromJson(fullJson);
      expect(m.destinationAddresses, ['Dest A', 'Dest B']);
      expect(m.originAddresses, ['Origin A']);
      expect(m.status, 'OK');
      expect(m.rows, isNotNull);
      expect(m.rows!.length, 1);
      expect(m.rows![0].elements!.length, 2);
      expect(m.rows![0].elements![0].distance!.value, 5000);
      expect(m.rows![0].elements![1].duration!.value, 900);
    });

    test('fromJson with empty arrays but keys present', () {
      final m = DistanceMatrixModel.fromJson({
        'destination_addresses': [],
        'origin_addresses': [],
        'rows': [],
        'status': '',
      });
      expect(m.destinationAddresses, isEmpty);
      expect(m.originAddresses, isEmpty);
      expect(m.rows, isEmpty);
      expect(m.status, '');
    });

    test('fromJson missing status -> empty default', () {
      final m = DistanceMatrixModel.fromJson({
        'destination_addresses': ['A'],
        'origin_addresses': ['B'],
        'rows': [],
      });
      expect(m.status, '');
    });

    test('distanceMatrixModelFromJson string helper', () {
      final m = distanceMatrixModelFromJson(jsonEncode(fullJson));
      expect(m.status, 'OK');
      expect(m.rows![0].elements![0].distance!.text, '5 km');
      expect(m.destinationAddresses, ['Dest A', 'Dest B']);
    });
  });
}

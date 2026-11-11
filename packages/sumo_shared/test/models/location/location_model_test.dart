import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/location/location_model.dart';

void main() {
  group('Location.fromJson', () {
    test('parses lat/lng as doubles', () {
      final loc = Location.fromJson({'lat': 13.752395, 'lng': 100.50943});
      expect(loc.lat, 13.752395);
      expect(loc.lng, 100.50943);
    });

    test('coerces int values to double', () {
      final loc = Location.fromJson({'lat': 13, 'lng': 100});
      expect(loc.lat, 13.0);
      expect(loc.lng, 100.0);
    });

    test('empty map -> null lat/lng', () {
      final loc = Location.fromJson({});
      expect(loc.lat, isNull);
      expect(loc.lng, isNull);
    });
  });

  group('Location.toJson', () {
    test('round-trips lat/lng', () {
      final loc = Location(lat: 1.5, lng: 2.5);
      expect(loc.toJson(), {'lat': 1.5, 'lng': 2.5});
    });

    test('emits nulls when unset', () {
      final loc = Location();
      expect(loc.toJson(), {'lat': null, 'lng': null});
    });
  });

  group('LocationModel.fromJson', () {
    test('fully populated', () {
      final m = LocationModel.fromJson({
        'imageUrl': 'http://x/img.png',
        'location': {'lat': 13.5, 'lng': 100.5},
        'title': 'จุดรับ',
        'subtitle': 'รายละเอียด',
      });
      expect(m.imageUrl, 'http://x/img.png');
      expect(m.location, isNotNull);
      expect(m.location!.lat, 13.5);
      expect(m.location!.lng, 100.5);
      expect(m.title, 'จุดรับ');
      expect(m.subtitle, 'รายละเอียด');
    });

    test(
      'empty map -> string fields default to "", location is a non-null empty Location',
      () {
        final m = LocationModel.fromJson({});
        expect(m.imageUrl, '');
        expect(m.title, '');
        expect(m.subtitle, '');
        // location defaults to Location.fromJson({}) -> non-null with null coords
        expect(m.location, isNotNull);
        expect(m.location!.lat, isNull);
        expect(m.location!.lng, isNull);
        // encodedPolyline is not read in fromJson
        expect(m.encodedPolyline, isNull);
      },
    );

    test('missing location key still yields a non-null Location', () {
      final m = LocationModel.fromJson({'title': 't'});
      expect(m.location, isNotNull);
      expect(m.location!.lat, isNull);
    });
  });

  group('LocationModel.toJson', () {
    test('serializes nested location via toJson', () {
      final m = LocationModel(
        imageUrl: 'u',
        location: Location(lat: 1.0, lng: 2.0),
        title: 't',
        subtitle: 's',
      );
      expect(m.toJson(), {
        'imageUrl': 'u',
        'location': {'lat': 1.0, 'lng': 2.0},
        'title': 't',
        'subtitle': 's',
      });
    });

    test('null location serializes to null', () {
      final m = LocationModel(title: 't');
      final out = m.toJson();
      expect(out['location'], isNull);
      expect(out['title'], 't');
    });
  });

  group('LocationModel constructor', () {
    test('holds encodedPolyline even though fromJson ignores it', () {
      final m = LocationModel(encodedPolyline: 'abc123');
      expect(m.encodedPolyline, 'abc123');
    });
  });

  group('top-level list helpers', () {
    test('locationModelFromJson parses a JSON array', () {
      final list = locationModelFromJson(
        '[{"title":"A","location":{"lat":1,"lng":2}},{"title":"B","location":{"lat":3,"lng":4}}]',
      );
      expect(list, hasLength(2));
      expect(list[0].title, 'A');
      expect(list[0].location!.lat, 1.0);
      expect(list[1].title, 'B');
      expect(list[1].location!.lng, 4.0);
    });

    test('locationModelToJson serializes a list back to a JSON array', () {
      final list = [
        LocationModel(title: 'A', location: Location(lat: 1.0, lng: 2.0)),
      ];
      final decoded = json.decode(locationModelToJson(list)) as List;
      expect(decoded, hasLength(1));
      expect(decoded[0]['title'], 'A');
      expect(decoded[0]['location'], {'lat': 1.0, 'lng': 2.0});
    });
  });
}

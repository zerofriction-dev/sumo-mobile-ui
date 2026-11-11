import 'dart:convert';

List<LocationModel> locationModelFromJson(String str) =>
    List<LocationModel>.from(
      json.decode(str).map((x) => LocationModel.fromJson(x)),
    );
String locationModelToJson(List<LocationModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LocationModel {
  String? imageUrl;
  Location? location;
  String? title;
  String? subtitle;
  String? encodedPolyline;

  LocationModel({
    this.imageUrl,
    this.location,
    this.title,
    this.subtitle,
    this.encodedPolyline,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    imageUrl: json["imageUrl"] ?? '',
    location: Location.fromJson(json["location"] ?? {}),
    title: json["title"] ?? '',
    subtitle: json["subtitle"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "imageUrl": imageUrl,
    "location": location?.toJson(),
    "title": title,
    "subtitle": subtitle,
  };
}

class Location {
  double? lat;
  double? lng;

  Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    lat: (json["lat"] as num?)?.toDouble(),
    lng: (json["lng"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {"lat": lat, "lng": lng};
}

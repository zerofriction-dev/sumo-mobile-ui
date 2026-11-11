import 'dart:convert';

DistanceMatrixModel distanceMatrixModelFromJson(String str) =>
    DistanceMatrixModel.fromJson(json.decode(str));

class DistanceMatrixModel {
  final List<String>? destinationAddresses;
  final List<String>? originAddresses;
  final List<Rows>? rows;
  final String? status;

  DistanceMatrixModel({
    required this.destinationAddresses,
    required this.originAddresses,
    required this.rows,
    required this.status,
  });

  factory DistanceMatrixModel.fromJson(Map<String, dynamic> json) =>
      DistanceMatrixModel(
        destinationAddresses: List<String>.from(
          json["destination_addresses"].map((x) => x) ?? [],
        ),
        originAddresses: List<String>.from(
          json["origin_addresses"].map((x) => x) ?? [],
        ),
        rows: List<Rows>.from(json["rows"].map((x) => Rows.fromJson(x)) ?? []),
        status: json["status"] ?? '',
      );
}

class Rows {
  final List<Elements>? elements;

  Rows({this.elements});

  factory Rows.fromJson(Map<String, dynamic> json) => Rows(
    elements: List<Elements>.from(
      json["elements"].map((x) => Elements.fromJson(x)) ?? [],
    ),
  );
}

class Elements {
  final Distance? distance;
  final Distance? duration;
  final String? status;

  Elements({this.distance, this.duration, this.status});

  factory Elements.fromJson(Map<String, dynamic> json) => Elements(
    distance: Distance.fromJson(json["distance"] ?? {}),
    duration: Distance.fromJson(json["duration"] ?? {}),
    status: json["status"] ?? '',
  );
}

class Distance {
  final String? text;
  final int? value;

  Distance({this.text, this.value});

  factory Distance.fromJson(Map<String, dynamic> json) =>
      Distance(text: json["text"] ?? '', value: json["value"] ?? 0);
}

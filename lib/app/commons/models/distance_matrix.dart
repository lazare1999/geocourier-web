class DistanceMatrix {
  final List<String> destinations;
  final List<String> origins;
  final List<Element> elements;
  final String status;

  DistanceMatrix({required this.destinations, required this.origins, required this.elements, required this.status});

  factory DistanceMatrix.fromJson(Map<String, dynamic> json) {
    var destinationsJson = json['destination_addresses'];
    var originsJson = json['origin_addresses'];
    var rowsJson = json['rows'][0]['elements'] as List;

    return DistanceMatrix(
        destinations: destinationsJson.cast<String>(),
        origins: originsJson.cast<String>(),
        elements: rowsJson.map((i) => new Element.fromJson(i)).toList(),
        status: json['status']);
  }
}

class Element {
  final Distance distance;
  final Duration duration;
  final String status;

  Element({required this.distance, required this.duration, required this.status});

  factory Element.fromJson(Map<String, dynamic> json) {
    return Element(
        distance: new Distance.fromJson(json['distance']),
        duration: new Duration.fromJson(json['duration']),
        status: json['status']);
  }
}

class Distance {
  final String text;
  final int value;

  Distance({required this.text, required this.value});

  factory Distance.fromJson(Map<String, dynamic> json) {
    return new Distance(text: json['text'], value: json['value']);
  }
}

class Duration {
  final String text;
  final int value;

  Duration({required this.text, required this.value});

  factory Duration.fromJson(Map<String, dynamic> json) {
    return new Duration(text: json['text'], value: json['value']);
  }
}
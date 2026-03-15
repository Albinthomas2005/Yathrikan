import 'package:latlong2/latlong.dart';

/// A single stop on a bus route, with a display name and GPS coordinates.
class BusStop {
  String name;
  LatLng position;

  BusStop({required this.name, required this.position});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': position.latitude,
      'lng': position.longitude,
    };
  }

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      name: map['name'],
      position: LatLng(map['lat'], map['lng']),
    );
  }

  @override
  String toString() => name;
}

class LiveBus {
  final String busId;
  String busName;
  final String routeName;
  final String from;
  final String to;
  List<LatLng> route;

  /// Number plate in format KL-ERU-2005 — primary identifier shown on cards.
  String numberPlate;

  /// Ordered list of stops with GPS coordinates, from origin to destination.
  List<BusStop> stops;

  int index;
  double speedMps;
  String status;
  double headingDeg;
  /// When set, overrides route-based position (used for MBTA & IoT live buses)
  LatLng? directPosition;

  /// True if this bus's location is updated from the Firebase IoT GPS node
  bool isFirebaseIot;

  /// Firebase/IoT device ID (e.g. "ESP32_01") — used to build the path
  /// /<deviceId>/gps.json in Firebase Realtime Database.
  /// Empty string means no specific device is bound.
  String deviceId;

  LiveBus({
    required this.busId,
    required this.busName,
    required this.routeName,
    this.from = 'Erumely',
    this.to = 'Kottayam',
    List<LatLng>? route,
    this.index = 0,
    double? speedMps,
    double? speedKmph,
    this.status = 'RUNNING',
    this.headingDeg = 0.0,
    this.directPosition,
    this.isFirebaseIot = false,
    this.deviceId = '',
    this.numberPlate = '',
    List<BusStop>? stops,
    // legacy ignored params
    double? lat,
    double? lon,
    DateTime? lastUpdated,
  }) :
    route = route ?? [],
    stops = stops ?? [],
    speedMps = speedMps ?? (speedKmph != null ? speedKmph / 3.6 : 10.0);

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'busName': busName,
      'routeName': routeName,
      'from': from,
      'to': to,
      'route': route.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      'numberPlate': numberPlate,
      'stops': stops.map((e) => e.toMap()).toList(),
      'index': index,
      'speedMps': speedMps,
      'status': status,
      'headingDeg': headingDeg,
      'directPosition': directPosition != null ? {'lat': directPosition!.latitude, 'lng': directPosition!.longitude} : null,
      'isFirebaseIot': isFirebaseIot,
      'deviceId': deviceId,
    };
  }

  factory LiveBus.fromMap(Map<String, dynamic> map) {
    return LiveBus(
      busId: map['busId'],
      busName: map['busName'],
      routeName: map['routeName'],
      from: map['from'] ?? 'Erumely',
      to: map['to'] ?? 'Kottayam',
      route: (map['route'] as List?)?.map((e) => LatLng(e['lat'], e['lng'])).toList(),
      numberPlate: map['numberPlate'] ?? '',
      stops: (map['stops'] as List?)?.map((e) => BusStop.fromMap(e)).toList(),
      index: map['index'] ?? 0,
      speedMps: map['speedMps'],
      status: map['status'] ?? 'RUNNING',
      headingDeg: map['headingDeg'] ?? 0.0,
      directPosition: map['directPosition'] != null ? LatLng(map['directPosition']['lat'], map['directPosition']['lng']) : null,
      isFirebaseIot: map['isFirebaseIot'] ?? false,
      deviceId: map['deviceId'] ?? '',
    );
  }

  LatLng get position {
    if (directPosition != null) return directPosition!;
    if (route.isEmpty) return const LatLng(9.5361, 76.8254);
    return route[index.clamp(0, route.length - 1)];
  }

  double get lat => position.latitude;
  double get lon => position.longitude;
  double get speedKmph => speedMps * 3.6;
  int get etaMin => 0;
  bool get forward => true;
  int get currentIndex => index;
}

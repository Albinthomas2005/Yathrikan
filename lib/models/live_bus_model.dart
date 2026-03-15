import 'package:latlong2/latlong.dart';

/// A single stop on a bus route, with a display name and GPS coordinates.
class BusStop {
  String name;
  LatLng position;

  BusStop({required this.name, required this.position});

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

import 'package:latlong2/latlong.dart';

class LiveBus {
  final String busId;
  final String busName;
  final String routeName;
  final String from;
  final String to;
  List<LatLng> route;

  int index;
  double speedMps;
  String status;
  double headingDeg;
  /// When set, overrides route-based position (used for MBTA live buses)
  LatLng? directPosition;

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
    // legacy ignored params
    double? lat,
    double? lon,
    DateTime? lastUpdated,
  }) :
    route = route ?? [],
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

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
  
  // Real coordinates and bearing
  double currentLat;
  double currentLon;
  double currentBearing;
  
  LiveBus({
    required this.busId,
    required this.busName,
    required this.routeName,
    this.from = "MBTA", 
    this.to = "Boston",  
    List<LatLng>? route,
    this.index = 0,
    double? speedMps,
    double? speedKmph,      
    this.status = "RUNNING",
    double? lat,
    double? lon,
    double? headingDeg,
    DateTime? lastUpdated,
  }) : 
    route = route ?? [],
    speedMps = speedMps ?? (speedKmph != null ? speedKmph / 3.6 : 10.0),
    currentLat = lat ?? 42.3601,
    currentLon = lon ?? -71.0589,
    currentBearing = headingDeg ?? 0.0;

  LatLng get position {
    return LatLng(currentLat, currentLon);
  }

  double get lat => currentLat;
  double get lon => currentLon;
  
  double get headingDeg => currentBearing;
  double get speedKmph => speedMps * 3.6;
  
  int get etaMin => 0; 
  bool get forward => true; 
  int get currentIndex => index; 
}

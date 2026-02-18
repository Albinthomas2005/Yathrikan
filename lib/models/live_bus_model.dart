import 'package:latlong2/latlong.dart';

class LiveBus {
  final String busId;
  final String busName;
  final String routeName; // keeping this for UI compatibility
  final String from;
  final String to;
  List<LatLng> route; // full shortest path polyline (Mutable to allow assignment in addBus)

  int index;               // current position on route
  double speedMps;         // meters per second
  String status;           // Mutable status
  
  LiveBus({
    required this.busId,
    required this.busName,
    required this.routeName,
    this.from = "Erumely", // Optional/Default to avoid break
    this.to = "Kottayam",   // Optional/Default
    List<LatLng>? route,
    this.index = 0,
    double? speedMps,
    double? speedKmph,      // Legacy support
    this.status = "RUNNING",
    // Ignored legacy params to satisfy AdminRoutesScreen calls
    double? lat,
    double? lon,
    double? headingDeg,
    DateTime? lastUpdated,
  }) : 
    this.route = route ?? [],
    this.speedMps = speedMps ?? (speedKmph != null ? speedKmph / 3.6 : 10.0); // Default speed if missing

  LatLng get position {
    if (route.isEmpty) return const LatLng(9.5361, 76.8254); // Default Koovappally if no route
    final safeIndex = index.clamp(0, route.length - 1);
    return route[safeIndex];
  }

  // Getters for compatibility with existing code that expects lat/lon
  double get lat => position.latitude;
  double get lon => position.longitude;
  
  // Mock fields
  double get headingDeg => 0.0;
  double get speedKmph => speedMps * 3.6;
  
  int get etaMin => 0; 
  bool get forward => true; 
  int get currentIndex => index; 
}

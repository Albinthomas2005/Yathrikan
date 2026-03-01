import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/live_bus_model.dart';
import '../models/route_model.dart';
import 'notification_service.dart';

class BusLocationService {
  static final BusLocationService _instance = BusLocationService._internal();
  factory BusLocationService() => _instance;
  BusLocationService._internal();

  final List<LiveBus> _buses = [];
  final StreamController<List<LiveBus>> _busStreamController =
      StreamController<List<LiveBus>>.broadcast();
  Timer? _updateTimer;
  final NotificationService _notificationService = NotificationService();

  void setTrackedBuses(List<String> busIds) {
    debugPrint("Now tracking exactly ${busIds.length} buses: $busIds");
  }
  int _userRouteIndex = 0; // Cached user index on regular route
  int _userRouteIndexReturn = 0; // Cached user index on return route

  Stream<List<LiveBus>> get busStream => _busStreamController.stream;
  List<LiveBus> get buses => List.unmodifiable(_buses);

  // Erumely → Koovappally → Kottayam waypoints
  static final List<LatLng> waypoints = [
    const LatLng(9.4810562, 76.8450521), // Erumely
    const LatLng(9.5005000, 76.8500000), // Erumely North
    const LatLng(9.5425371, 76.8201976), // Koovappally
    const LatLng(9.5594567, 76.7873550), // Kanjirappally
    const LatLng(9.5656117, 76.7546495), // Ponkunnam
    const LatLng(9.6040000, 76.6730000), // Vazhoor
    const LatLng(9.6200000, 76.6500000), // 14th Mile
    const LatLng(9.6400000, 76.6400000), // Mannathipara
    const LatLng(9.6500000, 76.6200000), // Chennampally
    const LatLng(9.6600000, 76.6000000), // Pampady
    const LatLng(9.5916000, 76.5222000), // Kottayam
  ];

  // Kottayam → Erumely waypoints (Reverse of above)
  static final List<LatLng> waypointsReturn = waypoints.reversed.toList();

  late List<LatLng> _interpolatedRoute;
  late List<LatLng> _interpolatedRouteReturn;
  LatLng _userLocation = const LatLng(9.528711, 76.822581); // Default: Amal Jyothi (will update)
  LatLng get userLocation => _userLocation;
  
  bool _initialized = false;

  static const Map<String, LatLng> keyPlaces = {
    'Kottayam': LatLng(9.5916, 76.5222),
    'Changanassery': LatLng(9.4436, 76.5363),
    'Pala': LatLng(9.7086, 76.6835),
    'Ettumanoor': LatLng(9.6690, 76.5604),
    'Vaikom': LatLng(9.7479, 76.3918),
    'Erattupetta': LatLng(9.6890, 76.7865),
    'Thalayolaparambu': LatLng(9.8055, 76.4523),
    'Kumarakom': LatLng(9.6175, 76.4300),
    'Mundakayam': LatLng(9.5310, 76.8834),
    'Kanjirappally': LatLng(9.5594567, 76.7873550),
    'Erumely': LatLng(9.4810562, 76.8450521),
    'Erumely North': LatLng(9.5005, 76.8500),
    'Koovappally': LatLng(9.5425371, 76.8201976),
    'Ponkunnam': LatLng(9.5656117, 76.7546495),
    'Vazhoor': LatLng(9.6040, 76.6730),
    'Amal Jyothi': LatLng(9.528711, 76.822581),
    'Manimala': LatLng(9.4583, 76.7333),
    'Koruthodu': LatLng(9.4333, 76.9000),
    'Pampady': LatLng(9.6600, 76.6000),
    '14th Mile': LatLng(9.6200, 76.6500),
    'Mannathipara': LatLng(9.6400, 76.6400),
    'Chennampally': LatLng(9.6500, 76.6200),
    'Vakathanam': LatLng(9.5333, 76.5667),
    'Manarcadu': LatLng(9.5833, 76.5500),
    'Kodungoor': LatLng(9.5800, 76.7000),
    'Kidangoor': LatLng(9.6667, 76.6167),
    'Kuravilangad': LatLng(9.7500, 76.5667),
    'Bharananganam': LatLng(9.6917, 76.7167),
    'Athirampuzha': LatLng(9.6500, 76.5333),
    'Chengalam': LatLng(9.6000, 76.5000),
    'Neendoor': LatLng(9.6333, 76.5000),
    'Kaduthuruthy': LatLng(9.7667, 76.4833),
    'Nattakom': LatLng(9.5667, 76.5167),
    'Panachikkad': LatLng(9.5500, 76.5333),
    'Thirunakkara': LatLng(9.5833, 76.5167),
    'Vechoor': LatLng(9.7000, 76.4333),
    'Poovanthuruthu': LatLng(9.5667, 76.5500),
    'Vagamon': LatLng(9.6833, 76.9167),
    'Melukavu': LatLng(9.7500, 76.7667),
    'Ilaveezhapoonchira': LatLng(9.7833, 76.7833),
    'Ramapuram': LatLng(9.8000, 76.6333),
    'Lalam': LatLng(9.7083, 76.6833),
    'Cherpunkal': LatLng(9.6833, 76.6333),
    'Koratty': LatLng(9.5167, 76.8500),
    'Kuruvamoozhi': LatLng(9.4833, 76.8167),
    'Tiruvalla': LatLng(9.3833, 76.5667),
    'Pathanamthitta': LatLng(9.2667, 76.7833),
    'Alappuzha': LatLng(9.4900, 76.3300),
  };

  static const List<String> allPlaces = [
    'Kottayam','Changanassery','Pala','Ettumanoor','Vaikom','Erattupetta',
    'Thalayolaparambu','Kumarakom','Mundakayam','Kanjirappally',
    'Erumely','Erumely North','Koovappally','Ponkunnam','Vazhoor',
    'Amal Jyothi',
    'Manimala','Koruthodu','Pampady','14th Mile','Mannathipara',
    'Chennampally','Vakathanam','Manarcadu','Kodungoor','Kidangoor',
    'Kuravilangad','Bharananganam','Athirampuzha','Chengalam','Neendoor',
    'Kaduthuruthy','Nattakom','Panachikkad','Thirunakkara','Vechoor',
    'Poovanthuruthu','Vagamon','Melukavu','Ilaveezhapoonchira',
    'Ramapuram','Lalam','Cherpunkal','Koratty','Kuruvamoozhi',
    'Tiruvalla','Pathanamthitta','Alappuzha',
  ];

  String _currentUserPlace = "Amal Jyothi"; // Default



  /// Initialize service: start polling MBTA API
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize notifications
    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    // Start polling the MBTA API
    await _updateBuses();
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateBuses();
    });
  }

  Future<void> _updateBuses() async {
    try {
      // Fetch vehicles from MbtaService
      // Using MbtaService is better, but since it returns direct List<dynamic> we must parse here
      const targetUrl = "https://api-v3.mbta.com/vehicles?api_key=ddec6fb4aadf4f4db40509fc75891796";
      final url = Uri.parse("https://api.codetabs.com/v1/proxy?quest=$targetUrl");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> vehiclesData = data['data'] ?? [];
        
        // Temporarily clear to replace completely (or update existing based on ID later)
        if (_buses.isEmpty) {
           _buses.clear();
        }

        final Map<String, LiveBus> existingBuses = { for (var b in _buses) b.busId : b };
        final List<LiveBus> updatedList = [];

        for (var v in vehiclesData) {
          final String id = v['id'] ?? 'unknown';
          final attr = v['attributes'] ?? {};
          final double lat = attr['latitude'] ?? 0.0;
          final double lon = attr['longitude'] ?? 0.0;
          final double bearing = attr['bearing']?.toDouble() ?? 0.0;
          final double speedMps = attr['speed']?.toDouble() ?? 0.0;
          final String label = attr['label'] ?? id;
          final String status = attr['current_status'] ?? 'RUNNING';

          if (existingBuses.containsKey(id)) {
            // Update existing
            final bus = existingBuses[id]!;
            bus.currentLat = lat;
            bus.currentLon = lon;
            bus.currentBearing = bearing;
            bus.speedMps = speedMps;
            bus.status = status;
            updatedList.add(bus);
          } else {
            // Add new
            updatedList.add(LiveBus(
              busId: id,
              busName: label,
              routeName: attr['direction_id'] == 1 ? "Inbound" : "Outbound",
              lat: lat,
              lon: lon,
              headingDeg: bearing,
              speedMps: speedMps,
              status: status,
              from: "MBTA",
              to: "Destination"
            ));
          }
        }

        _buses.clear();
        _buses.addAll(updatedList);
        _busStreamController.add(List.from(_buses));
        
        // NOTE: We stripped out the complex notification tracking for Erumely/Kottayam specific logic
        // because we are now showing all MBTA vehicles generally on the map.
      }
    } catch(e) {
      debugPrint("Failed to update MBTA vehicles: $e");
    }
  }

// The `_updateBuses` definition was relocated to override the old `initialize` block above to group API polling.
  // -------------------------------------------------------------------------
  // Helper / Query Methods
  // -------------------------------------------------------------------------

  // Helper to get cached user index if available
  int _getUserIndexForBus(LiveBus bus) {
    if (bus.route == _interpolatedRoute) return _userRouteIndex;
    if (bus.route == _interpolatedRouteReturn) return _userRouteIndexReturn;
    return _userIndex(bus.route);
  }

  int _userIndex(List<LatLng> route, {LatLng? location}) {
    final target = location ?? userLocation;
    double minDst = double.infinity;
    int uIdx = 0;
    const Distance dist = Distance();
    for (int i = 0; i < route.length; i++) {
      final d = dist.as(LengthUnit.Meter, route[i], target);
      if (d < minDst) { minDst = d; uIdx = i; }
    }
    return uIdx;
  }

  int etaMinutes(LiveBus bus, {LatLng? relativeTo}) {
    if (bus.route.isEmpty) return 0;
    
    int uIdx;
    if (relativeTo != null) {
       uIdx = _userIndex(bus.route, location: relativeTo);
    } else {
       uIdx = _getUserIndexForBus(bus);
    }

    final remaining = uIdx - bus.index;
    if (remaining <= 0) return 0;
    // Each index ≈ 12m, speed in m/s
    final distMeters = remaining * 12.0;
    return (distMeters / bus.speedMps / 60).ceil();
  }

  bool isIncoming(LiveBus bus, {LatLng? relativeTo}) {
    if (bus.route.isEmpty) return false;
    
    int uIdx;
    if (relativeTo != null) {
       uIdx = _userIndex(bus.route, location: relativeTo);
    } else {
       uIdx = _getUserIndexForBus(bus);
    }
    
    return bus.index < uIdx;
  }

  List<RouteModel> getAllRoutes() {
    return [
      RouteModel(
        id: '1',
        name: 'Erumely - Kottayam',
        fromLocation: 'Erumely',
        toLocation: 'Kottayam',
        frequency: 'Every 15m',
        activeBuses: _buses.where((b) => b.routeName == 'Erumely - Kottayam' && b.status == 'RUNNING').length,
      ),
      RouteModel(
        id: '2',
        name: 'Kottayam - Erumely',
        fromLocation: 'Kottayam',
        toLocation: 'Erumely',
        frequency: 'Every 15m',
        activeBuses: _buses.where((b) => b.routeName == 'Kottayam - Erumely' && b.status == 'RUNNING').length,
      ),
      RouteModel(
        id: '3',
        name: 'Kanjirappally - Ponkunnam',
        fromLocation: 'Kanjirappally',
        toLocation: 'Ponkunnam',
        frequency: 'Every 10m',
        activeBuses: _buses.where((b) => b.status == 'RUNNING' && 
            _isBusOnSegment(b, 'Kanjirappally', 'Ponkunnam')).length,
      ),
       RouteModel(
        id: '4',
        name: 'Kottayam - Pala',
        fromLocation: 'Kottayam',
        toLocation: 'Pala',
        frequency: 'Every 20m',
        activeBuses: 0, 
        isActive: false, 
      ),
      RouteModel(
        id: '5',
        name: 'Pala - Ettumanoor',
        fromLocation: 'Pala',
        toLocation: 'Ettumanoor',
        frequency: 'Every 30m',
        activeBuses: 2,
        isActive: true,
      ),
      RouteModel(
        id: '6',
        name: 'Changanassery - Kottayam',
        fromLocation: 'Changanassery',
        toLocation: 'Kottayam',
        frequency: 'Every 15m',
        activeBuses: 5,
        isActive: true,
      ),
    ];
  }
  
  bool _isBusOnSegment(LiveBus bus, String start, String end) {
    // Determine if bus is currently between start and end places
    // This is approximate based on index
    if (!keyPlaces.containsKey(start) || !keyPlaces.containsKey(end)) return true;
    
    // Simplification: if it's on the main route, count it
    return bus.routeName.contains("Erumely"); 
  }

  List<RouteModel> getPopularRoutes() {
    return [
      RouteModel(
        id: '3',
        name: 'Kanjirappally - Ponkunnam',
        fromLocation: 'Kanjirappally',
        toLocation: 'Ponkunnam',
        frequency: 'Every 10m',
        activeBuses: 8,
        isTrending: true,
      ),
      RouteModel(
        id: '1',
        name: 'Erumely - Kottayam',
        fromLocation: 'Erumely',
        toLocation: 'Kottayam',
        frequency: 'Every 15m',
        activeBuses: 12,
        isFastest: true,
      ),
      RouteModel(
        id: '6',
        name: 'Changanassery - Kottayam',
        fromLocation: 'Changanassery',
        toLocation: 'Kottayam',
        frequency: 'Every 15m',
        activeBuses: 5,
        isActive: true,
      ),
      RouteModel(
        id: '5',
        name: 'Pala - Ettumanoor',
        fromLocation: 'Pala',
        toLocation: 'Ettumanoor',
        frequency: 'Every 30m',
        activeBuses: 2,
        isActive: true,
      ),
    ];
  }

  List<String> get availableCities => keyPlaces.keys.toList();

  // Bus management
  void addBus(LiveBus bus) {
    if (bus.route.isEmpty && _interpolatedRoute.isNotEmpty) {
      bus.route = _interpolatedRoute;
    }
    _buses.add(bus);
    _busStreamController.add(List.from(_buses));
  }

  void removeBus(String busId) {
    _buses.removeWhere((b) => b.busId == busId);
    _busStreamController.add(List.from(_buses));
  }

  void updateBusStatus(String busId, String status) {
    try {
      final bus = _buses.firstWhere((b) => b.busId == busId);
      bus.status = status;
      _busStreamController.add(List.from(_buses));
    } catch (e) { debugPrint("Bus not found: $busId"); }
  }

  List<Map<String, dynamic>> findBusesForUser({
    required String startLocation,
    required String endLocation,
    required TimeOfDay userCurrentTime,
  }) {
    // Normalize inputs
    final from = startLocation.trim();
    final to = endLocation.trim();
    
    // Filter buses based on route direction
    final matchingBuses = _buses.where((b) {
      if (b.status != 'RUNNING') return false;
      
      // Check if bus route matches request
      // We do a simple contains check or directional check
      // For now, we assume direct match on 'from' and 'to' in routeName or bus properties
      
      bool matchesDirection = false;
      if (from.toLowerCase().contains("erumely") && to.toLowerCase().contains("kottayam")) {
        matchesDirection = b.routeName.contains("Erumely - Kottayam");
      } else if (from.toLowerCase().contains("kottayam") && to.toLowerCase().contains("erumely")) {
        matchesDirection = b.routeName.contains("Kottayam - Erumely");
      } else {
        // If query is generic or partial (e.g. from Koovappally to Kanjirappally)
        // We'd need more complex logic. For now, default to returning all if vague, 
        // or strict matching if specific. 
        // Let's implement a 'contains' logic based on stops if we had them.
        // For MVP, if start/end aren't the terminals, just return buses going in the general direction?
        // Or simpler: match 'to' destination.
        
        matchesDirection = b.to.toLowerCase() == to.toLowerCase();
      }
      
      return matchesDirection && isIncoming(b);
    }).toList();

    matchingBuses.sort((a, b) => etaMinutes(a).compareTo(etaMinutes(b)));
    
    return matchingBuses.map((b) {
      final eta = etaMinutes(b);
      final now = DateTime.now();
      final reach = now.add(Duration(minutes: eta + 45));
      return {
        'busName': b.busName, 'arrivalTime': "$eta min",
        'reachTime': "${reach.hour}:${reach.minute.toString().padLeft(2, '0')}",
        'duration': "45 min"
      };
    }).toList();
  }



  void _identifyNearestPlace(LatLng userPos) {
    String nearest = "your location";
    double minDistance = 500.0; // Max threshold in meters
    const Distance dist = Distance();

    keyPlaces.forEach((name, pos) {
      final d = dist.as(LengthUnit.Meter, userPos, pos);
      if (d < minDistance) {
        minDistance = d;
        nearest = name;
      }
    });
    
    _currentUserPlace = nearest;
    debugPrint("📍 User is near: $_currentUserPlace");
  }



  void updateUserLocation(LatLng newLocation) {
    _userLocation = newLocation;
    _identifyNearestPlace(newLocation);
    
    
    // Recalculate usage indices if routes are ready
    if (_initialized) {
      _userRouteIndex = _userIndex(_interpolatedRoute);
      _userRouteIndexReturn = _userIndex(_interpolatedRouteReturn);
    }
  }

  void dispose() {
    _updateTimer?.cancel();
    _busStreamController.close();
  }
}

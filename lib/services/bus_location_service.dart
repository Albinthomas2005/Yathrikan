import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/live_bus_model.dart';
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
  final Set<String> _notifiedBuses = {}; // Track which buses already notified (per lap)
  int _userRouteIndex = 0; // Cached user index on route

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

  late List<LatLng> _interpolatedRoute;
  final LatLng userLocation = const LatLng(9.5425371, 76.8201976); // Koovappally
  bool _initialized = false;

  static const List<String> allPlaces = [
    'Kottayam','Changanassery','Pala','Ettumanoor','Vaikom','Erattupetta',
    'Thalayolaparambu','Kumarakom','Mundakayam','Kanjirappally',
    'Erumely','Erumely North','Koovappally','Ponkunnam','Vazhoor',
    'Manimala','Koruthodu','Pampady','14th Mile','Mannathipara',
    'Chennampally','Vakathanam','Manarcadu','Kodungoor','Kidangoor',
    'Kuravilangad','Bharananganam','Athirampuzha','Chengalam','Neendoor',
    'Kaduthuruthy','Nattakom','Panachikkad','Thirunakkara','Vechoor',
    'Poovanthuruthu','Vagamon','Melukavu','Ilaveezhapoonchira',
    'Ramapuram','Lalam','Cherpunkal','Koratty','Kuruvamoozhi',
    'Tiruvalla','Pathanamthitta','Alappuzha',
  ];

  /// Fetch actual road geometry from OSRM
  Future<List<LatLng>> _fetchOSRMRoute() async {
    try {
      final coords = waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
      final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final List<dynamic> osrmCoords = data['routes'][0]['geometry']['coordinates'];
          final List<LatLng> roadPath = [];
          LatLng? prev;
          for (final c in osrmCoords) {
            final pt = LatLng(c[1].toDouble(), c[0].toDouble());
            if (prev == null ||
                (pt.latitude - prev.latitude).abs() > 0.00001 ||
                (pt.longitude - prev.longitude).abs() > 0.00001) {
              roadPath.add(pt);
              prev = pt;
            }
          }
          debugPrint('OSRM: Got ${roadPath.length} road-following points');
          return roadPath;
        }
      }
    } catch (e) {
      debugPrint('OSRM fetch failed: $e');
    }
    // Fallback to linear interpolation
    return _generateDenseRoute(waypoints, 12.0);
  }

  /// Initialize service: fetch OSRM route and create 30 buses
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize notifications
    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    _interpolatedRoute = await _fetchOSRMRoute();
    debugPrint('Route has ${_interpolatedRoute.length} points');

    // Cache user index on the route
    _userRouteIndex = _userIndex(_interpolatedRoute);
    debugPrint('User location index: $_userRouteIndex');

    // Create 30 buses staggered along the route
    final segmentLength = _interpolatedRoute.length ~/ 30;
    for (int i = 0; i < 30; i++) {
      final id = (i + 1).toString().padLeft(3, '0');
      final startIdx = (i * segmentLength) % _interpolatedRoute.length;
      _buses.add(LiveBus(
        busId: 'KL-ERU-$id',
        busName: 'Erumely Express $id',
        routeName: 'Erumely - Kottayam',
        from: 'Erumely',
        to: 'Kottayam',
        route: _interpolatedRoute,
        index: startIdx,
        speedMps: 8.0 + Random().nextDouble() * 6.0,
        status: i < 25 ? 'RUNNING' : 'SCHEDULED',
      ));
    }

    debugPrint('Initialized ${_buses.length} buses');
    _busStreamController.add(List.from(_buses));

    // Start movement simulation
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateBuses();
    });
  }

  void _updateBuses() {
    const tolerance = 8; // index tolerance (~100m at 12m/point)
    for (final bus in _buses) {
      if (bus.route.isNotEmpty && bus.status == 'RUNNING') {
        final prevIdx = bus.index;
        // Move forward along route
        final step = (bus.speedMps * 3 / 12.0).round().clamp(1, 5);
        bus.index = (bus.index + step) % bus.route.length;

        // Check if bus just crossed the user's location
        final crossedUser = prevIdx < _userRouteIndex &&
            bus.index >= _userRouteIndex &&
            (bus.index - _userRouteIndex).abs() <= tolerance;

        // Also check wrapping (bus was near end, user near start)
        final nearUser = (bus.index - _userRouteIndex).abs() <= tolerance;

        if ((crossedUser || nearUser) && !_notifiedBuses.contains(bus.busId)) {
          _notifiedBuses.add(bus.busId);
          _notificationService.showNotification(
            id: bus.busId.hashCode,
            title: '🚌 ${bus.busName} is here!',
            body: '${bus.busId} has arrived at your location (Koovappally). Board now!',
            payload: bus.busId,
          );
          debugPrint('🔔 Notification: ${bus.busId} arrived at user location');
        }

        // Reset notification flag when bus moves far past user (allow re-notify on next lap)
        if (bus.index > _userRouteIndex + 50 || bus.index < _userRouteIndex - 50) {
          _notifiedBuses.remove(bus.busId);
        }
      }
    }
    _busStreamController.add(List.from(_buses));
  }

  // -------------------------------------------------------------------------
  // Helper / Query Methods
  // -------------------------------------------------------------------------

  int _userIndex(List<LatLng> route) {
    double minDst = double.infinity;
    int uIdx = 0;
    const Distance dist = Distance();
    for (int i = 0; i < route.length; i++) {
      final d = dist.as(LengthUnit.Meter, route[i], userLocation);
      if (d < minDst) { minDst = d; uIdx = i; }
    }
    return uIdx;
  }

  int etaMinutes(LiveBus bus) {
    if (bus.route.isEmpty) return 0;
    final uIdx = _userIndex(bus.route);
    final remaining = uIdx - bus.index;
    if (remaining <= 0) return 0;
    // Each index ≈ 12m, speed in m/s
    final distMeters = remaining * 12.0;
    return (distMeters / bus.speedMps / 60).ceil();
  }

  bool isIncoming(LiveBus bus) {
    if (bus.route.isEmpty) return false;
    return bus.index < _userIndex(bus.route);
  }

  List<String> get availableCities => List.from(allPlaces);

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
    final incoming = _buses.where((b) => isIncoming(b) && b.status == 'RUNNING').toList();
    incoming.sort((a, b) => etaMinutes(a).compareTo(etaMinutes(b)));
    return incoming.map((b) {
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

  List<LatLng> _generateDenseRoute(List<LatLng> wp, double stepMeters) {
    List<LatLng> dense = [];
    const Distance dist = Distance();
    for (int i = 0; i < wp.length - 1; i++) {
      final start = wp[i]; final end = wp[i + 1];
      final segDist = dist.as(LengthUnit.Meter, start, end);
      final steps = (segDist / stepMeters).ceil();
      dense.add(start);
      for (int j = 1; j < steps; j++) {
        final t = j / steps;
        dense.add(LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        ));
      }
    }
    dense.add(wp.last);
    return dense;
  }

  void dispose() {
    _updateTimer?.cancel();
    _busStreamController.close();
  }
}

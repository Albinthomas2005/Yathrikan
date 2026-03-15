import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/live_bus_model.dart';
import '../models/route_model.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_localizations.dart';

/// Represents a found route — either direct (one bus) or transfer (two buses).
class FoundRoute {
  final String type;          // 'direct' | 'transfer'
  final String bus1Name;
  final String? bus2Name;     // null when direct
  final String? transferStop; // normalised, null when direct  
  final List<String> leg1Stops;
  final List<String> leg2Stops; // empty when direct

  const FoundRoute({
    required this.type,
    required this.bus1Name,
    this.bus2Name,
    this.transferStop,
    required this.leg1Stops,
    this.leg2Stops = const [],
  });

  /// Human-readable title for the transfer stop (Title Case).
  String get transferStopDisplay {
    if (transferStop == null) return '';
    return transferStop!.split(' ').map((w) =>
        w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  /// Human-readable stop name from a normalised key.
  static String displayName(String norm) =>
      norm.split(' ').map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class BusLocationService {
  static final BusLocationService _instance = BusLocationService._internal();
  factory BusLocationService() => _instance;
  BusLocationService._internal();

  final List<LiveBus> _buses = [];
  final StreamController<List<LiveBus>> _busStreamController =
      StreamController<List<LiveBus>>.broadcast();
  Timer? _updateTimer;
  Timer? _firebaseIotTimer;
  final NotificationService _notificationService = NotificationService();
  final Map<String, DateTime> _lastNotificationTime = {};
  final Map<String, DateTime> _lastWarningTime = {};
  /// Track last seen time for IoT devices to determine online status
  final Map<String, DateTime> _iotLastSeen = {};





  // Tracked buses to limit notification spam
  List<String> _trackedBusIds = [];


  void setTrackedBuses(List<String> busIds) {
    _trackedBusIds = busIds;
    debugPrint("Now tracking exactly ${busIds.length} buses: $busIds");
  }
  int _userRouteIndex = 0; // Cached user index on regular route
  int _userRouteIndexReturn = 0; // Cached user index on return route

  Stream<List<LiveBus>> get busStream => _busStreamController.stream;
  List<LiveBus> get buses => List.unmodifiable(_buses);
  List<LiveBus> get allLiveBuses => List.from(_buses);
  // Erumely → Koovappally → Kottayam waypoints
  static final List<LatLng> waypoints = [
    const LatLng(9.4810562, 76.8450521), // Erumely
    const LatLng(9.5005000, 76.8500000), // Erumely North
    const LatLng(9.525651, 76.827199), // Koovappally
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
  LatLng _userLocation = const LatLng(9.525651, 76.827199); // Default: Koovappally (will update)
  LatLng get userLocation => _userLocation;
  
  void updateUserLocation(LatLng location, [String? placeName]) {
      _userLocation = location;
      if (placeName != null) {
        _currentUserPlace = placeName;
      } else {
        _identifyNearestPlace(location);
      }
      // Re-calculate the cached index
      if (_initialized) {
        _userRouteIndex = _userIndex(_interpolatedRoute);
        _userRouteIndexReturn = _userIndex(_interpolatedRouteReturn);
      }
      debugPrint("Updated user location to $_currentUserPlace ($location)");
  }
  
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
    'Koovappally': LatLng(9.525651, 76.827199),
    'Ponkunnam': LatLng(9.5656117, 76.7546495),
    'Vazhoor': LatLng(9.6040, 76.6730),
    'Amal Jyothi': LatLng(9.52816, 76.82379),
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

  String _currentUserPlace = "Koovappally"; // Default

  /// Fetch actual road geometry from OSRM
  Future<List<LatLng>> _fetchOSRMRoute(List<LatLng> points) async {
    try {
      final coords = points.map((w) => '${w.longitude},${w.latitude}').join(';');
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
    return _generateDenseRoute(points, 12.0);
  }

  /// Initialize service: fetch OSRM route and create 30 buses
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize notifications
    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    _interpolatedRoute = await _fetchOSRMRoute(waypoints);
    _interpolatedRouteReturn = await _fetchOSRMRoute(waypointsReturn);
    
    debugPrint('Route A has ${_interpolatedRoute.length} points');
    debugPrint('Route B has ${_interpolatedRouteReturn.length} points');

    // Cache user index on the route
    _userRouteIndex = _userIndex(_interpolatedRoute);
    _userRouteIndexReturn = _userIndex(_interpolatedRouteReturn);
    debugPrint('User location index A: $_userRouteIndex, B: $_userRouteIndexReturn');

    // Create 30 buses: 15 on Erumely->Kottayam, 15 on Kottayam->Erumely
    
    // Route A: Erumely -> Kottayam
    final segmentLengthA = _interpolatedRoute.length ~/ 15;
    final List<BusStop> stopsA = [
      BusStop(name: 'Erumely', position: keyPlaces['Erumely']!),
      BusStop(name: 'Koovappally', position: keyPlaces['Koovappally']!),
      BusStop(name: 'Kanjirappally', position: keyPlaces['Kanjirappally']!),
      BusStop(name: 'Ponkunnam', position: keyPlaces['Ponkunnam']!),
      BusStop(name: 'Vazhoor', position: keyPlaces['Vazhoor']!),
      BusStop(name: 'Pampady', position: keyPlaces['Pampady']!),
      BusStop(name: 'Kottayam', position: keyPlaces['Kottayam']!),
    ];

    for (int i = 0; i < 15; i++) {
      final id = (i + 1).toString().padLeft(3, '0');
      final startIdx = (i * segmentLengthA) % _interpolatedRoute.length;
      final bus = LiveBus(
        busId: 'KL-ERU-$id',
        busName: 'Erumely Express $id',
        routeName: 'Erumely - Kottayam',
        from: 'Erumely',
        to: 'Kottayam',
        route: _interpolatedRoute,
        index: startIdx,
        speedMps: 8.0 + Random().nextDouble() * 6.0,
        status: i < 10 ? 'RUNNING' : 'SCHEDULED', // first 10 running
        stops: stopsA,
      );
      _buses.add(bus);
      _addRouteToDatabase(bus);
    }

    // Route B: Kottayam -> Erumely
    final segmentLengthB = _interpolatedRouteReturn.length ~/ 15;
    final List<BusStop> stopsB = stopsA.reversed.toList();

    for (int i = 0; i < 15; i++) {
      final id = (i + 16).toString().padLeft(3, '0');
      final startIdx = (i * segmentLengthB) % _interpolatedRouteReturn.length;
      final bus = LiveBus(
        busId: 'KL-KTM-$id',
        busName: 'Kottayam Express $id',
        routeName: 'Kottayam - Erumely',
        from: 'Kottayam',
        to: 'Erumely',
        route: _interpolatedRouteReturn,
        index: startIdx,
        speedMps: 8.0 + Random().nextDouble() * 6.0,
        status: i < 10 ? 'RUNNING' : 'SCHEDULED',
        stops: stopsB,
      );
      _buses.add(bus);
      _addRouteToDatabase(bus);
    }

    debugPrint('Initialized simulations. Loading saved buses...');
    await _loadBuses();
    
    _busStreamController.add(List.from(_buses));

    // Start movement simulation for Kerala buses (every 3s)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateBuses();
    });



    // Start Firebase IoT live data polling (every 2s)
    _firebaseIotTimer?.cancel();
    _fetchFirebaseIoT(); // first fetch immediately
    _firebaseIotTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchFirebaseIoT();
    });
  }

  /// Firebase Realtime Database base URL
  static const String _firebaseBase =
      'https://yathrikan-mini-default-rtdb.firebaseio.com';

  /// Holds the "always-on" IoT live position from the root /gps node.
  /// Shown on map even without an admin bus being added.
  LiveBus? _permanentIotBus;

  /// Creates / updates the permanent IoT marker (root /gps path).
  /// Called once at startup and then on every poll via _fetchFirebaseIoT.
  void _upsertPermanentIotMarker(double lat, double lng, [double? speed]) {
    const id = 'IOT-LIVE-GPS';
    final pos = LatLng(lat, lng);

    if (_permanentIotBus == null) {
      _permanentIotBus = LiveBus(
        busId: id,
        busName: '🛰️ IoT Live Bus',
        routeName: 'Live GPS Tracker',
        from: 'GPS Device',
        to: 'GPS Device',
        status: 'RUNNING',
        isFirebaseIot: true,
        deviceId: '',
        directPosition: pos,
        speedMps: speed != null ? speed / 3.6 : 10.0,
      );
      // Insert at front
      _buses.insert(0, _permanentIotBus!);
    } else {
      _permanentIotBus!.directPosition = pos;
      if (speed != null) {
        _permanentIotBus!.speedMps = speed / 3.6;
      }
      // Ensure it's still in the list (e.g. if removed by admin)
      if (!_buses.any((b) => b.busId == id)) {
        _buses.insert(0, _permanentIotBus!);
      }
    }
  }

  /// Polls Firebase for IoT bus positions.
  /// Strategy for each bus:
  ///   1. Try /<deviceId>/gps.json  (per-device, multi-bus setup)
  ///   2. If null/missing, fall back to /gps.json  (root, single-device setup)
  /// Also always updates the permanent root-/gps marker so the position is
  /// visible on the map even without an admin-added bus.
  Future<void> _fetchFirebaseIoT() async {
    // ── Always poll root /gps for the permanent IoT marker ──────────────────
    try {
      final rootResp = await http
          .get(Uri.parse('$_firebaseBase/gps.json'))
          .timeout(const Duration(seconds: 5));
      if (rootResp.statusCode == 200) {
        final d = json.decode(rootResp.body);
        if (d != null) {
          final lat = (d['lat'] ?? d['latitude'] as num?)?.toDouble();
          final lng = (d['lng'] ?? d['lon'] ?? d['longitude'] as num?)?.toDouble();
          
          if (lat != null && lng != null) {
            final speed = (d['speed'] as num?)?.toDouble() ?? (d['speedKmph'] as num?)?.toDouble();
            _upsertPermanentIotMarker(lat, lng, speed);
            _iotLastSeen['IOT-LIVE-GPS'] = DateTime.now();
            debugPrint('📡 IoT root GPS: $lat, $lng, Speed: $speed');
          }
        }
      }
    } catch (e) {
      debugPrint('Firebase root /gps fetch error: $e');
    }

    // ── Per-admin-added IoT bus: try device path, fallback to root ───────────
    final iotBuses = _buses.where((b) => b.isFirebaseIot && b.deviceId.isNotEmpty).toList();

    bool anyUpdated = _permanentIotBus != null;
    for (final bus in iotBuses) {
      try {
        // Stage 1: device-specific path
        LatLng? newPos;
        final devicePath = '$_firebaseBase/${bus.deviceId}/gps.json';
        final resp1 = await http
            .get(Uri.parse(devicePath))
            .timeout(const Duration(seconds: 5));
        if (resp1.statusCode == 200) {
          final d = json.decode(resp1.body);
          if (d != null) {
            final lat = (d['lat'] ?? d['latitude'] as num?)?.toDouble();
            final lng = (d['lng'] ?? d['lon'] ?? d['longitude'] as num?)?.toDouble();
            
            if (lat != null && lng != null) {
              newPos = LatLng(lat, lng);
              final speed = (d['speed'] as num?)?.toDouble() ?? (d['speedKmph'] as num?)?.toDouble();
              if (speed != null) {
                bus.speedMps = speed / 3.6;
              }
              _iotLastSeen[bus.deviceId] = DateTime.now();
              debugPrint('📡 IoT [${bus.busId}] device path: $lat, $lng, Speed: $speed');
            }
          }
        }

        // Stage 2: fallback to root /gps if device path returned nothing
        if (newPos == null) {
          final resp2 = await http
              .get(Uri.parse('$_firebaseBase/gps.json'))
              .timeout(const Duration(seconds: 5));
          if (resp2.statusCode == 200) {
            final d = json.decode(resp2.body);
            if (d != null) {
              final lat = (d['lat'] ?? d['latitude'] as num?)?.toDouble();
              final lng = (d['lng'] ?? d['lon'] ?? d['longitude'] as num?)?.toDouble();
              
              if (lat != null && lng != null) {
                newPos = LatLng(lat, lng);
                final speed = (d['speed'] as num?)?.toDouble() ?? (d['speedKmph'] as num?)?.toDouble();
                if (speed != null) {
                  bus.speedMps = speed / 3.6;
                }
                _iotLastSeen[bus.deviceId] = DateTime.now();
                debugPrint('📡 IoT [${bus.busId}] fallback /gps: $lat, $lng, Speed: $speed');
              }
            }
          }
        }

        if (newPos != null) {
          bus.directPosition = newPos;
          anyUpdated = true;
        }
      } catch (e) {
        debugPrint('Firebase IoT fetch error for ${bus.busId}: $e');
      }
    }

    if (anyUpdated) {
      _busStreamController.add(List.from(_buses));
    }
  }

  void _updateBuses() {
    for (final bus in _buses) {
      if (bus.route.isNotEmpty && bus.status == 'RUNNING') {
        if (!bus.isFirebaseIot) {
          // Move forward along route
          final step = (bus.speedMps * 3 / 12.0).round().clamp(1, 5);
          bus.index = (bus.index + step) % bus.route.length;
        }

        // We need to use the cached index relevant to this bus's route
        final userIdx = _getUserIndexForBus(bus);

        // Ensure we only notify for tracked buses if tracking is active
        final isTracked = _trackedBusIds.contains(bus.busId);

        // ── 30-minute early warning ──────────────────────────────────────────
        final eta = etaMinutes(bus);
        if (isTracked && eta >= 28 && eta <= 32) {
          final now = DateTime.now();
          final lastWarn30 = _lastWarningTime['${bus.busId}_30'];
          if (lastWarn30 == null || now.difference(lastWarn30).inMinutes >= 60) {
            _lastWarningTime['${bus.busId}_30'] = now;
            _sendBusNotification(bus, 'push_bus_warning_title_early', 'push_bus_warning_body_early');
          }
        }

        // ── 1-minute range warning ──────────────────────────────────────────
        // Only notify when the bus is approaching and is ~1 min away (30-80 steps).
        final stepsToUser = userIdx - bus.index;

        if (isTracked && stepsToUser >= 30 && stepsToUser <= 80) {
          final now = DateTime.now();
          final lastWarn = _lastWarningTime[bus.busId];
          if (lastWarn == null || now.difference(lastWarn).inMinutes >= 20) {
            _lastWarningTime[bus.busId] = now;
            _sendBusNotification(bus, 'push_bus_warning_title', 'push_bus_warning_body');
            debugPrint('🔔 Warning: ${bus.busId} ~1 min from $_currentUserPlace');
          }
        }
      }
    }
    _busStreamController.add(List.from(_buses));
  }

  void _sendBusNotification(LiveBus bus, String titleKey, String bodyKey) {
    SharedPreferences.getInstance().then((prefs) {
      final lang = prefs.getString('languageCode') ?? 'en';
      final loc = AppLocalizations(Locale(lang));
      
      final transName = loc.translate(bus.busName);
      final transFrom = loc.translate(bus.from);
      final transTo = loc.translate(bus.to);
      final transPlace = loc.translate(_currentUserPlace);
      
      String title = loc.translate(titleKey).replaceAll('{0}', transName);
      String body = loc.translate(bodyKey)
          .replaceAll('{0}', transFrom)
          .replaceAll('{1}', transTo)
          .replaceAll('{2}', transPlace);

      _notificationService.showNotification(
        id: bus.busId.hashCode ^ titleKey.hashCode,
        title: title,
        body: body,
        payload: '${bus.busId}|${bus.to}',
      );
    });
  }

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
    // If it's an IoT bus with a live position, always consider it "relevant"
    // to keep it from disappearing while tracked or live.
    if (bus.isFirebaseIot && bus.directPosition != null) return true;
    
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

  /// Registers a newly added bus and, for admin-added buses with explicit
  /// from/to cities, fetches an OSRM road route between those cities so the
  /// bus follows real roads on the map.
  Future<void> addBus(LiveBus bus) async {
    _buses.add(bus);
    _busStreamController.add(List.from(_buses));

    // Resolve from/to city coordinates
    final fromCoords = keyPlaces[bus.from];
    final toCoords   = keyPlaces[bus.to];

    if (fromCoords != null && toCoords != null && bus.from != bus.to) {
      // Fetch real road geometry for this bus, including all stops as waypoints
      final List<LatLng> waypoints = bus.stops.isNotEmpty 
          ? bus.stops.map((s) => s.position).toList()
          : [fromCoords, toCoords];
          
      final roadRoute = await _fetchOSRMRoute(waypoints);
      if (roadRoute.isNotEmpty) {
        bus.route = roadRoute;
        bus.index = 0;
        // Clear directPosition so position() now uses route array
        if (!bus.isFirebaseIot) {
          bus.directPosition = null;
        }
        debugPrint('🛣️ Admin bus ${bus.busId}: loaded ${roadRoute.length} road pts through ${bus.stops.length} stops');
      }
    } else if (bus.route.isEmpty && _interpolatedRoute.isNotEmpty) {
      // Fallback: use the default main route
      bus.route = _interpolatedRoute;
    }

    // Register this bus's route in the search database
    _addRouteToDatabase(bus);

    await _saveBuses();
    _busStreamController.add(List.from(_buses));
  }

  Future<void> _saveBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only save non-simulated, non-permanent-iot buses
      final toSave = _buses.where((b) => 
        !b.busId.startsWith('KL-ERU-') && 
        !b.busId.startsWith('KL-KTM-') && 
        b.busId != 'IOT-LIVE-GPS'
      ).toList();
      
      final jsonStr = jsonEncode(toSave.map((b) => b.toMap()).toList());
      await prefs.setString('saved_buses', jsonStr);
      debugPrint('💾 Saved ${toSave.length} buses to prefs');
    } catch (e) {
      debugPrint('Error saving buses: $e');
    }
  }

  Future<void> _loadBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_buses');
      if (jsonStr == null) return;
      
      final List<dynamic> list = jsonDecode(jsonStr);
      for (final item in list) {
        final bus = LiveBus.fromMap(item as Map<String, dynamic>);
        // Skip legacy MBTA buses that might have been saved in previous versions
        if (bus.busId.startsWith('MBTA-')) continue;

        // Avoid duplicates if already partially initialized
        if (!_buses.any((b) => b.busId == bus.busId)) {
          _buses.add(bus);
          _addRouteToDatabase(bus);
        }
      }
      debugPrint('📥 Loaded ${list.length} buses from prefs');
    } catch (e) {
      debugPrint('Error loading buses: $e');
    }
  }

  /// Verifies if a device ID exists and has valid GPS data in Firebase.
  Future<bool> testConnection(String deviceId) async {
    try {
      final path = deviceId.isEmpty ? 'gps.json' : '$deviceId/gps.json';
      final url = '$_firebaseBase/$path';
      debugPrint('🔍 Testing IoT connection: $url');
      
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      debugPrint('📡 Response status: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final d = json.decode(resp.body);
        debugPrint('📡 Response body: $d');
        
        if (d == null) return false;
        
        // Be flexible with keys (lat/latitude, lng/lon/longitude)
        final hasLat = d['lat'] != null || d['latitude'] != null;
        final hasLng = d['lng'] != null || d['lon'] != null || d['longitude'] != null;
        
        return hasLat && hasLng;
      }
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
    }
    return false;
  }

  /// Returns true if the device has sent data in the last 60 seconds.
  bool isDeviceOnline(String deviceId) {
    if (deviceId.isEmpty) deviceId = 'IOT-LIVE-GPS';
    final lastSeen = _iotLastSeen[deviceId];
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen).inSeconds < 60;
  }

  void removeBus(String busId) {
    _buses.removeWhere((b) => b.busId == busId);
    _saveBuses();
    _busStreamController.add(List.from(_buses));
  }

  void updateBusStatus(String busId, String status) {
    try {
      final bus = _buses.firstWhere((b) => b.busId == busId);
      bus.status = status;
      _saveBuses();
      _busStreamController.add(List.from(_buses));
    } catch (e) { debugPrint("Bus not found: $busId"); }
  }

  // ── Stop order along the main route (Erumely → Kottayam) ────────────────
  // Index 0 = start, higher index = closer to Kottayam.
  // Route B is the same list reversed.
  static const List<String> _routeStopsA = [
    'erumely', 'koovappally', 'kanjirappally', 'ponkunnam', 'kottayam',
    'changanassery', 'pala', 'ettumanoor', 'thalayolaparambu', 'kumarakom',
  ];

  // Translate any user-typed name (English or Malayalam) to the normalised key.
  static const Map<String, String> _placeNorm = {
    // English variants
    'erumely': 'erumely', 'koovappally': 'koovappally', 'koovapally': 'koovappally', 'koovapply': 'koovappally',
    'kanjirappally': 'kanjirappally', 'ponkunnam': 'ponkunnam',
    'kottayam': 'kottayam', 'kottyam': 'kottayam', 'changanassery': 'changanassery',
    'pala': 'pala', 'ettumanoor': 'ettumanoor',
    'thalayolaparambu': 'thalayolaparambu', 'kumarakom': 'kumarakom',
    'mundakayam': 'mundakayam', 'amal jyothi': 'koovappally', 'amaljyothi': 'koovappally',
    // Malayalam equivalents
    'എറുമേലി': 'erumely',
    'കൂവപ്പള്ളി': 'koovappally',
    'കാഞ്ഞിരപ്പള്ളി': 'kanjirappally',
    'പൊൻകുന്നം': 'ponkunnam',
    'കോട്ടയം': 'kottayam',
    'ചങ്ങനാശ്ശേരി': 'changanassery',
    'പാല': 'pala',
    'എട്ടുമാനൂർ': 'ettumanoor',
    'അമൽ ജ്യോതി': 'koovappally',
  };

  String _norm(String input) =>
      _placeNorm[input.trim()] ?? _placeNorm[input.trim().toLowerCase()] ?? input.trim().toLowerCase();

  /// Public method to normalize names
  String normalizeLocationName(String input) => _norm(input);

  // -----------------------------------------------------------------------
  // Bus Route Database & Transfer Algorithm
  // -----------------------------------------------------------------------

  /// All known bus routes as ordered stop lists (normalised lower-case).
  /// Non-const so admin-added buses can append their routes at runtime.
  static final List<Map<String, dynamic>> busRouteDatabase = [
    {
      'bus': 'Erumely Express',
      'route': ['erumely', 'erumely north', 'koovappally', 'kanjirappally', 'ponkunnam', 'vazhoor', 'kottayam'],
    },
    {
      'bus': 'Kottayam Express',
      'route': ['kottayam', 'vazhoor', 'ponkunnam', 'kanjirappally', 'koovappally', 'erumely north', 'erumely'],
    },
    {
      'bus': 'Kanjirappally - Pala Bus',
      'route': ['kanjirappally', 'bharananganam', 'pala'],
    },
    {
      'bus': 'Ponkunnam - Pala Bus',
      'route': ['ponkunnam', 'lalam', 'pala'],
    },
    {
      'bus': 'Erattupetta - Pala Bus',
      'route': ['erattupetta', 'bharananganam', 'pala'],
    },
    {
      'bus': 'Kanjirappally - Erattupetta Bus',
      'route': ['kanjirappally', 'erattupetta'],
    },
    {
      'bus': 'Pala - Kottayam Bus',
      'route': ['pala', 'bharananganam', 'kuravilangad', 'ettumanoor', 'kottayam'],
    },
    {
      'bus': 'Kottayam - Pala Bus',
      'route': ['kottayam', 'ettumanoor', 'kuravilangad', 'bharananganam', 'pala'],
    },
  ];

  /// Adds a new entry to the live route database so the bus shows in
  /// shortest-route search. Builds a sequence: [Origin → Stop1 → ... → Destination].
  void _addRouteToDatabase(LiveBus bus) {
    final List<String> fullRoute = [];
    fullRoute.add(_norm(bus.from));
    for (final stop in bus.stops) {
      fullRoute.add(_norm(stop.name));
    }
    fullRoute.add(_norm(bus.to));

    // Filter out potential consecutive duplicates (e.g. if origin matches first stop)
    final List<String> distinctStops = [];
    for (final s in fullRoute) {
      if (distinctStops.isEmpty || distinctStops.last != s) {
        distinctStops.add(s);
      }
    }

    if (distinctStops.length < 2) return;

    // Remove existing entry for this specific bus name if present to allow updates
    busRouteDatabase.removeWhere((r) => r['bus'] == bus.busName);

    busRouteDatabase.add({
      'bus': bus.busName,
      'route': distinctStops,
    });
    debugPrint('📋 Registered "${bus.busName}" with ${distinctStops.length} searchable stops');
  }

  /// Checks if a bus serves a route from [from] to [to] (normalised or raw).
  bool servesSearchPath(LiveBus bus, String from, String to) {
    if (from.isEmpty) return true; // everything matches empty origin
    final fromNorm = _norm(from);
    final toNorm = _norm(to);

    // 1. Check updated database
    final entry = busRouteDatabase.firstWhere(
      (r) => r['bus'] == bus.busName,
      orElse: () => {},
    );
    if (entry.isNotEmpty) {
      final List<String> stops = List<String>.from(entry['route']);
      final fi = stops.indexOf(fromNorm);
      final ti = stops.indexOf(toNorm);
      
      if (fi != -1) {
        if (toNorm.isEmpty) return true;
        if (ti != -1 && fi < ti) return true;
      }
    }

    // 2. Legacy/Fallback check against bus field properties
    final bFrom = _norm(bus.from);
    final bTo   = _norm(bus.to);
    if (bFrom == fromNorm && (toNorm.isEmpty || bTo == toNorm)) return true;

    return false;
  }

  /// Finds direct and 1-transfer bus routes between [start] and [end].
  /// Returns a list of [FoundRoute] (empty if nothing found).
  List<FoundRoute> findRoutes(String start, String end) {
    final fromNorm = _norm(start);
    final toNorm   = _norm(end);
    final List<FoundRoute> results = [];

    // ── Step 0: Ensure database knows about all current buses ────────────────
    for (final b in _buses) {
      _addRouteToDatabase(b);
    }

    // ── Step 1: Direct routes ──────────────────────────────────────────────
    for (final r in busRouteDatabase) {
      final stops = List<String>.from(r['route'] as List);
      final fi = stops.indexOf(fromNorm);
      final ti = stops.indexOf(toNorm);
      if (fi != -1 && ti != -1 && fi < ti) {
        results.add(FoundRoute(
          type: 'direct',
          bus1Name: r['bus'] as String,
          leg1Stops: stops.sublist(0, ti + 1), // Start drawing from the bus's origin
        ));
      }
    }
    if (results.isNotEmpty) return results;

    // ── Step 2: 1-transfer routes ──────────────────────────────────────────
    final Set<String> seen = {};
    for (final r1 in busRouteDatabase) {
      final s1 = List<String>.from(r1['route'] as List);
      final fi = s1.indexOf(fromNorm);
      if (fi == -1) continue;

      for (int si = fi + 1; si < s1.length; si++) {
        final transferStop = s1[si];
        for (final r2 in busRouteDatabase) {
          if (r2 == r1) continue;
          final s2 = List<String>.from(r2['route'] as List);
          final ti2 = s2.indexOf(toNorm);
          final ts2 = s2.indexOf(transferStop);
          if (ts2 != -1 && ti2 != -1 && ts2 < ti2) {
            final key = '${r1['bus']}|${r2['bus']}|$transferStop';
            if (!seen.contains(key)) {
              seen.add(key);
              results.add(FoundRoute(
                type: 'transfer',
                bus1Name: r1['bus'] as String,
                bus2Name: r2['bus'] as String,
                transferStop: transferStop,
                leg1Stops: s1.sublist(0, si + 1), // Start drawing from the bus's origin
                leg2Stops: s2.sublist(ts2, ti2 + 1), // Start red bus at transfer
              ));
            }
          }
        }
      }
    }
    return results;
  }

  /// Return the keyPlaces LatLng for a normalised stop name (private).
  LatLng? _latLngForStop(String normName) {
    for (final entry in keyPlaces.entries) {
      if (entry.key.toLowerCase() == normName) return entry.value;
    }
    return null;
  }

  /// Public version — used by the UI to resolve stop names to map coordinates.
  LatLng? getLatLngForStop(String normName) => _latLngForStop(normName);

  List<Map<String, dynamic>> findBusesForUser({
    required String startLocation,
    required String endLocation,
    required TimeOfDay userCurrentTime,
  }) {
    final fromNorm = _norm(startLocation);
    final toNorm   = _norm(endLocation);

    // Determine route direction from stop-order indices
    final fromIdx = _routeStopsA.indexOf(fromNorm);
    final toIdx   = _routeStopsA.indexOf(toNorm);

    String? requiredRouteName; // null = show all matching
    if (fromIdx != -1 && toIdx != -1) {
      if (fromIdx < toIdx) {
        requiredRouteName = 'Erumely - Kottayam'; // travelling toward Kottayam
      } else {
        requiredRouteName = 'Kottayam - Erumely';  // travelling toward Erumely
      }
    } else {
       // use route order to guess direction for unknown stops on the main route if they happen to be listed here
       const routeOrder = ['erumely', 'erumely north', 'koovappally', 'kanjirappally', 'ponkunnam', 'vazhoor', 'kottayam', 'ettumanoor', 'kuravilangad', 'bharananganam', 'pala'];
       final fi = routeOrder.indexOf(fromNorm);
       final ti = routeOrder.indexOf(toNorm);
       if (fi != -1 && ti != -1) {
           if (fi < ti) {
               requiredRouteName = 'Erumely - Kottayam'; 
           } else {
               requiredRouteName = 'Kottayam - Erumely'; 
           }
       }
    }

    // Use the 'from' stop coordinates so isIncoming checks relative to that stop,
    // not the user's GPS. This ensures only buses that haven't passed 'from' yet appear.
    final fromLatLng = _latLngForStop(fromNorm);

    final matchingBuses = _buses.where((b) {
      if (b.status != 'RUNNING') return false;
      if (requiredRouteName != null && !b.routeName.contains(requiredRouteName)) {
        return false;
      }
      // Bus must not have passed the 'from' stop yet
      return isIncoming(b, relativeTo: fromLatLng);
    }).toList();

    matchingBuses.sort((a, b) => etaMinutes(a, relativeTo: fromLatLng)
        .compareTo(etaMinutes(b, relativeTo: fromLatLng)));

    // Estimate travel time as distance from from-stop to to-stop
    final toLatLng = _latLngForStop(toNorm);
    int travelMin = 45;
    if (fromLatLng != null && toLatLng != null) {
      final distM = const Distance().as(LengthUnit.Meter, fromLatLng, toLatLng);
      travelMin = (distM / (30000 / 60)).ceil(); // ~30 km/h average
    }

    return matchingBuses.map((b) {
      final arrivalEta = etaMinutes(b, relativeTo: fromLatLng);
      final now = DateTime.now();
      final reach = now.add(Duration(minutes: arrivalEta + travelMin));
      return {
        'busName': b.busName,
        'arrivalTime': arrivalEta == 0 ? 'Now' : '$arrivalEta min',
        'reachTime': '${reach.hour}:${reach.minute.toString().padLeft(2, '0')}',
        'duration': '$travelMin min',
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





  void dispose() {
    _updateTimer?.cancel();
    _firebaseIotTimer?.cancel();
    _busStreamController.close();
  }
}

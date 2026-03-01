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

class BusLocationService {
  static final BusLocationService _instance = BusLocationService._internal();
  factory BusLocationService() => _instance;
  BusLocationService._internal();

  final List<LiveBus> _buses = [];
  /// Real-time MBTA vehicles at their actual US coordinates
  final List<LiveBus> _mbtaBuses = [];
  final StreamController<List<LiveBus>> _busStreamController =
      StreamController<List<LiveBus>>.broadcast();
  Timer? _updateTimer;
  Timer? _mbtaTimer;
  Timer? _mbtaLerpTimer;
  final NotificationService _notificationService = NotificationService();
  final Map<String, DateTime> _lastNotificationTime = {};
  final Map<String, DateTime> _lastWarningTime = {};

  // MBTA API key
  static const String _mbtaApiKey = 'ddec6fb4aadf4f4db40509fc75891796';
  // Poll interval (ms) — interpolation uses this as the denominator
  static const int _mbtaPollMs = 10000;

  // Per-bus interpolation state
  final Map<String, LatLng> _mbtaPrev   = {};  // position when last API arrived
  final Map<String, LatLng> _mbtaTarget = {};  // position from last API response
  DateTime _mbtaLastFetch = DateTime(2000);    // far past so t starts at 1.0

  /// Update _mbtaBuses list and interpolation targets from fresh API data.
  Future<void> _fetchMbtaBuses() async {
    try {
      // include=trip gives us headsign (final destination) for each vehicle
      final url = Uri.parse(
          'https://api-v3.mbta.com/vehicles?api_key=$_mbtaApiKey&filter[revenue]=REVENUE&include=trip');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      final List<dynamic> vehicles = data['data'] ?? [];
      final List<dynamic> included  = data['included'] ?? [];

      // Build trip_id → headsign map from sideloaded trip objects
      final Map<String, String> tripHeadsign = {};
      for (final item in included) {
        if ((item['type'] as String?) == 'trip') {
          final tripId = item['id']?.toString();
          final headsign = item['attributes']?['headsign']?.toString();
          if (tripId != null && headsign != null && headsign.isNotEmpty) {
            tripHeadsign[tripId] = headsign;
          }
        }
      }

      // Build a map of new data keyed by busId
      final Map<String, Map<String, dynamic>> incoming = {};
      for (final v in vehicles) {
        final attrs = v['attributes'] as Map<String, dynamic>?;
        if (attrs == null) continue;
        final double? lat = (attrs['latitude'] as num?)?.toDouble();
        final double? lon = (attrs['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        final String vehicleId = 'MBTA-${v['id'] ?? incoming.length}';
        final String routeId = v['relationships']?['route']?['data']?['id']?.toString() ?? 'Unknown';
        final String? tripId = v['relationships']?['trip']?['data']?['id']?.toString();
        final String headsign = (tripId != null ? tripHeadsign[tripId] : null) ?? 'Unknown';
        final int? dirId = (attrs['direction_id'] as num?)?.toInt();
        final String dirLabel = dirId == 0 ? 'Outbound' : dirId == 1 ? 'Inbound' : '';

        incoming[vehicleId] = {
          'lat': lat, 'lon': lon,
          'label': attrs['label']?.toString() ?? vehicleId,
          'status': (attrs['current_status'] as String?) ?? 'IN_TRANSIT_TO',
          'bearing': (attrs['bearing'] as num?)?.toInt() ?? 0,
          'speed': (attrs['speed'] as num?)?.toDouble() ?? 10.0,
          'route': routeId,
          'headsign': headsign,       // final destination
          'direction': dirLabel,      // Inbound / Outbound
        };
      }

      // For each incoming vehicle: update existing bus OR create new one.
      // Prev = current interpolated position so there is no jump.
      final now = DateTime.now();

      final existingIds = {for (final b in _mbtaBuses) b.busId};
      final incomingIds = incoming.keys.toSet();

      // Remove buses that disappeared from the API
      _mbtaBuses.removeWhere((b) => !incomingIds.contains(b.busId));
      _mbtaPrev.removeWhere((id, _) => !incomingIds.contains(id));
      _mbtaTarget.removeWhere((id, _) => !incomingIds.contains(id));

      for (final entry in incoming.entries) {
        final id = entry.key;
        final d = entry.value;
        final newLatLng = LatLng(d['lat'] as double, d['lon'] as double);
        final String direction = d['direction'] as String;
        final String headsign  = d['headsign'] as String;
        final String routeId   = d['route'] as String;

        if (existingIds.contains(id)) {
          // Update existing bus: prev = wherever it currently is (smooth handoff)
          final bus = _mbtaBuses.firstWhere((b) => b.busId == id);
          _mbtaPrev[id] = bus.directPosition ?? newLatLng;
          _mbtaTarget[id] = newLatLng;
          bus.headingDeg = (d['bearing'] as int).toDouble();
          bus.speedMps = (d['speed'] as double).clamp(2.0, 30.0);
          bus.status = (d['status'] as String) == 'STOPPED_AT' ? 'STOPPED' : 'RUNNING';
        } else {
          // New bus: start at the API position with no interpolation needed
          _mbtaPrev[id] = newLatLng;
          _mbtaTarget[id] = newLatLng;
          _mbtaBuses.add(LiveBus(
            busId: id,
            busName: 'Route $routeId',
            routeName: direction.isNotEmpty ? '$routeId · $direction' : routeId,
            from: 'Route $routeId',
            to: headsign,            // actual destination from headsign
            route: [], index: 0,
            speedMps: (d['speed'] as double).clamp(2.0, 30.0),
            status: (d['status'] as String) == 'STOPPED_AT' ? 'STOPPED' : 'RUNNING',
            headingDeg: (d['bearing'] as int).toDouble(),
            directPosition: newLatLng,
          ));
        }
      }

      _mbtaLastFetch = now;
      debugPrint('🚌 MBTA: updated ${_mbtaBuses.length} vehicles (${tripHeadsign.length} headsigns)');
    } catch (e) {
      debugPrint('MBTA fetch error: $e');
    }
  }

  /// Called every 300ms — smoothly moves each MBTA bus using two modes:
  /// 1. Ease-in-out lerp (t < 1.0): glides bus from prev → target.
  /// 2. Dead reckoning (t > 1.0): extrapolates beyond target using heading+speed
  ///    so the bus keeps moving while waiting for the next API fetch.
  void _lerpMbtaBuses() {
    if (_mbtaBuses.isEmpty) return;
    final elapsedMs = DateTime.now().difference(_mbtaLastFetch).inMilliseconds;
    final double rawT = elapsedMs / _mbtaPollMs; // can exceed 1.0

    for (final bus in _mbtaBuses) {
      final prev   = _mbtaPrev[bus.busId];
      final target = _mbtaTarget[bus.busId];
      if (prev == null || target == null) continue;

      if (rawT <= 1.0) {
        // ── Phase 1: Ease-in-out lerp prev → target ─────────────────────
        // Cubic ease-in-out: smooth at both ends, no abrupt start/stop
        final double t = rawT < 0.5
            ? 2 * rawT * rawT
            : -1 + (4 - 2 * rawT) * rawT;
        bus.directPosition = LatLng(
          prev.latitude  + (target.latitude  - prev.latitude)  * t,
          prev.longitude + (target.longitude - prev.longitude) * t,
        );
      } else {
        // ── Phase 2: Dead reckoning past target ──────────────────────────
        // Bus has reached target; keep it moving at last known speed+bearing
        // so it doesn't freeze while waiting for the next API poll.
        final overSecs = (elapsedMs - _mbtaPollMs) / 1000.0;
        final distMeters = bus.speedMps * overSecs;
        final bearingRad = bus.headingDeg * pi / 180.0;

        // Earth approximation: 1° lat ≈ 111 320 m; 1° lon ≈ 111 320 * cos(lat)
        const metersPerDegLat = 111320.0;
        final metersPerDegLon = 111320.0 * cos(target.latitude * pi / 180.0);

        bus.directPosition = LatLng(
          target.latitude  + (distMeters * cos(bearingRad)) / metersPerDegLat,
          target.longitude + (distMeters * sin(bearingRad)) / metersPerDegLon,
        );
      }
    }
    _busStreamController.add([...List.from(_buses), ...List.from(_mbtaBuses)]);
  }

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
    for (int i = 0; i < 15; i++) {
      final id = (i + 1).toString().padLeft(3, '0');
      final startIdx = (i * segmentLengthA) % _interpolatedRoute.length;
      _buses.add(LiveBus(
        busId: 'KL-ERU-$id',
        busName: 'Erumely Express $id',
        routeName: 'Erumely - Kottayam',
        from: 'Erumely',
        to: 'Kottayam',
        route: _interpolatedRoute,
        index: startIdx,
        speedMps: 8.0 + Random().nextDouble() * 6.0,
        status: i < 10 ? 'RUNNING' : 'SCHEDULED', // first 10 running
      ));
    }

    // Route B: Kottayam -> Erumely
    final segmentLengthB = _interpolatedRouteReturn.length ~/ 15;
    for (int i = 0; i < 15; i++) {
      final id = (i + 16).toString().padLeft(3, '0');
      final startIdx = (i * segmentLengthB) % _interpolatedRouteReturn.length;
      _buses.add(LiveBus(
        busId: 'KL-KTM-$id',
        busName: 'Kottayam Express $id',
        routeName: 'Kottayam - Erumely',
        from: 'Kottayam',
        to: 'Erumely',
        route: _interpolatedRouteReturn,
        index: startIdx,
        speedMps: 8.0 + Random().nextDouble() * 6.0,
        status: i < 10 ? 'RUNNING' : 'SCHEDULED',
      ));
    }

    debugPrint('Initialized ${_buses.length} simulated buses');
    _busStreamController.add(List.from(_buses));

    // Start movement simulation for Kerala buses (every 3s)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateBuses();
    });

    // Start MBTA live data polling (every 10s)
    _mbtaTimer?.cancel();
    _fetchMbtaBuses(); // first fetch immediately
    _mbtaTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchMbtaBuses();
    });

    // Smooth lerp timer for MBTA buses (every 300ms)
    _mbtaLerpTimer?.cancel();
    _mbtaLerpTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _lerpMbtaBuses();
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
        // We need to use the cached index relevant to this bus's route
        final userIdx = _getUserIndexForBus(bus);
        
        final crossedUser = prevIdx < userIdx &&
            bus.index >= userIdx &&
            (bus.index - userIdx).abs() <= tolerance;

        // Also check wrapping (bus was near end, user near start)
        final nearUser = (bus.index - userIdx).abs() <= tolerance;

        // Ensure we only notify for tracked buses if tracking is active
        final isTracked = _trackedBusIds.contains(bus.busId);

        if (isTracked && (crossedUser || nearUser)) {
          final now = DateTime.now();
          final lastTime = _lastNotificationTime[bus.busId];
          
          // Cooldown: Only notify if never notified or last notification was > 20 mins ago
          if (lastTime == null || now.difference(lastTime).inMinutes >= 20) {
            _lastNotificationTime[bus.busId] = now;
            
            SharedPreferences.getInstance().then((prefs) {
                final lang = prefs.getString('languageCode') ?? 'en';
                final loc = AppLocalizations(Locale(lang));
                
                final transName = loc.translate(bus.busName);
                final transFrom = loc.translate(bus.from);
                final transTo = loc.translate(bus.to);
                final transPlace = loc.translate(_currentUserPlace);
                
                String title = loc.translate('push_bus_here_title').replaceAll('{0}', transName);
                String body = loc.translate('push_bus_here_body')
                    .replaceAll('{0}', transFrom)
                    .replaceAll('{1}', transTo)
                    .replaceAll('{2}', bus.busId)
                    .replaceAll('{3}', transPlace);

                _notificationService.showNotification(
                  id: bus.busId.hashCode,
                  title: title,
                  body: body,
                  payload: '${bus.busId}|${bus.to}',
                );
            });
            debugPrint('🔔 Notification: ${bus.busId} arrived at $_currentUserPlace');
          }
        }

        // ── 1-minute early warning ──────────────────────────────────────────
        // At ~12m per index point and bus speed ~8-14 m/s:
        //   1 min = 60s. Steps ahead ≈ speed(m/s) * 60 / 12 ≈ 40-70 points.
        //   We use a fixed window of 30-80 points (~360m-960m) as "≈1 min away".
        final stepsToUser = (userIdx - bus.index) % bus.route.length;
        if (isTracked && stepsToUser >= 30 && stepsToUser <= 80) {
          final now = DateTime.now();
          final lastWarn = _lastWarningTime[bus.busId];
          if (lastWarn == null || now.difference(lastWarn).inMinutes >= 20) {
            _lastWarningTime[bus.busId] = now;
            
            SharedPreferences.getInstance().then((prefs) {
                final lang = prefs.getString('languageCode') ?? 'en';
                final loc = AppLocalizations(Locale(lang));
                
                final transName = loc.translate(bus.busName);
                final transFrom = loc.translate(bus.from);
                final transTo = loc.translate(bus.to);
                final transPlace = loc.translate(_currentUserPlace);
                
                String title = loc.translate('push_bus_warning_title').replaceAll('{0}', transName);
                String body = loc.translate('push_bus_warning_body')
                    .replaceAll('{0}', transFrom)
                    .replaceAll('{1}', transTo)
                    .replaceAll('{2}', transPlace);

                _notificationService.showNotification(
                  id: bus.busId.hashCode + 1,
                  title: title,
                  body: body,
                  payload: '${bus.busId}|${bus.to}',
                );
            });
            debugPrint('🔔 Early warning: ${bus.busId} ~1 min from $_currentUserPlace');
          }
        }
      }
    }
    _busStreamController.add([...List.from(_buses), ...List.from(_mbtaBuses)]);
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
    _mbtaTimer?.cancel();
    _mbtaLerpTimer?.cancel();
    _busStreamController.close();
  }
}

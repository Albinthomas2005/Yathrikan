import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import 'dart:async';
import 'dart:math';
import '../models/route_path_model.dart';
import '../services/osrm_routing_service.dart';
import '../services/notification_service.dart';
import '../utils/app_localizations.dart';
import '../services/bus_location_service.dart';
import 'dart:convert';
import '../models/live_bus_model.dart';
import '../models/route_history_item.dart';
import '../utils/string_utils.dart';
import '../data/kerala_places.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusOption {
  final String id;
  final String name;
  final String type;
  final String time;
  final DateTime departureTime;
  final String duration;
  final double price;
  final int seatsLeft;
  final String origin;
  final String destination;
  final String arrivalTimeAtOrigin;
  final String arrivalTimeAtDestination;
  final LiveBus? liveBusData;

  BusOption({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.departureTime,
    required this.duration,
    required this.price,
    required this.seatsLeft,
    required this.origin,
    required this.destination,
    required this.arrivalTimeAtOrigin,
    required this.arrivalTimeAtDestination,
    this.liveBusData,
    this.minutesToUser,
    this.arrivalAtUserStr,
  });

  final int? minutesToUser;
  final String? arrivalAtUserStr;
}

class ShortestRouteScreen extends StatefulWidget {
  final String? initialDestination;
  const ShortestRouteScreen({super.key, this.initialDestination});

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
  final TextEditingController _fromController = TextEditingController();
  late final TextEditingController _toController;
  List<RouteHistoryItem> _recentRoutes = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  final MapController _mapController = MapController();
  final NotificationService _notificationService = NotificationService();

  // Route State
  RoutePath? _currentRoutePath;
  bool _isRouteLoading = false;
  LatLng? _busLocation;
  int _currentWaypointIndex = 0;
  Timer? _simulationTimer;
  String _etaText = "Calculate Route";
  bool _hasNotified = false;
  String _pickupEtaText = "-- min";
  bool _hasNotifiedPickup = false;

  // Bus Selection State
  bool _showBusList = false;
  List<BusOption> _availableBuses = [];
  BusOption? _selectedBus;

  LatLng _currentLocation = const LatLng(9.9312, 76.2673);

  final Map<String, LatLng> _staticLocations = {
    'Aluva': const LatLng(10.1076, 76.3516),
    'Angamaly': const LatLng(10.1963, 76.3860),
    'Chalakudy': const LatLng(10.3073, 76.3330),
    'Edappally': const LatLng(10.0261, 76.3086),
    'Ernakulam North': const LatLng(9.9894, 76.2872),
    'Ernakulam South': const LatLng(9.9696, 76.2917),
    'Fort Kochi': const LatLng(9.9658, 76.2421),
    'Kakkanad': const LatLng(10.0159, 76.3419),
    'Kaloor': const LatLng(9.9934, 76.2991),
    'Kalamassery': const LatLng(10.0573, 76.3149),
    'Kottayam': const LatLng(9.5916, 76.5222),
    'Kozhikode': const LatLng(11.2588, 75.7804),
    'Lulu Mall': const LatLng(10.0271, 76.3079),
    'Marine Drive': const LatLng(9.9774, 76.2751),
    'MG Road': const LatLng(9.9663, 76.2879),
    'Palarivattom': const LatLng(10.0039, 76.3060),
    'Thiruvananthapuram': const LatLng(8.5241, 76.9366),
    'Thrissur': const LatLng(10.5276, 76.2144),
    'Vyttila': const LatLng(9.9656, 76.3190),
    'Changanassery': const LatLng(9.4442, 76.5413),
    'Pala': const LatLng(9.7086, 76.6830),
    'Kumily': const LatLng(9.6083, 77.1691),
    'Kattappana': const LatLng(9.7430, 77.0784),
    'Mundakayam': const LatLng(9.6213, 76.8566),
    'Erumely': const LatLng(9.4820, 76.8797),
    'Pathanamthitta': const LatLng(9.2647, 76.7872),
    'Peermade': const LatLng(9.5772, 76.9694),
    'Thodupuzha': const LatLng(9.8953, 76.7136),
  };

  List<String> get _keralaLocations => KeralaPlaces.all;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialDestination ?? '');
    _checkLocationPermission();
    _startLocationTracking();
    _notificationService.initialize();
    _notificationService.requestPermissions();
    BusLocationService().initialize();
    _loadRecentRoutes();
    
    _getCurrentLocation().then((_) {
      if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
        if (mounted) {
           if (_fromController.text.isEmpty) {
              _fromController.text = "Current Location";
           }
           if (_fromController.text.isNotEmpty) {
              _handleFindRoute();
           }
        }
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 20));

      String placeName = "Unknown Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          placeName = place.locality ?? place.subLocality ?? place.name ?? "Current Location";
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
        placeName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      }

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _fromController.text = placeName;
        });
      }
      _mapController.move(_currentLocation, 14.0);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _loadRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList('recent_routes_v2') ?? [];
    if (mounted) {
      setState(() {
        _recentRoutes = jsonList.map((e) => RouteHistoryItem.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> _saveRecentRoute(String origin, String destination) async {
    if (origin.isEmpty || destination.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentJsonList = prefs.getStringList('recent_routes_v2') ?? [];
    List<RouteHistoryItem> items = currentJsonList.map((e) => RouteHistoryItem.fromJson(jsonDecode(e))).toList();
    items.removeWhere((item) => item.origin.toLowerCase() == origin.toLowerCase() && item.destination.toLowerCase() == destination.toLowerCase());
    items.insert(0, RouteHistoryItem(origin: origin, destination: destination, lastViewed: DateTime.now()));
    if (items.length > 5) items.removeLast();
    await prefs.setStringList('recent_routes_v2', items.map((e) => jsonEncode(e.toJson())).toList());
    if (mounted) {
      setState(() => _recentRoutes = items);
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  List<String> _getAllKnownLocations() {
    final allBuses = BusLocationService().buses;
    final Set<String> knownLocations = {};
    for (var bus in allBuses) {
      if (bus.routeName.contains(' - ')) {
        final parts = bus.routeName.split(' - ');
        if (parts.length >= 2) {
          knownLocations.add(parts[0].trim());
          knownLocations.add(parts[1].trim());
        }
      }
    }
    knownLocations.addAll(_staticLocations.keys);
    knownLocations.addAll(KeralaPlaces.all);
    return knownLocations.toList();
  }

  List<BusOption> _searchRealBuses(String from, String to, {bool strict = true}) {
    final allBuses = BusLocationService().buses;
    final List<BusOption> matchedBuses = [];
    final now = DateTime.now();
    final searchFrom = from.toLowerCase().trim();
    final searchTo = to.toLowerCase().trim();
    final distanceCalc = const Distance();

    for (var liveBus in allBuses) {
      final routeName = liveBus.routeName.toLowerCase();
      bool matches = false;
      if (strict) {
        matches = routeName.contains(searchFrom) && routeName.contains(searchTo);
      } else {
        if (searchFrom.isNotEmpty && routeName.contains(searchFrom)) matches = true;
        if (searchTo.isNotEmpty && routeName.contains(searchTo)) matches = true;
      }

      if (matches) {
        // Calculate ETA
        double distToUser = 0;
        int minsToUser = 999;
        bool isApproaching = true; // Default to true if no path data

        if (liveBus.routePath != null && liveBus.routePath!.waypoints.isNotEmpty) {
           // Use actual route path
           final userIndex = liveBus.routePath!.findClosestWaypoint(_currentLocation);
           final busIndex = liveBus.currentWaypointIndex;
           
           if (userIndex <= busIndex) {
              // Bus has likely passed the user
              isApproaching = false;
              minsToUser = 9999; // Push to bottom
           } else {
              // Calculate distance along path
              for (int i = busIndex; i < userIndex; i++) {
                 distToUser += distanceCalc.as(LengthUnit.Meter, 
                    liveBus.routePath!.waypoints[i], 
                    liveBus.routePath!.waypoints[i+1]);
              }
              // Speed ~40km/h = ~666 m/min
              minsToUser = (distToUser / 666).round();
           }
        } else {
           // Fallback: Straight line
           distToUser = distanceCalc.as(LengthUnit.Meter, LatLng(liveBus.lat, liveBus.lon), _currentLocation);
           minsToUser = (distToUser / 666).round();
        }

        DateTime arrivalAtUser = now.add(Duration(minutes: minsToUser));
        
        // Mocking Departure/Duration
        int offsetMinutes = (liveBus.busId.hashCode % 30) + 5; 
        DateTime departureTime = now.add(Duration(minutes: offsetMinutes));
        int durationMinutes = 45 + (liveBus.busId.hashCode % 90);
        DateTime destinationTime = departureTime.add(Duration(minutes: durationMinutes));
        String durationStr = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
        
        String formatTime(DateTime dt) {
             int h = dt.hour;
             String ampm = h >= 12 ? 'PM' : 'AM';
             int dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
             return "$dh:${dt.minute.toString().padLeft(2, '0')} $ampm";
        }

        String arrivalAtUserStr = formatTime(arrivalAtUser);
        if (!isApproaching) {
            arrivalAtUserStr = "Departed";
        } else if (minsToUser < 1) {
            arrivalAtUserStr = "Arriving";
        }
        
        matchedBuses.add(BusOption(
          id: liveBus.busId,
          name: "${liveBus.routeName} (${liveBus.busId})",
          type: "Live Bus",
          time: formatTime(departureTime),
          departureTime: departureTime,
          duration: durationStr,
          price: 20.0 + (liveBus.busId.hashCode % 20),
          seatsLeft: 10 + (liveBus.busId.hashCode % 30),
          origin: from,
          destination: to,
          arrivalTimeAtOrigin: formatTime(departureTime),
          arrivalTimeAtDestination: formatTime(destinationTime),
          liveBusData: liveBus,
          minutesToUser: minsToUser,
          arrivalAtUserStr: arrivalAtUserStr,
        ));
      }
    }
    
    // SORT BY ETA TO USER
    matchedBuses.sort((a, b) => (a.minutesToUser ?? 9999).compareTo(b.minutesToUser ?? 9999));
    return matchedBuses;
  }

  Future<void> _handleFindRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both locations")));
      return;
    }

    setState(() {
      _isRouteLoading = true;
      _currentRoutePath = null;
      _simulationTimer?.cancel();
      _busLocation = null;
      _hasNotified = false;
      _etaText = "Calculating...";
    });

    try {
      final candidates = _getAllKnownLocations();
      String? correctedFrom;
      if (!["current location", "my location"].contains(_fromController.text.toLowerCase().trim())) {
         correctedFrom = StringUtils.findClosestMatch(_fromController.text.trim(), candidates);
      }
      final correctedTo = StringUtils.findClosestMatch(_toController.text.trim(), candidates);
      
      if (correctedFrom != null && correctedFrom.toLowerCase() != _fromController.text.toLowerCase().trim()) {
        _fromController.text = correctedFrom;
      }
      if (correctedTo != null && correctedTo.toLowerCase() != _toController.text.toLowerCase().trim()) {
        _toController.text = correctedTo;
      }

      var buses = _searchRealBuses(_fromController.text, _toController.text);
      if (buses.isEmpty) {
        final partialBuses = _searchRealBuses(_fromController.text, _toController.text, strict: false);
        if (partialBuses.isNotEmpty) {
           buses = partialBuses;
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No direct buses found. Showing buses passing through.")));
           }
        } else {
           throw Exception("No buses found matching your search.");
        }
      }

      setState(() {
        _isRouteLoading = false;
        _availableBuses = buses;
        _showBusList = true;
      });
      _saveRecentRoute(_fromController.text.trim(), _toController.text.trim());

    } catch (e) {
      debugPrint("Error finding route: $e");
      setState(() {
        _isRouteLoading = false;
        _etaText = "Error finding route";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  Future<LatLng?> _getCoordinates(String placeName) async {
    final key = _staticLocations.keys.firstWhere((k) => k.toLowerCase() == placeName.toLowerCase(), orElse: () => '');
    if (key.isNotEmpty) return _staticLocations[key];
    try {
      List<Location> locations = await locationFromAddress("$placeName, Kerala");
      if (locations.isNotEmpty) return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      debugPrint("Geocoding failed for $placeName: $e");
    }
    return null;
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10),
    ).listen((Position position) {
      if (!mounted) return;
      final newLocation = LatLng(position.latitude, position.longitude);
      if (_currentLocation != newLocation) {
        setState(() {
          _currentLocation = newLocation;
        });
        if (_selectedBus != null && !_isRouteLoading) {
          _calculateRoute(_selectedBus!);
        }
      }
    });
  }

  Future<void> _calculateRoute(BusOption bus) async {
    setState(() {});
    try {
      LatLng? start;
      if (bus.liveBusData != null) {
         start = LatLng(bus.liveBusData!.lat, bus.liveBusData!.lon);
      } else if (bus.origin.toLowerCase() == "current location" || bus.origin.toLowerCase() == "my location") {
         start = _currentLocation;
      } else {
         start = await _getCoordinates(bus.origin);
      }
      LatLng? end = await _getCoordinates(bus.destination);
      if (start == null || end == null) return;

      final routePath = await OSRMRoutingService.fetchRouteWithWaypoints(
        waypoints: [start, _currentLocation, end],
        routeName: "${bus.origin} -> You -> ${bus.destination}",
      );

      if (routePath != null && mounted) {
        setState(() {
          _currentRoutePath = routePath;
          if (_busLocation == null) {
             int userIndex = 0;
             double minDistance = double.infinity;
             for (int i = 0; i < routePath.waypoints.length; i++) {
                final d = const Distance().as(LengthUnit.Meter, routePath.waypoints[i], _currentLocation);
                if (d < minDistance) {
                   minDistance = d;
                   userIndex = i;
                }
             }
             int offset = (routePath.waypoints.length * 0.15).round();
             if (offset < 20) offset = 20;
             _currentWaypointIndex = (userIndex - offset).clamp(0, routePath.waypoints.length - 1);
             _busLocation = routePath.waypoints[_currentWaypointIndex];
          }
        });
      }
    } catch (e) {
      debugPrint("Error recalculating route: $e");
    }
  }

  Future<void> _selectBus(BusOption bus) async {
    setState(() {
      _selectedBus = bus;
      _showBusList = false;
      _isRouteLoading = true;
      _currentRoutePath = null;
      _simulationTimer?.cancel();
    });
    try {
      await _calculateRoute(bus);
      if (mounted) {
        setState(() {
          _isRouteLoading = false;
          if (_busLocation == null && _currentRoutePath != null) {
             _busLocation = _currentRoutePath!.waypoints.first;
             _currentWaypointIndex = 0;
           }
           
           // Sync initial ETA from bus option
           if (bus.minutesToUser != null) {
              final mins = bus.minutesToUser!;
              if (mins < 1) _pickupEtaText = "Arriving";
              else _pickupEtaText = "$mins min";
           }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_currentRoutePath != null) {
            _fitBounds(_currentRoutePath!.waypoints);
            _startBusSimulation();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching bus route: $e");
      if (mounted) {
        setState(() { _isRouteLoading = false; _showBusList = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _startBusSimulation() {
    const simulationInterval = Duration(seconds: 2);
    _simulationTimer = Timer.periodic(simulationInterval, (timer) {
      if (_currentRoutePath == null) {
        timer.cancel();
        return;
      }
      
      // Pause simulation if bus is IDLE
      if (_selectedBus?.liveBusData?.status == 'IDLE') {
        return;
      }

      setState(() {
        _currentWaypointIndex += 2;
        if (_currentWaypointIndex >= _currentRoutePath!.waypoints.length) {
          _currentWaypointIndex = _currentRoutePath!.waypoints.length - 1;
          timer.cancel();
          _etaText = "Arrived";
          _pickupEtaText = "Arrived";
        }
        _busLocation = _currentRoutePath!.waypoints[_currentWaypointIndex];
        _updateETA();
        _checkProximity();
      });
    });
  }

  void _updateETA() {
    if (_currentRoutePath == null || _busLocation == null) return;
    int userWaypointIndex = _currentWaypointIndex;
    double minDistance = double.infinity;
    for (int i = 0; i < _currentRoutePath!.waypoints.length; i++) {
        final d = const Distance().as(LengthUnit.Meter, _currentRoutePath!.waypoints[i], _currentLocation);
        if (d < minDistance) {
            minDistance = d;
            userWaypointIndex = i;
        }
    }
    double distToEnd = 0;
    for (int i = _currentWaypointIndex; i < _currentRoutePath!.waypoints.length - 1; i++) {
       distToEnd += const Distance().as(LengthUnit.Meter, _currentRoutePath!.waypoints[i], _currentRoutePath!.waypoints[i + 1]);
    }
    double distToPickup = 0;
    if (userWaypointIndex > _currentWaypointIndex) {
        for (int i = _currentWaypointIndex; i < userWaypointIndex; i++) {
           distToPickup += const Distance().as(LengthUnit.Meter, _currentRoutePath!.waypoints[i], _currentRoutePath!.waypoints[i + 1]);
        }
    }
    final totalMinutes = (distToEnd / 666).round();
    final pickupMinutes = (distToPickup / 666).round();

    setState(() {
      if (totalMinutes < 1) _etaText = "Arriving Now";
      else if (totalMinutes < 60) _etaText = "$totalMinutes min";
      else _etaText = "${totalMinutes ~/ 60}h ${totalMinutes % 60}m";

      if (distToPickup <= 0 && _currentWaypointIndex >= userWaypointIndex) _pickupEtaText = "Arrived";
      else if (pickupMinutes < 1) _pickupEtaText = "Arriving";
      else _pickupEtaText = "$pickupMinutes min";
    });
  }

  void _checkProximity() {
    if (_currentRoutePath == null || _busLocation == null) return;
    if (!_hasNotified) {
        final destination = _currentRoutePath!.waypoints.last;
        final distToDest = const Distance().as(LengthUnit.Meter, _busLocation!, destination);
        if (distToDest < 1000) {
          _hasNotified = true;
          _notificationService.showNotification(id: 100, title: "Reaching Destination!", body: "Your bus is nearing ${_toController.text}.");
        }
    }
    if (!_hasNotifiedPickup) {
        final distToUser = const Distance().as(LengthUnit.Meter, _busLocation!, _currentLocation);
        if (distToUser < 500) {
          _hasNotifiedPickup = true;
          _notificationService.showNotification(id: 101, title: "Bus Arriving at Pickup!", body: "The bus is reaching your location now.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus is arriving at your location!")));
        }
    }
  }

  void _onBackPressed() {
    if (_selectedBus != null) {
      setState(() {
        _selectedBus = null;
        _showBusList = true;
        _simulationTimer?.cancel();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedBus == null,
      onPopInvokedWithResult: (didPop, result) {
         if (didPop) return;
         _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: _onBackPressed,
          ),
          title: Text(
            loc.translate('shortest_route'),
            style: AppTextStyles.heading2.copyWith(color: theme.textTheme.titleLarge?.color),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: _selectedBus == null
            ? Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRouteLoading ? null : _handleFindRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.search, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isRouteLoading ? "Finding Route..." : loc.translate('find_route'),
                            style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ROUTE INPUT CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Column(
                        children: [
                          // From Input
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location, color: Colors.blueAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                      return _keralaLocations.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (selection) => _fromController.text = selection,
                                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                       if (controller.text.isEmpty && _fromController.text.isNotEmpty) controller.text = _fromController.text;
                                       controller.addListener(() {
                                          if (_fromController.text != controller.text) _fromController.text = controller.text;
                                       });
                                       return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          onEditingComplete: onEditingComplete,
                                          decoration: InputDecoration(
                                            hintText: loc.translate('from'),
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: Colors.grey.shade500),
                                          ),
                                       );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.gps_fixed, size: 20, color: Colors.grey),
                                  onPressed: () async => await _getCurrentLocation(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // To Input
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                      return _keralaLocations.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (selection) => _toController.text = selection,
                                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                       if (controller.text.isEmpty && _toController.text.isNotEmpty) controller.text = _toController.text;
                                       controller.addListener(() {
                                          if (_toController.text != controller.text) _toController.text = controller.text;
                                       });
                                       return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          onEditingComplete: onEditingComplete,
                                          decoration: InputDecoration(
                                            hintText: loc.translate('to'),
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: Colors.grey.shade500),
                                          ),
                                       );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Swap Button
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.swap_vert, color: Colors.white),
                            onPressed: _swapLocations,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 2. BUS LIST
                if (_showBusList) ...[
                 Text("Select a Bus", style: AppTextStyles.heading2.copyWith(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
                 const SizedBox(height: 15),
                 ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _availableBuses.length,
                   itemBuilder: (context, index) {
                     final bus = _availableBuses[index];
                     return Card(
                       margin: const EdgeInsets.only(bottom: 12),
                       elevation: 2,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       color: theme.cardColor,
                       child: InkWell(
                         onTap: () => _selectBus(bus),
                         borderRadius: BorderRadius.circular(16),
                         child: Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: Row(
                             children: [
                               Container(
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(
                                   color: bus.type == 'KSRTC' ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: Icon(Icons.directions_bus, color: bus.type == 'KSRTC' ? Colors.green : Colors.blue, size: 28),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(bus.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                                     const SizedBox(height: 4),
                                     Row(children: [
                                       Icon(
                                            Icons.access_time, 
                                            size: 14, 
                                            color: bus.arrivalAtUserStr == "Departed" ? Colors.red : ((bus.minutesToUser ?? 99) < 15 ? Colors.green : Colors.grey)
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                            bus.arrivalAtUserStr == "Departed" 
                                                ? "Departed"
                                                : "Arrives: ${bus.arrivalAtUserStr} (${bus.minutesToUser} min)", 
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 12, 
                                                color: bus.arrivalAtUserStr == "Departed" ? Colors.red : ((bus.minutesToUser ?? 99) < 15 ? Colors.green : Colors.black87)
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                       ),
                                     ]),
                                     Text("Dest: ${bus.arrivalTimeAtDestination}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                   ],
                                 ),
                               ),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.end,
                                 children: [
                                   Text("₹${bus.price.toInt()}", style: AppTextStyles.bodyBold.copyWith(fontSize: 18, color: AppColors.primaryYellow)),
                                   Text("${bus.seatsLeft} seats", style: TextStyle(color: bus.seatsLeft < 10 ? Colors.redAccent : Colors.green, fontSize: 12)),
                                 ],
                               ),
                             ],
                           ),
                         ),
                       ),
                     );
                   },
                 ),
                ],

                // 3. MAP PREVIEW
                if (!_showBusList) ...[
                  if (_currentRoutePath == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.translate('preview'), style: AppTextStyles.heading2.copyWith(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
                        Text(loc.translate('full_map'), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  if (_currentRoutePath == null) const SizedBox(height: 15),

                  Container(
                    height: (_currentRoutePath != null && _selectedBus != null) ? 400 : 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentLocation,
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.yathrikan'),
                              if (_currentRoutePath != null)
                                PolylineLayer(polylines: [Polyline(points: _currentRoutePath!.waypoints, strokeWidth: 4.0, color: Colors.blueAccent)]),
                              MarkerLayer(
                                markers: [
                                  if (_currentRoutePath != null) Marker(point: _currentRoutePath!.waypoints.first, width: 40, height: 40, child: const Icon(Icons.my_location, color: Colors.green, size: 40)),
                                  if (_currentRoutePath != null) Marker(point: _currentRoutePath!.waypoints.last, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                                  if (_busLocation != null)
                                    Marker(
                                      point: _busLocation!,
                                      width: 60,
                                      height: 60,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 60, 
                                            height: 60, 
                                            decoration: BoxDecoration(
                                              color: (_selectedBus?.liveBusData?.status == 'IDLE') 
                                                  ? Colors.grey.withValues(alpha: 0.3)
                                                  : Colors.white.withValues(alpha: 0.3), 
                                              shape: BoxShape.circle
                                            )
                                          ),
                                          Container(
                                            width: 40, height: 40,
                                            decoration: BoxDecoration(
                                              color: (_selectedBus?.liveBusData?.status == 'IDLE') ? Colors.grey : Colors.white, 
                                              shape: BoxShape.circle, 
                                              border: Border.all(
                                                color: (_selectedBus?.liveBusData?.status == 'IDLE') ? Colors.grey.shade700 : AppColors.primaryYellow, 
                                                width: 2
                                              )
                                            ),
                                            child: Icon(
                                              Icons.directions_bus, 
                                              color: (_selectedBus?.liveBusData?.status == 'IDLE') ? Colors.white : Colors.black, 
                                              size: 20
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Marker(point: _currentLocation, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40)),
                                ],
                              ),
                            ],
                          ),
                          if (_selectedBus != null)
                            Positioned(
                              top: 20, right: 20,
                              child: FloatingActionButton.small(
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  setState(() { _showBusList = true; _selectedBus = null; _simulationTimer?.cancel(); });
                                },
                                child: const Icon(Icons.close, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // RECENT ROUTES
                  if (_selectedBus == null && _recentRoutes.isNotEmpty) ...[
                    Row(children: [Text("Recent Routes", style: AppTextStyles.heading2)]),
                    const SizedBox(height: 10),
                    ..._recentRoutes.map((route) {
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 12.0),
                         child: GestureDetector(
                           onTap: () {
                              setState(() { _fromController.text = route.origin; _toController.text = route.destination; });
                              _handleFindRoute();
                           },
                           child: Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                             child: Row(
                               children: [
                                 const Icon(Icons.history, color: Colors.grey),
                                 const SizedBox(width: 16),
                                 Text("${route.origin} → ${route.destination}", style: AppTextStyles.bodyBold),
                               ],
                             ),
                           ),
                         ),
                       );
                    }),
                    const SizedBox(height: 25),
                  ],

                  // PICKUP ETA
                  if (_selectedBus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryYellow, width: 2)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "On Board: ${_selectedBus!.name}",
                                        style: AppTextStyles.bodyBold,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        "To: ${_toController.text}",
                                        style: const TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_etaText, style: AppTextStyles.heading2),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [const Icon(Icons.person_pin_circle, color: Colors.blueAccent), const SizedBox(width: 8), Text("Your Pickup:", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500))]),
                                Text(_pickupEtaText, style: AppTextStyles.bodyBold.copyWith(color: _pickupEtaText.contains("Arriv") ? Colors.green : Colors.blueAccent, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

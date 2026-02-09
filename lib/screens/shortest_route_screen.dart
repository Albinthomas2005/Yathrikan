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
  final String type; // KSRTC, Private, AC
  final String time; // Display time string
  final DateTime departureTime; // Actual time for sorting
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
  });
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

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialDestination ?? '');
    _checkLocationPermission();
    _notificationService.initialize();
    _notificationService.requestPermissions();
    BusLocationService().initialize();
    _loadRecentRoutes(); // Load history (Restored)
    
    // Auto-search logic
    _getCurrentLocation().then((_) {
      // If we have a destination from Chatbot
      if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
        if (mounted) {
           // If 'From' is still empty but we have location, set it to "Current Location"
           if (_fromController.text.isEmpty) {
              _fromController.text = "Current Location";
           }
           
           // Trigger search if we have both fields (even if From is "Current Location")
           if (_fromController.text.isNotEmpty) {
              _handleFindRoute();
           }
        }
      }
    });
  }

  Future<void> _loadRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList('recent_routes_v2') ?? [];
    
    if (mounted) {
      setState(() {
        _recentRoutes = jsonList
            .map((e) => RouteHistoryItem.fromJson(jsonDecode(e)))
            .toList();
      });
    }
  }

  Future<void> _saveRecentRoute(String origin, String destination) async {
    if (origin.isEmpty || destination.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentJsonList = prefs.getStringList('recent_routes_v2') ?? [];
    
    // Convert to objects
    List<RouteHistoryItem> items = currentJsonList
        .map((e) => RouteHistoryItem.fromJson(jsonDecode(e)))
        .toList();

    // Remove duplicates (same origin & dest)
    items.removeWhere((item) => 
        item.origin.toLowerCase() == origin.toLowerCase() && 
        item.destination.toLowerCase() == destination.toLowerCase());
    
    // Add to top
    items.insert(0, RouteHistoryItem(
      origin: origin,
      destination: destination,
      lastViewed: DateTime.now(),
    ));
    
    // Keep max 5
    if (items.length > 5) items.removeLast();
    
    // Save back
    await prefs.setStringList('recent_routes_v2', 
        items.map((e) => jsonEncode(e.toJson())).toList());

    // Update UI immediately
    if (mounted) {
      setState(() {
        _recentRoutes = items;
      });
    }
  }



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

  // Bus Selection State
  bool _showBusList = false;
  List<BusOption> _availableBuses = [];
  BusOption? _selectedBus;

  // Default to Kochi
  LatLng _currentLocation = const LatLng(9.9312, 76.2673);
  // _isLoadingLocation removed

  // Static locations for fallback
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



  // Using KeralaPlaces.all instead of local list
  List<String> get _keralaLocations => KeralaPlaces.all;



  @override
  void dispose() {
    _simulationTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return;
    }

    // Permissions granted, but we don't auto-fetch anymore
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // balanced -> low for better success rate
        ),
      ).timeout(const Duration(seconds: 20));

      String placeName = "Unknown Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Prioritize locality (City) or name/subLocality
          placeName = place.locality ??
              place.subLocality ??
              place.name ??
              "Current Location";
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
        placeName =
            "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      }

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _fromController.text = placeName;

          // Also update the Autocomplete controller if possible
          // Note: This is tricky since we don't hold a reference to the Autocomplete's internal controller here.
          // The listener in build() handles syncing back from _fromController.
        });
      }

      // Move map to new location
      _mapController.move(_currentLocation, 14.0);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() {
          _fromController.text = ""; // Clear "Locating..." on error
        });

        String errorMessage = "Could not get location. Please try again.";
        if (e is TimeoutException) {
          errorMessage = "Location request timed out. Please check your GPS signal.";
        } else if (e.toString().contains("Location services are disabled")) {
          errorMessage = "Location services are disabled. Please enable them.";
        } else if (e.toString().contains("denied")) {
          errorMessage = "Location permission denied.";
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
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
    // Add expansive list
    knownLocations.addAll(KeralaPlaces.all);
    return knownLocations.toList();
  }

  List<BusOption> _searchRealBuses(String from, String to, {bool strict = true}) {
    // 1. Get real buses from service
    final allBuses = BusLocationService().buses;
    final List<BusOption> matchedBuses = [];
    final now = DateTime.now();
    
    final searchFrom = from.toLowerCase().trim();
    final searchTo = to.toLowerCase().trim();

    for (var liveBus in allBuses) {
      final routeName = liveBus.routeName.toLowerCase();

      bool matches = false;
      if (strict) {
        // STRICT MODE: Route name must contain both locations
        matches = routeName.contains(searchFrom) && routeName.contains(searchTo);
      } else {
        // PARTIAL MODE: Matches either Origin OR Destination
        // Useful for showing "Buses from X" or "Buses to Y"
        if (searchFrom.isNotEmpty && routeName.contains(searchFrom)) matches = true;
        if (searchTo.isNotEmpty && routeName.contains(searchTo)) matches = true;
      }

      if (matches) {
        // Create a display-friendly object
        
        // Depart in (busId hash % 30) minutes to look realistic
        int offsetMinutes = (liveBus.busId.hashCode % 30) + 5; 
        DateTime departureTime = now.add(Duration(minutes: offsetMinutes));
        
        // Calculate duration (approx 45m to 2h)
        int durationMinutes = 45 + (liveBus.busId.hashCode % 90);
        DateTime destinationTime = departureTime.add(Duration(minutes: durationMinutes));
        String durationStr = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
        
        int hour = departureTime.hour;
        String amPm = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        String originTimeStr = "$displayHour:${departureTime.minute.toString().padLeft(2, '0')} $amPm";
        
        int destHour = destinationTime.hour;
        String destAmPm = destHour >= 12 ? 'PM' : 'AM';
        int destDisplayHour = destHour > 12 ? destHour - 12 : (destHour == 0 ? 12 : destHour);
        String destTimeStr = "$destDisplayHour:${destinationTime.minute.toString().padLeft(2, '0')} $destAmPm";

        matchedBuses.add(BusOption(
          id: liveBus.busId,
          name: "${liveBus.routeName} (${liveBus.busId})",
          type: "Live Bus", // Showing it's real
          time: originTimeStr,
          departureTime: departureTime,
          duration: durationStr, // Dynamic
          price: 20.0 + (liveBus.busId.hashCode % 20), // Placeholder price
          seatsLeft: 10 + (liveBus.busId.hashCode % 30), // Placeholder seats
          origin: from, // Used for routing
          destination: to, // Used for routing
          arrivalTimeAtOrigin: originTimeStr,
          arrivalTimeAtDestination: destTimeStr,
          liveBusData: liveBus,
        ));
      }
    }

    // Sort by departure time
    matchedBuses.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return matchedBuses;
  }

  Future<void> _handleFindRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both locations")),
      );
      return;
    }

    setState(() {
      _isRouteLoading = true;
      _currentRoutePath = null;
      _simulationTimer?.cancel();
      _busLocation = null;
      _hasNotified = false; // Reset notification flag
      _etaText = "Calculating...";
    });

    try {
      // 1. Auto-correction Logic (Visual)
      // Get all known locations
      final candidates = _getAllKnownLocations();
      
      // Find matches - skip for "Current Location"
      String? correctedFrom;
      if (!["current location", "my location"].contains(_fromController.text.toLowerCase().trim())) {
         correctedFrom = StringUtils.findClosestMatch(_fromController.text.trim(), candidates);
      }
      
      final correctedTo = StringUtils.findClosestMatch(_toController.text.trim(), candidates);
      
      // Update UI if corrections found
      if (correctedFrom != null && correctedFrom.toLowerCase() != _fromController.text.toLowerCase().trim()) {
        _fromController.text = correctedFrom;
      }
      if (correctedTo != null && correctedTo.toLowerCase() != _toController.text.toLowerCase().trim()) {
        _toController.text = correctedTo;
      }

      // 2. Search for Real Buses
      // Pass actual coordinates if "Current Location" to avoid geocoding issues in search logic if we were using it there
      // But _searchRealBuses currently uses string matching. 
      // We should probably rely on the names for now as per current logic, 
      // OR update _searchRealBuses to handle coordinates (which is complex).
      // For now, let's keep the bus search string-based but ensure we don't fail geocoding for the MAP route later.
      
      var buses = _searchRealBuses(_fromController.text, _toController.text);
      
      if (buses.isEmpty) {
        // FALLBACK: Try partial match
        // If we can't find direct route, check for ANY buses that go through these places
        // This answers "buses have to list not have to there is no bus like that"
        final partialBuses = _searchRealBuses(_fromController.text, _toController.text, strict: false);
        
        if (partialBuses.isNotEmpty) {
           buses = partialBuses;
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No direct buses found. Showing buses passing through these locations.")),
              );
           }
        } else {
           throw Exception("No buses found matching your search.");
        }
      }

      setState(() {
        _isRouteLoading = false;
        _availableBuses = buses;
        _showBusList = true; // Show the list
      });
      
      // Save successful search (Advanced)
      _saveRecentRoute(_fromController.text.trim(), _toController.text.trim());

    } catch (e) {
      debugPrint("Error finding route: $e");
      setState(() {
        _isRouteLoading = false;
        _etaText = "Error finding route";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  /// Helper to get coordinates with fallback
  Future<LatLng?> _getCoordinates(String placeName) async {
    // 1. Check static map first (Case insensitive check)
    final key = _staticLocations.keys.firstWhere(
      (k) => k.toLowerCase() == placeName.toLowerCase(),
      orElse: () => '',
    );
    
    if (key.isNotEmpty) {
      return _staticLocations[key];
    }

    // 2. Try Geocoding
    try {
      List<Location> locations = await locationFromAddress("$placeName, Kerala");
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint("Geocoding failed for $placeName: $e");
    }
    
    return null;
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _selectBus(BusOption bus) async {
    setState(() {
      _selectedBus = bus;
      _showBusList = false;
      _isRouteLoading = true; // Show loading while we fetch bus route
      _currentRoutePath = null; // Clear old route
      _simulationTimer?.cancel();
    });

    try {
      // Use LiveBus data if available
      if (bus.liveBusData != null && bus.liveBusData!.routePath != null) {
         // If the bus already has a path, use it!
         final path = bus.liveBusData!.routePath!;
         
         setState(() {
            _currentRoutePath = path;
            _isRouteLoading = false;
            // Use current live location
            _busLocation = LatLng(bus.liveBusData!.lat, bus.liveBusData!.lon);
            // Find closest waypoint index to start tracking
             _currentWaypointIndex = bus.liveBusData!.currentWaypointIndex;
            _hasNotified = false;
         });
         
         WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitBounds(path.waypoints);
            _startBusSimulation();
         });
         return;
      }
    
      // Fallback if no pre-calculated path: Fetch new one
      LatLng? start;
      if (bus.origin.toLowerCase() == "current location" || bus.origin.toLowerCase() == "my location") {
         start = _currentLocation;
      } else {
         start = await _getCoordinates(bus.origin);
      }
      
      LatLng? end = await _getCoordinates(bus.destination);

      if (start == null || end == null) {
        throw Exception("Could not locate bus route points");
      }

      final routePath = await OSRMRoutingService.fetchRoute(
        start: start,
        end: end,
        routeName: "${bus.origin} to ${bus.destination}",
      );

      if (routePath == null) throw Exception("Could not fetch bus route");

      if (mounted) {
        setState(() {
          _currentRoutePath = routePath;
          _isRouteLoading = false;
          _busLocation = _currentRoutePath!.waypoints.first;
          _currentWaypointIndex = 0;
          _hasNotified = false;
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
        setState(() {
          _isRouteLoading = false;
          _showBusList = true; // Go back to list on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error showing bus route: $e")),
        );
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

      // Move bus forward
      setState(() {
        // Advance 2 waypoints per tick for speed
        _currentWaypointIndex += 2;
        if (_currentWaypointIndex >= _currentRoutePath!.waypoints.length) {
          _currentWaypointIndex = _currentRoutePath!.waypoints.length - 1;
          timer.cancel();
          _etaText = "Arrived";
        }

        _busLocation = _currentRoutePath!.waypoints[_currentWaypointIndex];
        _updateETA();
        _checkProximity();
      });
    });
  }

  void _updateETA() {
    if (_currentRoutePath == null || _busLocation == null) return;

    // Calculate distance from current bus location to end
    double distToEnd = 0;
    // Optimization: Calculate from current index
    for (int i = _currentWaypointIndex; i < _currentRoutePath!.waypoints.length - 1; i++) {
       distToEnd += const Distance().as(LengthUnit.Meter,
          _currentRoutePath!.waypoints[i], _currentRoutePath!.waypoints[i + 1]);
    }

    // Bus speed ~40km/h => ~666 m/min
    final totalMinutes = (distToEnd / 666).round();

    setState(() {
      if (totalMinutes < 1) {
        _etaText = "Arriving Now";
      } else if (totalMinutes < 60) {
        _etaText = "$totalMinutes min";
      } else {
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        _etaText = "${hours}h ${mins}m";
      }
    });
  }

  void _checkProximity() {
    if (_hasNotified || _currentRoutePath == null || _busLocation == null) {
      return;
    }

    final destination = _currentRoutePath!.waypoints.last;
    final distance = const Distance().as(LengthUnit.Meter, _busLocation!, destination);

    if (distance < 1000) {
      _hasNotified = true;
      _notificationService.showNotification(
        id: 100,
        title: "Bus Arriving!",
        body: "Your bus is within 1km of ${_toController.text}. Get ready!",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bus is arriving soon! Notification sent.")),
      );
    }
  }

  void _onBackPressed() {
    if (_selectedBus != null) {
      // Return to list view
      setState(() {
        _selectedBus = null;
        _showBusList = true;
        _simulationTimer?.cancel();
        _currentRoutePath = null;
      });
    } else {
      // Exit screen
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
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
                          _isRouteLoading
                              ? "Finding Route..."
                              : loc.translate('find_route'),
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
              // Route Input Card
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location,
                                  color: AppColors.primaryYellow, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text == '') {
                                          return const Iterable<String>.empty();
                                        }
                                        return _keralaLocations
                                            .where((String option) {
                                          return option.toLowerCase().contains(
                                              textEditingValue.text
                                                  .toLowerCase());
                                        });
                                      },
                                      onSelected: (String selection) {
                                        _fromController.text = selection;
                                      },
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onFieldSubmitted) {
                                        // Keep external controller in sync
                                        controller.addListener(() {
                                          if (controller.text !=
                                              _fromController.text) {
                                            _fromController.text =
                                                controller.text;
                                          }
                                        });
                                        // Update internal controller when external changes (e.g. GPS)
                                        if (_fromController.text.isNotEmpty &&
                                            controller.text !=
                                                _fromController.text) {
                                          controller.text =
                                              _fromController.text;
                                          // Move cursor to end to prevent jumpiness
                                          controller.selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: controller
                                                          .text.length));
                                        }

                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          style: TextStyle(
                                              color: theme
                                                  .textTheme.bodyLarge?.color),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText:
                                                loc.translate('your_location'),
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 12),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.gps_fixed,
                                                  color: Colors.blueAccent,
                                                  size: 20),
                                              onPressed: () async {
                                                // Manually trigger location fetch
                                                controller.text = "Locating...";
                                                _fromController.text =
                                                    "Locating...";

                                                LocationPermission permission =
                                                    await Geolocator
                                                        .checkPermission();
                                                if (permission ==
                                                    LocationPermission.denied) {
                                                  permission = await Geolocator
                                                      .requestPermission();
                                                  if (permission ==
                                                      LocationPermission
                                                          .denied) {
                                                    return;
                                                  }
                                                }
                                                if (permission ==
                                                    LocationPermission
                                                        .deniedForever) {
                                                  return;
                                                }

                                                await _getCurrentLocation();
                                              },
                                              tooltip: "Use Current Location",
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // To Input
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.redAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text == '') {
                                          return const Iterable<String>.empty();
                                        }
                                        return _keralaLocations
                                            .where((String option) {
                                          return option.toLowerCase().contains(
                                              textEditingValue.text
                                                  .toLowerCase());
                                        });
                                      },
                                      onSelected: (String selection) {
                                        _toController.text = selection;
                                      },
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onFieldSubmitted) {
                                        controller.addListener(() {
                                          _toController.text = controller.text;
                                        });
                                        if (_toController.text.isNotEmpty &&
                                            controller.text !=
                                                _toController.text) {
                                          controller.text = _toController.text;
                                        }
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          style: TextStyle(
                                              color: theme
                                                  .textTheme.bodyLarge?.color),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: loc.translate(
                                                'search_destination'),
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 12),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Floating Swap Button
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: _swapLocations,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                            color: theme.cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_up_arrow_down,
                            size: 16,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ),

                const SizedBox(height: 25),

                if (_showBusList) ...[
                Text("Select a Bus",
                    style: AppTextStyles.heading2.copyWith(
                        fontSize: 18,
                        color: theme.textTheme.titleLarge?.color)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
                                  color: bus.type == 'KSRTC'
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_bus,
                                  color: bus.type == 'KSRTC'
                                      ? Colors.green
                                      : Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bus.name,
                                      style: AppTextStyles.bodyBold
                                          .copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    // Calculate relative time
                                    Builder(
                                      builder: (context) {
                                        final now = DateTime.now();
                                        final diff = bus.departureTime.difference(now).inMinutes;
                                        final isArrivingSoon = diff <= 15;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Arriving in $diff min  •  ${bus.arrivalTimeAtOrigin}",
                                              style: TextStyle(
                                                  color: isArrivingSoon ? Colors.green : Colors.blue,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Reaches Dest: ${bus.arrivalTimeAtDestination}",
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${bus.price.toInt()}",
                                    style: AppTextStyles.bodyBold.copyWith(
                                        fontSize: 18,
                                        color: AppColors.primaryYellow),
                                  ),
                                  Text(
                                    "${bus.seatsLeft} seats",
                                    style: TextStyle(
                                        color: bus.seatsLeft < 10
                                            ? Colors.redAccent
                                            : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
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

              if (!_showBusList) ...[
                // Preview Header
                if (_currentRoutePath == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.translate('preview'),
                          style: AppTextStyles.heading2.copyWith(
                              fontSize: 18,
                              color: theme.textTheme.titleLarge?.color)),
                      Text(
                        loc.translate('full_map'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (_currentRoutePath == null) const SizedBox(height: 15),

                // Map Preview
                Container(
                  height: (_currentRoutePath != null && _selectedBus != null)
                      ? 400
                      : 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
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
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.yathrikan',
                            ),
                            // Route Polyline
                            if (_currentRoutePath != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _currentRoutePath!.waypoints,
                                    strokeWidth: 4.0,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                // Start Marker
                                if (_currentRoutePath != null)
                                  Marker(
                                    point: _currentRoutePath!.waypoints.first,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.my_location,
                                        color: Colors.green, size: 40),
                                  ),
                                // End Marker
                                if (_currentRoutePath != null)
                                  Marker(
                                    point: _currentRoutePath!.waypoints.last,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on,
                                        color: Colors.red, size: 40),
                                  ),
                                  // Bus Marker - Enhanced
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
                                              color: Colors.white
                                                  .withValues(alpha: 0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: AppColors.primaryYellow,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.directions_bus,
                                              color: Colors.black,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                // Current Location Marker
                                if (_currentRoutePath == null)
                                  Marker(
                                    point: _currentLocation,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.person_pin_circle,
                                        color: Colors.blueAccent, size: 40),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Cancel Navigation Button
                        if (_selectedBus != null)
                          Positioned(
                            top: 20,
                            right: 20,
                            child: FloatingActionButton.small(
                              backgroundColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  _showBusList = true;
                                  _selectedBus = null;
                                  _simulationTimer?.cancel();
                                });
                              },
                              child:
                                  const Icon(Icons.close, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                if (_selectedBus == null) ...[
                  // 1. RECENT ROUTES (Restored)
                  if (_recentRoutes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Routes", style: AppTextStyles.heading2),
                         // Optional: Clear button
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._recentRoutes.map((route) {
                      final diff = DateTime.now().difference(route.lastViewed);
                      String timeAgo;
                      if (diff.inMinutes < 60) {
                        timeAgo = "${diff.inMinutes} mins ago";
                      } else if (diff.inHours < 24) {
                        timeAgo = "${diff.inHours} hours ago";
                      } else {
                        timeAgo = "Yesterday";
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                             // Populate and search
                             setState(() {
                               _fromController.text = route.origin;
                               _toController.text = route.destination;
                             });
                             _handleFindRoute();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.history, color: Colors.grey.shade500, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${route.origin} → ${route.destination}",
                                        style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Last viewed $timeAgo",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 25),
                  ],
               ],


                if (_selectedBus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primaryYellow, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "On Board: ${_selectedBus!.name}",
                                  style: AppTextStyles.bodyBold,
                                  overflow: TextOverflow.ellipsis, // Fix overflow
                                  maxLines: 1,
                                ),
                                Text(
                                  "To: ${_toController.text}",
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis, // Fix overflow
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Text(_etaText, style: AppTextStyles.heading2),
                        ],
                      ),
                  ),
                ),

                const SizedBox(height: 30),

                const SizedBox(height: 20),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
    ),
    ),
  );
  }


}

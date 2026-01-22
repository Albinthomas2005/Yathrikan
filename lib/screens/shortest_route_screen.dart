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

class BusOption {
  final String id;
  final String name;
  final String type; // KSRTC, Private, AC
  final String time;
  final String duration;
  final double price;
  final int seatsLeft;
  final String origin;
  final String destination;

  BusOption({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.duration,
    required this.price,
    required this.seatsLeft,
    required this.origin,
    required this.destination,
  });
}

class ShortestRouteScreen extends StatefulWidget {
  const ShortestRouteScreen({super.key});

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
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

  // Mock Data for Autocomplete
  final List<String> _keralaLocations = [
    'Aluva',
    'Angamaly',
    'Chalakudy',
    'Edappally',
    'Ernakulam North',
    'Ernakulam South',
    'Fort Kochi',
    'Kakkanad',
    'Kaloor',
    'Kalamassery',
    'Kottayam',
    'Kozhikode',
    'Lulu Mall',
    'Marine Drive',
    'MG Road',
    'Palarivattom',
    'Thiruvananthapuram',
    'Thrissur',
    'Vyttila',
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _notificationService.initialize();
    _notificationService.requestPermissions();
  }

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
          accuracy: LocationAccuracy.medium, // balanced -> medium
          timeLimit: Duration(seconds: 10),
        ),
      );

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

        String errorMessage = "Could not get location";
        if (e.toString().contains("Location services are disabled")) {
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

  List<BusOption> _generateMockBuses() {
    final Random random = Random();
    final List<BusOption> buses = [];
    // User requested only Private buses for Mundakayam - Koovalpaly route
    const String type = 'Private';

    // Diverse Private Bus Names
    final List<String> busNames = [
      'St. Marys',
      'Blue Bird',
      'Karthika',
      'Devi Travels',
      'Ave Maria',
      'St. Jude',
      'Royal Cruisers',
      'Angel Wings',
      'City Fast',
      'Highrange',
      'Pala Flyers',
      'Ranni Express',
      'Pathanamthitta Wheels',
      'Erumely Fast',
      'Kanjirappally Spl',
      'Sree Murugan',
      'Vettukallumkuzhi',
      'Holy Cross',
      'Moonlight',
      'Sunrise',
      'Kerala Roadways'
    ];

    // Origins and Destinations to simulate passing buses
    final List<String> origins = [
      'Kottayam',
      'Changanassery',
      'Pala',
      'Ernakulam',
      'Aluva',
      'Thodupuzha'
    ];
    final List<String> destinations = [
      'Kumily',
      'Kattappana',
      'Mundakayam',
      'Erumely',
      'Pathanamthitta',
      'Peermade'
    ];

    for (int i = 0; i < 100; i++) {
      String baseName = busNames[random.nextInt(busNames.length)];

      // Pick random origin and destination
      String busOrigin = origins[random.nextInt(origins.length)];
      String busDest = destinations[random.nextInt(destinations.length)];

      // Ensure they are different
      while (busOrigin == busDest) {
        busDest = destinations[random.nextInt(destinations.length)];
      }

      // Format: "Name (Origin - Dest)"
      // e.g., "St. Marys (Kottayam - Kumily)"
      String name = "$baseName ($busOrigin - $busDest)";

      // Ticket rate 13 - 35
      double price = 13.0 + random.nextInt(23);

      // Random Time
      int hour = 5 + random.nextInt(18); // 5 AM to 11 PM
      int minute = random.nextInt(60);
      String amPm = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : hour;
      String time = "$displayHour:${minute.toString().padLeft(2, '0')} $amPm";

      // Random Duration (Short route: Mundakayam to Koovalpaly)
      int durMin = 20 + random.nextInt(30); // 20 to 50 mins
      String duration = "${durMin}m";

      buses.add(BusOption(
        id: i.toString(),
        name: name,
        type: type,
        time: time,
        duration: duration,
        price: price,
        seatsLeft: 1 + random.nextInt(40), // Private buses usually small/medium
        origin: busOrigin,
        destination: busDest,
      ));
    }

    // Sort by time
    buses.sort((a, b) {
      return a.time.compareTo(b.time);
    });

    return buses;
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
      // 1. Geocode "From" and "To" locations
      List<Location> fromLocations =
          await locationFromAddress("${_fromController.text}, Kerala");
      List<Location> toLocations =
          await locationFromAddress("${_toController.text}, Kerala");

      if (fromLocations.isEmpty || toLocations.isEmpty) {
        throw Exception("Could not find locations");
      }

      LatLng start =
          LatLng(fromLocations.first.latitude, fromLocations.first.longitude);
      LatLng end =
          LatLng(toLocations.first.latitude, toLocations.first.longitude);

      // 2. Fetch Route from OSRM
      final routePath = await OSRMRoutingService.fetchRoute(
        start: start,
        end: end,
        routeName: "${_fromController.text} to ${_toController.text}",
      );

      if (routePath == null) {
        throw Exception("Could not fetch route");
      }

      setState(() {
        _currentRoutePath = routePath;
        _isRouteLoading = false;
        // Generate mock buses for this route
        _availableBuses = _generateMockBuses();
        _showBusList = true; // Show the list instead of map directly
      });

      // Fit bounds
      _fitBounds(routePath.waypoints);

      // 3. Start Simulation (Moved to _selectBus)
      // _startBusSimulation();
    } catch (e) {
      debugPrint("Error finding route: $e");
      setState(() {
        _isRouteLoading = false;
        _etaText = "Error finding route";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
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
      // 1. Geocode Bus Origin and Destination
      // Append ", Kerala" for better accuracy
      List<Location> originLocs =
          await locationFromAddress("${bus.origin}, Kerala");
      List<Location> destLocs =
          await locationFromAddress("${bus.destination}, Kerala");

      if (originLocs.isEmpty || destLocs.isEmpty) {
        throw Exception("Could not locate bus route points");
      }

      LatLng start =
          LatLng(originLocs.first.latitude, originLocs.first.longitude);
      LatLng end = LatLng(destLocs.first.latitude, destLocs.first.longitude);

      // 2. Fetch Route for the Bus
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

          // Reset simulation for new route
          _busLocation = _currentRoutePath!.waypoints.first;
          _currentWaypointIndex = 0;
          _hasNotified = false;
        });

        // Fit bounds and start simulation
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

    // Approximate if getDistanceToWaypoint isn't perfect for current index logic,
    // but calculating distance from current index to end is better:
    double distToEnd = 0;
    for (int i = _currentWaypointIndex;
        i < _currentRoutePath!.waypoints.length - 1;
        i++) {
      distToEnd += const Distance().as(LengthUnit.Meter,
          _currentRoutePath!.waypoints[i], _currentRoutePath!.waypoints[i + 1]);
    }

    final minutes = (distToEnd / 666).round(); // 40km/h => 666m/min

    setState(() {
      if (minutes < 1) {
        _etaText = "Arriving now";
      } else if (minutes > 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        _etaText = "ETA: $hours" "h $mins" "m";
      } else {
        _etaText = "ETA: $minutes min";
      }
    });
  }

  void _checkProximity() {
    if (_hasNotified || _currentRoutePath == null || _busLocation == null) {
      return;
    }

    // Calculate distance to destination (last waypoint)
    final destination = _currentRoutePath!.waypoints.last;
    final distance =
        const Distance().as(LengthUnit.Meter, _busLocation!, destination);

    // Notify if within 1000 meters
    if (distance < 1000) {
      _hasNotified = true;
      _notificationService.showNotification(
        id: 100,
        title: "Bus Arriving!",
        body: "Your bus is within 1km of ${_toController.text}. Get ready!",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bus is arriving soon! Notification sent.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('shortest_route'),
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
        ),
        centerTitle: true,
      ),
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
                                    Text(
                                      "${bus.time} • ${bus.duration}",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                                // Bus Marker
                                if (_busLocation != null)
                                  Marker(
                                    point: _busLocation!,
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.directions_bus,
                                      color: AppColors.primaryYellow,
                                      size: 45,
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
                  // Recent Places
                  Text(loc.translate('recent_places'),
                      style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          color: theme.textTheme.titleLarge?.color)),
                  const SizedBox(height: 15),

                  _buildRecentPlaceItem(
                    context,
                    icon: CupertinoIcons.clock,
                    title: loc.translate('central_station'),
                    subtitle: "Main Blvd, Downtown",
                  ),
                  const SizedBox(height: 10),
                  _buildRecentPlaceItem(
                    context,
                    icon: CupertinoIcons.briefcase,
                    title: loc.translate('office_hq'),
                    subtitle: "Tech Park, Sector 4",
                  ),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("On Board: ${_selectedBus!.name}",
                                  style: AppTextStyles.bodyBold),
                              Text("To: ${_toController.text}",
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Text(_etaText, style: AppTextStyles.heading2),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                if (_selectedBus == null)
                  SizedBox(
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
                            style:
                                AppTextStyles.bodyBold.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPlaceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

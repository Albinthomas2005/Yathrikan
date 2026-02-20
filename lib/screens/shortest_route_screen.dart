import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import 'dart:async';
import '../models/route_path_model.dart';
import '../services/notification_service.dart';
import '../utils/app_localizations.dart';
import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';
import '../utils/string_utils.dart';

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
  final int? minutesToUser;
  final String? arrivalAtUserStr;

  BusOption({
    required this.id, required this.name, required this.type,
    required this.time, required this.departureTime, required this.duration,
    required this.price, required this.seatsLeft, required this.origin,
    required this.destination, required this.arrivalTimeAtOrigin,
    required this.arrivalTimeAtDestination, this.liveBusData,
    this.minutesToUser, this.arrivalAtUserStr,
  });
}

class ShortestRouteScreen extends StatefulWidget {
  final String? initialDestination;
  final bool autoDetectOrigin;
  final String? initialBusId; // For notification navigation

  const ShortestRouteScreen({
    super.key,
    this.initialDestination,
    this.autoDetectOrigin = false,
    this.initialBusId,
  });

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
  final TextEditingController _fromController = TextEditingController();
  late final TextEditingController _toController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<LiveBus>>? _busSubscription;

  final MapController _mapController = MapController();
  final NotificationService _notificationService = NotificationService();
  final BusLocationService _busService = BusLocationService();

  RoutePath? _currentRoutePath;
  LatLng? _busLocation;
  String _pickupEtaText = "-- min";

  bool _showBusList = true;
  List<BusOption> _availableBuses = [];
  BusOption? _selectedBus;
  LatLng _currentLocation = const LatLng(9.5425371, 76.8201976); // Default Koovappally, will update
  bool _isLocationLoaded = false;

  // Autocomplete state
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialDestination ?? '');
    _notificationService.initialize();
    _notificationService.requestPermissions();
    _busService.initialize();

    _checkLocationPermission();

    if (widget.autoDetectOrigin) {
      _fromController.text = "Finding location...";
      // _autoDetectLocation() called in _checkLocationPermission or stream
    } else {
      _fromController.text = "Koovappally";
    }

    // Auto-select bus if ID provided
    if (widget.initialBusId != null) {
        // Wait for bus list to be available
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNotificationBus(widget.initialBusId!);
        });
    }

    _busSubscription = _busService.busStream.listen((buses) {
      if (mounted) {
        setState(() {
          if (_showBusList && _fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
            _updateBusList(buses);
          }
          if (_selectedBus != null) {
            final live = buses.firstWhere((b) => b.busId == _selectedBus!.id, orElse: () => _selectedBus!.liveBusData!);
            _busLocation = live.position;
            // Calculate ETA from user location or From location?
            // Usually ETA is to the user.
            final eta = _busService.etaMinutes(live, relativeTo: _currentLocation);
            _pickupEtaText = eta <= 0 ? "Arriving" : "$eta min";
          }
        });
      }
    });

    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _busSubscription?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _handleNotificationBus(String busId) {
    // Initial wait to ensure buses are populated?
    // The stream listener above will handle updates.
    // But we need to switch view mode immediately if possible.
    final bus = _busService.buses.where((b) => b.busId == busId).firstOrNull;
    if (bus != null) {
        final opt = BusOption(
            id: bus.busId, name: bus.busName, type: "Live",
            time: "Now", departureTime: DateTime.now(), duration: "",
            price: 20.0, seatsLeft: 0, origin: bus.from, destination: bus.to,
            arrivalTimeAtOrigin: "", arrivalTimeAtDestination: "",
            liveBusData: bus, minutesToUser: 0, arrivalAtUserStr: ""
        );
        _selectBus(opt);
    }
  }

  void _onFromChanged() {
    final q = _fromController.text;
    if (q.length >= 2 && _fromFocus.hasFocus) {
      setState(() {
        _fromSuggestions = BusLocationService.allPlaces
            .where((p) => p.toLowerCase().contains(q.toLowerCase()))
            .toList();
        _showFromSuggestions = _fromSuggestions.isNotEmpty;
      });
    } else {
      setState(() { _showFromSuggestions = false; });
    }
  }

  void _onToChanged() {
    final q = _toController.text;
    if (q.length >= 2 && _toFocus.hasFocus) {
      setState(() {
        _toSuggestions = BusLocationService.allPlaces
            .where((p) => p.toLowerCase().contains(q.toLowerCase()))
            .toList();
        _showToSuggestions = _toSuggestions.isNotEmpty;
      });
    } else {
      setState(() { _showToSuggestions = false; });
    }
  }

  void _updateBusList(List<LiveBus> buses) {
    // Resolve "From" location to coordinates
    final fromText = _fromController.text.trim();
    // Case-insensitive lookup
    LatLng? fromCoords;
    for (final entry in BusLocationService.keyPlaces.entries) {
        if (entry.key.toLowerCase() == fromText.toLowerCase()) {
            fromCoords = entry.value;
            break;
        }
    }
    
    // Fallback if user means "Current Location"
    if (fromCoords == null && (fromText.toLowerCase() == "current location" || fromText.isEmpty)) {
        fromCoords = _currentLocation;
    }

    final incoming = buses.where((b) {
      if (b.status != 'RUNNING') return false;
      
      // Filter by direction/route if "To" is specified
      // (Simple containment check as before)
      final toText = _toController.text.trim().toLowerCase();
      // If we are solving "Erumely -> Kottayam", we want buses bound for Kottayam.
      // E.g. Bus To: "Kottayam"
      bool matchesRoute = true;
      if (toText.isNotEmpty) {
           matchesRoute = b.to.toLowerCase() == toText || 
                          b.routeName.toLowerCase().contains(toText);
      }
      
      if (!matchesRoute) return false;

      // Check if incoming relative to the "From" location
      return _busService.isIncoming(b, relativeTo: fromCoords); // fromCoords can be null
    }).toList();

    incoming.sort((a, b) {
        // Sort by ETA relative to Start Point
        final etaA = _busService.etaMinutes(a, relativeTo: fromCoords);
        final etaB = _busService.etaMinutes(b, relativeTo: fromCoords);
        return etaA.compareTo(etaB);
    });

    _availableBuses = incoming.map((bus) {
      final eta = _busService.etaMinutes(bus, relativeTo: fromCoords);
      return BusOption(
        id: bus.busId, name: bus.busName, type: "Live",
        time: StringUtils.formatTime(DateTime.now().add(Duration(minutes: eta))),
        departureTime: DateTime.now().add(Duration(minutes: eta)),
        duration: "Var", price: 20.0, seatsLeft: 40,
        origin: bus.from, destination: bus.to,
        arrivalTimeAtOrigin: "", arrivalTimeAtDestination: "",
        liveBusData: bus, minutesToUser: eta, arrivalAtUserStr: "$eta min",
      );
    }).toList();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Start stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocationLoaded = true;
        });
        
        // If "from" was waiting for location
        if (_fromController.text == "Finding location...") {
             _autoDetectLocation(); // Updates text name
        }
      }
    });
  }

  Future<void> _autoDetectLocation() async {
    if (!_isLocationLoaded) {
        // Force get current if stream hasn't fired yet
        try {
            final pos = await Geolocator.getCurrentPosition();
            setState(() {
                _currentLocation = LatLng(pos.latitude, pos.longitude);
                _isLocationLoaded = true;
            });
        } catch (_) {}
    }

    // Find nearest known place
    const Distance dist = Distance();
    double minD = double.infinity;
    String nearest = 'Koovappally';
    
    // Check against all known places for better accuracy
    BusLocationService.keyPlaces.forEach((name, loc) {
        final d = dist.as(LengthUnit.Meter, loc, _currentLocation);
        if (d < minD) { minD = d; nearest = name; }
    });

    setState(() { _fromController.text = nearest; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location detected: $nearest'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  Future<void> _handleFindRoute() async {
    setState(() { _showBusList = true; });
    _updateBusList(_busService.buses);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  Future<void> _selectBus(BusOption bus) async {
    setState(() {
      _selectedBus = bus;
      _showBusList = false;
      _busLocation = bus.liveBusData?.position;
    });
    if (bus.liveBusData != null && bus.liveBusData!.route.isNotEmpty) {
      _currentRoutePath = RoutePath(
        routeName: "Live Route", waypoints: bus.liveBusData!.route,
        totalDistanceMeters: 1000, totalDurationSeconds: 600,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Fit bus and USER location
        final boundsLog = [bus.liveBusData!.route.first, bus.liveBusData!.route.last, _currentLocation];
         // Or just fit route
         _fitBounds(bus.liveBusData!.route);
      });
    }
  }

  void _onBackPressed() {
    if (_selectedBus != null) {
      setState(() { _selectedBus = null; _showBusList = true; });
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSuggestionList(List<String> suggestions, TextEditingController controller, StateSetter setStateCallback) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) => ListTile(
          dense: true,
          leading: const Icon(Icons.location_on_outlined, size: 18),
          title: Text(suggestions[i], style: const TextStyle(fontSize: 14)),
          onTap: () {
            controller.text = suggestions[i];
            setState(() { _showFromSuggestions = false; _showToSuggestions = false; });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedBus == null,
      onPopInvokedWithResult: (didPop, result) { if (didPop) return; _onBackPressed(); },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.iconTheme.color), onPressed: _onBackPressed),
          title: Text(loc.translate('shortest_route'), style: AppTextStyles.heading2.copyWith(color: theme.textTheme.titleLarge?.color)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROUTE INPUT CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor, borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(children: [
                    // From Input with Location Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.my_location, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _fromController, focusNode: _fromFocus,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              hintText: loc.translate('from'), border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                        // Auto-location button
                        IconButton(
                          icon: const Icon(Icons.gps_fixed, color: Colors.blueAccent, size: 22),
                          tooltip: 'Detect my location',
                          onPressed: _autoDetectLocation,
                        ),
                      ]),
                    ),
                    if (_showFromSuggestions) _buildSuggestionList(_fromSuggestions, _fromController, setState),
                    const SizedBox(height: 12),
                    // To Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _toController, focusNode: _toFocus,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              hintText: loc.translate('to'), border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    if (_showToSuggestions) _buildSuggestionList(_toSuggestions, _toController, setState),
                    const SizedBox(height: 12),
                    // Swap + Find row
                    Row(children: [
                      Container(
                        decoration: BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                        child: IconButton(icon: const Icon(Icons.swap_vert, color: Colors.white), onPressed: _swapLocations),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleFindRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow, foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(loc.translate('find_route'), style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 25),

                // BUS LIST
                if (_showBusList) ...[
                  Text("Incoming Buses", style: AppTextStyles.heading2.copyWith(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
                  const SizedBox(height: 15),
                  if (_availableBuses.isEmpty) const Text("No incoming buses found. Tap 'Find Route' to search."),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableBuses.length,
                    itemBuilder: (context, index) {
                      final bus = _availableBuses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12), elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: theme.cardColor,
                        child: InkWell(
                          onTap: () => _selectBus(bus), borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.directions_bus_filled, color: Colors.amber, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(bus.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                                const SizedBox(height: 2),
                                Text(bus.id, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text("ETA: ${bus.arrivalAtUserStr}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                              ])),
                              Text("₹${bus.price.toInt()}", style: AppTextStyles.bodyBold.copyWith(fontSize: 18, color: AppColors.primaryYellow)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // MAP (only when a bus is selected — shows ONLY that bus)
                if (!_showBusList && _selectedBus != null) ...[
                  const SizedBox(height: 25),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(initialCenter: _currentLocation, initialZoom: 12),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.yathrikan'),
                            if (_currentRoutePath != null)
                              PolylineLayer(polylines: [Polyline(points: _currentRoutePath!.waypoints, strokeWidth: 4.0, color: Colors.blueAccent)]),
                            MarkerLayer(markers: [
                              // User location
                              Marker(point: _currentLocation, width: 44, height: 44,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 36),
                                ),
                              ),
                              // ONLY the selected bus
                              if (_busLocation != null)
                                Marker(point: _busLocation!, width: 48, height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.amber, shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 24),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                        // Close button
                        Positioned(top: 12, right: 12,
                          child: FloatingActionButton.small(
                            backgroundColor: theme.cardColor,
                            onPressed: () { setState(() { _showBusList = true; _selectedBus = null; }); },
                            child: Icon(Icons.close, color: theme.iconTheme.color),
                          ),
                        ),
                        // ETA overlay
                        Positioned(bottom: 16, left: 16, right: 16,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_selectedBus!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(_selectedBus!.id, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_pickupEtaText, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ]),
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

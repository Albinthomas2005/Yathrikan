import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart'; // Unnecessary
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; // Unused
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import 'dart:async';

import '../models/route_path_model.dart';
// import '../services/osrm_routing_service.dart'; // Unused
import '../services/notification_service.dart';
import '../utils/app_localizations.dart';
import '../services/bus_location_service.dart';
// import 'dart:convert'; // Unused
import '../models/live_bus_model.dart';
// import '../models/route_history_item.dart'; // Unused
import '../utils/string_utils.dart';
// import '../data/kerala_places.dart'; // Unused
// import 'package:shared_preferences/shared_preferences.dart'; // Unused

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
  // List<RouteHistoryItem> _recentRoutes = []; // Unused
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<LiveBus>>? _busSubscription;

  final MapController _mapController = MapController();
  final NotificationService _notificationService = NotificationService();
  final BusLocationService _busService = BusLocationService();

  // Route State
  RoutePath? _currentRoutePath;
  
  // ignore: unused_field
  LatLng? _busLocation; 
  String _pickupEtaText = "-- min";

  // Bus Selection State
  bool _showBusList = true; // Default to showing list or inputs
  List<BusOption> _availableBuses = [];
  BusOption? _selectedBus;

  final LatLng _currentLocation = const LatLng(9.5361, 76.8254); // Default to Koovappally as per user request


  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialDestination ?? '');
    _checkLocationPermission();
    _startLocationTracking();
    _notificationService.initialize();
    _notificationService.requestPermissions();
    _busService.initialize();
    // _loadRecentRoutes(); // Unused
    
    // Listen to bus updates directly
    _busSubscription = _busService.busStream.listen((buses) {
      if (mounted) {
        setState(() {
           // Refresh list if visible
           if (_showBusList && _fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
              _updateBusList(buses);
           }
           // Update selected bus location if selected
           if (_selectedBus != null) {
              final live = buses.firstWhere((b) => b.busId == _selectedBus!.id, orElse: () => _selectedBus!.liveBusData!);
              _busLocation = live.position;
              final eta = _busService.etaMinutes(live);
              _pickupEtaText = eta <= 0 ? "Arriving/Passed" : "$eta min";
           }
        });
      }
    });

    _fromController.text = "Koovappally"; // Default for demo
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _busSubscription?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
  
  void _updateBusList(List<LiveBus> buses) {
      // Filter logic from user request: "incomingBuses()"
      // But adhering to the From/To somewhat. 
      // User said "LIST BUSES BY TIME (THIS IS WHAT YOU WANT)"
      // So let's just show all incoming buses relative to user location (Koovappally)
      
      // If user searches "Koovappally" to "Ponkunnam", we show buses on that route.
      // Our static data allows us to just show the 3 buses filtered by "incoming".
      
      final incoming = buses
          .where((b) => _busService.isIncoming(b))
          .toList();
      incoming.sort((a, b) => _busService.etaMinutes(a).compareTo(_busService.etaMinutes(b)));

      _availableBuses = incoming.map((bus) {
          final eta = _busService.etaMinutes(bus);
          return BusOption(
            id: bus.busId,
            name: bus.busName,
            type: "Live",
            time: StringUtils.formatTime(DateTime.now().add(Duration(minutes: eta))),
            departureTime: DateTime.now().add(Duration(minutes: eta)),
            duration: "Var",
            price: 20.0,
            seatsLeft: 40,
            origin: bus.from,
            destination: bus.to,
            arrivalTimeAtOrigin: "",
            arrivalTimeAtDestination: "",
            liveBusData: bus,
            minutesToUser: eta,
            arrivalAtUserStr: "$eta min",
          );
      }).toList();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  // Unused _getCurrentLocation removed

  // Unused methods removed


  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  Future<void> _handleFindRoute() async {
    // Just trigger list show, logic happens in _updateBusList which is called by stream
     setState(() {
        _showBusList = true;
        // _saveRecentRoute(_fromController.text, _toController.text); // Unused
     });
     // Force an initial update
     _updateBusList(_busService.buses);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _startLocationTracking() {
      // Just rely on _getCurrentLocation for now
  }

  Future<void> _selectBus(BusOption bus) async {
    setState(() {
      _selectedBus = bus;
      _showBusList = false;
      _busLocation = bus.liveBusData?.position; 
    });
    
    // Show route path mock
    if (bus.liveBusData != null && bus.liveBusData!.route.isNotEmpty) {
       _currentRoutePath = RoutePath(
          routeName: "Live Route", 
          waypoints: bus.liveBusData!.route, 
          totalDistanceMeters: 1000, 
          totalDurationSeconds: 600
       );
       WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds(bus.liveBusData!.route);
       });
    }
  }

  void _onBackPressed() {
    if (_selectedBus != null) {
      setState(() {
        _selectedBus = null;
        _showBusList = true;
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
                                  child: TextField(
                                      controller: _fromController,
                                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                      decoration: InputDecoration(
                                        hintText: loc.translate('from'),
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                      ),
                                   ),
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
                                  child: TextField(
                                      controller: _toController,
                                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                      decoration: InputDecoration(
                                        hintText: loc.translate('to'),
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                      ),
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
                
                 // FIND BUTTON
                 SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleFindRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                         loc.translate('find_route'),
                         style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                      ),
                    ),
                 ),
                 
                 const SizedBox(height: 25),

                 // 2. BUS LIST
                if (_showBusList) ...[
                 Text("Incoming Buses", style: AppTextStyles.heading2.copyWith(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
                 const SizedBox(height: 15),
                 if (_availableBuses.isEmpty)
                    const Text("No incoming buses found."),
                 
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
                                   color: Colors.blue.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: const Icon(
                                    Icons.directions_bus, 
                                    color: Colors.blue, 
                                    size: 28
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(bus.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                                     const SizedBox(height: 4),
                                     Text(
                                          "${bus.arrivalAtUserStr}",
                                           style: const TextStyle(
                                               fontWeight: FontWeight.bold, 
                                               fontSize: 12, 
                                               color: Colors.green
                                           ),
                                     ),
                                   ],
                                 ),
                               ),
                               Text("₹${bus.price.toInt()}", style: AppTextStyles.bodyBold.copyWith(fontSize: 18, color: AppColors.primaryYellow)),
                             ],
                           ),
                         ),
                       ),
                     );
                   },
                 ),
                ],

                // 3. MAP PREVIEW (Using User Snippet Logic)
                if (!_showBusList || true) ...[ // User said: "WHEN USER CLICKS A BUS", but also generally. Let's show map always? NO, let's keep list/map toggle
                  if (!_showBusList) ...[
                  const SizedBox(height: 25),
                  Container(
                    height: 400,
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
                              
                              // MARKERS: buses.map((bus) => ...).toList()
                              MarkerLayer(
                                markers: [
                                  Marker(point: _currentLocation, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40)),
                                  
                                  ..._busService.buses.map((bus) {
                                      return Marker(
                                        point: bus.position,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.directions_bus,
                                          color: Colors.yellow, // User requested Yellow
                                          size: 30, // Make it visible
                                        ),
                                      );
                                  }),
                                ],
                              ),
                            ],
                          ),
                          if (_selectedBus != null)
                            Positioned(
                              top: 20, right: 20,
                              child: FloatingActionButton.small(
                                backgroundColor: theme.cardColor,
                                onPressed: () {
                                  setState(() { _showBusList = true; _selectedBus = null; });
                                },
                                child: Icon(Icons.close, color: theme.iconTheme.color),
                              ),
                            ),
                            
                          // ETA Display Overlay
                          if (_selectedBus != null)
                             Positioned(
                                bottom: 20, left: 20, right: 20,
                                child: Card(
                                   child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                            Text(_selectedBus!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(_pickupEtaText, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                         ],
                                      ),
                                   ),
                                ),
                             )
                        ],
                      ),
                    ),
                  ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

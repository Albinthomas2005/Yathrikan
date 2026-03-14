import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapController = MapController();
  final BusLocationService _busLocationService = BusLocationService();
  StreamSubscription<List<LiveBus>>? _busLocationStream;
  StreamSubscription<Position>? _positionStream;

  // Koovappally default location
  LatLng _currentLocation = const LatLng(9.525651, 76.827199);
  bool _isLoadingLocation = true;
  List<Marker> _busMarkers = [];

  @override
  void initState() {
    super.initState();
    _busLocationService.initialize();
    _initializeLiveBusTracking();
    _startLiveLocationUpdates();
  }

  @override
  void dispose() {
    _busLocationStream?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentLocation, 14.0);
      }
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null && mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
      },
      onError: (e) => debugPrint("Location Stream Error: $e"),
    );
  }

  bool _iotCentered = false; // true after first auto-center to IoT marker

  void _initializeLiveBusTracking() {
    _busLocationStream = _busLocationService.busStream.listen((buses) {
      if (mounted) {
        setState(() {
          _busMarkers = buses.map((bus) => _createBusMarker(bus)).toList();
        });
        // Auto-center map to IoT bus on first appearance
        if (!_iotCentered) {
          final iot = buses.where((b) => b.isFirebaseIot && b.directPosition != null).firstOrNull;
          if (iot != null) {
            _iotCentered = true;
            _mapController.move(iot.directPosition!, 14.0);
            debugPrint('🗺️ Map centered to IoT bus at ${iot.directPosition}');
          }
        }
      }
    });
  }

  Marker _createBusMarker(LiveBus bus) {
    final bool isIot = bus.isFirebaseIot;

    Color busColor;
    Color borderColor;
    IconData icon;

    if (isIot) {
      // IoT bus: bright red bus icon with glow — easy to spot as live tracked
      busColor = Colors.redAccent;
      borderColor = Colors.red.shade800;
      icon = Icons.directions_bus;
    } else if (bus.speedKmph < 15) {
      busColor = Colors.green;
      borderColor = Colors.green;
      icon = Icons.directions_bus;
    } else if (bus.speedKmph < 35) {
      busColor = AppColors.primaryYellow;
      borderColor = AppColors.primaryYellow;
      icon = Icons.directions_bus;
    } else {
      busColor = Colors.orange;
      borderColor = Colors.orange;
      icon = Icons.directions_bus;
    }

    return Marker(
      point: LatLng(bus.lat, bus.lon),
      width: isIot ? 52 : 40,
      height: isIot ? 52 : 40,
      child: GestureDetector(
        onTap: () => _showBusInfo(bus),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isIot ? 2.5 : 0),
            boxShadow: [
              BoxShadow(
                color: busColor.withValues(alpha: isIot ? 0.6 : 0.3),
                blurRadius: isIot ? 10 : 4,
                spreadRadius: isIot ? 3 : 0,
              )
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            color: busColor,
            size: isIot ? 24 : 20,
          ),
        ),
      ),
    );
  }

  void _showBusInfo(LiveBus bus) {
    final bool isMbta = bus.busId.startsWith('MBTA-');
    final bool isRunning = bus.status == 'RUNNING';
    final statusColor = isRunning ? Colors.green : Colors.orange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primaryYellow,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.busName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bus.routeName.isNotEmpty)
                          Text(
                            bus.routeName,
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          bus.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Route: From → To ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Origin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(
                            bus.from,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              color: AppColors.primaryYellow, size: 22),
                        ],
                      ),
                    ),
                    // Destination
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Going to', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(
                            bus.to,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primaryYellow,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Speed + Source tiles
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Speed',
                      '${bus.speedKmph.toStringAsFixed(0)} km/h',
                      Icons.speed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile(
                      isMbta ? 'Source' : (bus.isFirebaseIot ? 'Source' : 'Type'),
                      isMbta ? 'MBTA Live' : (bus.isFirebaseIot ? '🛰️ IoT Live' : 'Kerala Bus'),
                      isMbta ? Icons.wifi : (bus.isFirebaseIot ? Icons.wifi : Icons.map_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryYellow),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.yathrikan',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bus Markers
                  ..._busMarkers,
                ],
              ),
            ],
          ),

          // Top bar with back button and info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.9),
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        CupertinoIcons.back,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.bus,
                            color: AppColors.primaryYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_busMarkers.length} Buses Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recenter button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryYellow,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.black),
              onPressed: () {
                _mapController.move(_currentLocation, 14.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

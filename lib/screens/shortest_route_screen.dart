import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';
=======
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

class ShortestRouteScreen extends StatefulWidget {
  const ShortestRouteScreen({super.key});

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
<<<<<<< HEAD
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final MapController _mapController = MapController();

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
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      )).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
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
        });
      }

      // Move map to new location
      _mapController.move(_currentLocation, 14.0);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() {
          _fromController.text = ""; // clear if failed
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Could not get location: $e"))); // Localized in next iteration if generic
      }
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
=======
  bool _showRoute = false;
  final TextEditingController _fromController =
      TextEditingController(text: 'Current Location');
  final TextEditingController _toController = TextEditingController();

  // Mock Route Points (Kochi style coordinates)
  final List<LatLng> _routePoints = [
    const LatLng(10.8505, 76.2711), // Start
    const LatLng(10.8480, 76.2720),
    const LatLng(10.8450, 76.2735),
    const LatLng(10.8420, 76.2750),
    const LatLng(10.8380, 76.2760), // End
  ];

  void _findRoute() {
    if (_toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    setState(() {
      _showRoute = true;
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
    });
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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

              // Preview Header
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
              const SizedBox(height: 15),

              // Map Preview
              Container(
                height: 200,
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
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on,
                                    color: Colors.blueAccent, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Stats Card Overlay (Simple styling kept for now)
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Recent Places
              Text(loc.translate('recent_places'),
                  style: AppTextStyles.heading2.copyWith(
                      fontSize: 18, color: theme.textTheme.titleLarge?.color)),
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

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Routing Logic
                  },
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
                        loc.translate('find_route'),
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
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
=======
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shortest Route',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: _showRoute ? _buildMap() : _buildSearchForm(),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(10.8440, 76.2735),
            initialZoom: 14.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.yathrikan',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: AppColors.primaryYellow,
                  borderColor: Colors.black,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _routePoints.first,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location,
                      color: Colors.blue, size: 30),
                ),
                Marker(
                  point: _routePoints.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        const Text('18 min',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Distance',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        const Text('4.2 km',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showRoute = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Back to Search'),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                  ),
                ),
              ],
            ),
<<<<<<< HEAD
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
=======
          ).animate().slideY(begin: 1.0, end: 0.0),
        ),
      ],
    );
  }

  Widget _buildSearchForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildLocationInput(
                  controller: _fromController,
                  label: 'From',
                  icon: Icons.my_location,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200])),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_vert, size: 16),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200])),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLocationInput(
                  controller: _toController,
                  label: 'To',
                  icon: Icons.search,
                  hint: 'Where are you going?',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _findRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Find Route',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(),

          const SizedBox(height: 30),

          // Recent Places
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Places',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          _buildRecentPlace(
            icon: Icons.home,
            title: 'Home',
            address: '124 Main Street, Downtown',
            time: '20 min',
            delay: 300,
            onTap: () {
              _toController.text = 'Home';
              _findRoute();
            },
          ),
          _buildRecentPlace(
            icon: Icons.work,
            title: 'Office',
            address: 'Tech Park, Sector 5',
            time: '45 min',
            delay: 400,
            onTap: () {
              _toController.text = 'Office';
              _findRoute();
            },
          ),
          _buildRecentPlace(
            icon: Icons.fitness_center,
            title: 'Gym',
            address: 'FitLife Center',
            time: '15 min',
            delay: 500,
            onTap: () {
              _toController.text = 'Gym';
              _findRoute();
            },
          ),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlace({
    required IconData icon,
    required String title,
    required String address,
    required String time,
    required int delay,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: 0.05);
  }
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class ShortestRouteScreen extends StatefulWidget {
  const ShortestRouteScreen({super.key});

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
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
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              ],
            ),
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
        ],
      ),
    );
  }

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
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'route_screen.dart';
import '../utils/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeView(),
          RouteScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Theme.of(context).cardColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: loc.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              label: loc.translate('route'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: loc.translate('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  // Kerala default location
  LatLng _currentLocation = const LatLng(10.8505, 76.2711);
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  List<Marker> _busMarkers = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLiveLocationUpdates();
    _initializeBusMarkers();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check service status
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    // Check permissions
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

    // Get initial position immediately
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentLocation, 16.0);
      }
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    // Subscribe to stream for live updates
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

  void _initializeBusMarkers() {
    // Mock bus data with different routes
    final buses = [
      {'loc': const LatLng(10.8550, 76.2750), 'route': 'Kochi - Thrissur'},
      {'loc': const LatLng(10.8450, 76.2650), 'route': 'Palakkad - Kozhikode'},
      {'loc': const LatLng(10.8600, 76.2800), 'route': 'TVM - Ernakulam'},
      {'loc': const LatLng(10.8400, 76.2700), 'route': 'Alappuzha - Kannur'},
    ];

    _busMarkers = buses.map((bus) {
      return Marker(
        point: bus['loc'] as LatLng,
        width: 40,
        height: 40,
        child: Container(
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
          padding: const EdgeInsets.all(5),
          child: const Icon(
            Icons.directions_bus,
            color: AppColors.primaryYellow,
            size: 20,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(loc),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Section
                  _buildMapSection(theme),
                  const SizedBox(height: 20),

                  // Stats Row
                  _buildStatsRow(context, loc),
                  const SizedBox(height: 30),

                  // Quick Actions
                  _buildQuickActions(context, loc, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo_circle.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('app_title'),
                        style: AppTextStyles.heading2.copyWith(
                          letterSpacing: 0.5,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loc.translate('live_buses'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none,
                  size: 24, color: Colors.black),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMapSection(ThemeData theme) {
    return Container(
      height: 250, // Increased height for better visibility
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              // Normal Map Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.yathrikan',
              ),
              // Markers Layer
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
          // Recenter Button
          Positioned(
            bottom: 15,
            right: 15,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: Colors.black),
              onPressed: () {
                _startLiveLocationUpdates();
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(context, loc.translate('arriving_in'), '8 min'),
        Container(
          height: 40,
          width: 1,
          color: Colors.grey[300],
        ),
        _buildStatItem(context, loc.translate('current_speed'), '38 km/h'),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.split(' ')[0],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: value.split(' ').length > 1 ? value.split(' ')[1] : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
      BuildContext context, AppLocalizations loc, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('quick_actions'),
          style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              color: Theme.of(context).textTheme.titleLarge?.color),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.alt_route,
              label: loc.translate('shortest_route'),
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 500,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.confirmation_number_outlined,
              label: loc.translate('my_ticket'),
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 550,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.campaign_outlined,
              label: loc.translate('complaint'),
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 600,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.security,
              label: loc.translate('safety'),
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 650,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required int delay,
  }) {
    // Mapping for navigation
    final Map<String, String> routeMap = {
      'Shortest Route': '/shortest_route',
      'റൂട്ട് കണ്ടെത്തുക': '/shortest_route',
      'My Ticket': '/ticket_validation',
      'ടിക്കറ്റ്': '/ticket_validation',
      'Complaint': '/complaint',
      'പരാതി': '/complaint',
      'Safety': '/safety',
      'സുരക്ഷ': '/safety',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final routeName = routeMap[label];
          if (routeName != null) {
            Navigator.pushNamed(context, routeName);
          } else {
            if (label.contains('Route') || label.contains('റൂട്ട്')) {
              Navigator.pushNamed(context, '/shortest_route');
            } else if (label.contains('Ticket') || label.contains('ടിക്കറ്റ്'))
              Navigator.pushNamed(context, '/ticket_validation');
            else if (label.contains('Complaint') || label.contains('പരാതി'))
              Navigator.pushNamed(context, '/complaint');
            else if (label.contains('Safety') || label.contains('സുരക്ഷ'))
              Navigator.pushNamed(context, '/safety');
            else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label feature coming soon!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}

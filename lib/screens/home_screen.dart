import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'route_screen.dart';
import '../utils/app_localizations.dart';
import '../services/bus_location_service.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart'; // For SOS call
import '../models/live_bus_model.dart';
import 'shortest_route_screen.dart';

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

    // Set status bar to yellow
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

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
              label: loc['home'],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              label: loc['route'],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: loc['profile'],
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70), // Position above bottom nav
              child: FloatingActionButton.small(
                onPressed: () {
                  Navigator.pushNamed(context, '/chatbot');
                },
                backgroundColor: AppColors.primaryYellow,
                elevation: 4,
                child: const Icon(
                  Icons.smart_toy, // Chatbot icon
                  color: Colors.black,
                  size: 24,
                ),
              ),
            )
          : null,
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  // Kottayam default location
  LatLng _currentLocation = const LatLng(9.5916, 76.5222);
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  List<Marker> _busMarkers = [];
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<LiveBus>>? _busLocationStream;
  final BusLocationService _busLocationService = BusLocationService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _startLiveLocationUpdates();
    _initializeLiveBusTracking();
    
    // Listen for notification clicks
    _notificationSubscription = _notificationService.onNotificationClick.listen((payload) {
      if (payload != null && mounted) {
        // payload format: "busId|destination"  (or just "busId" for legacy)
        final parts = payload.split('|');
        final busId = parts[0];
        final destination = parts.length > 1 ? parts[1] : null;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShortestRouteScreen(
              initialBusId: busId,
              initialDestination: destination,
              autoDetectOrigin: true,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _busLocationStream?.cancel();
    _notificationSubscription?.cancel();
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
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = latLng;
          _isLoadingLocation = false;
        });
        _busLocationService.updateUserLocation(latLng);
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
          final latLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentLocation = latLng;
          });
          // Update bus service with new user location for accurate notifications
          _busLocationService.updateUserLocation(latLng);
        }
      },
      onError: (e) => debugPrint("Location Stream Error: $e"),
    );
  }

  void _initializeLiveBusTracking() {
    // Initialize the bus location service
    debugPrint('🔧 Initializing BusLocationService...');
    _busLocationService.initialize();

    // Subscribe to bus location updates
    _busLocationStream = _busLocationService.busStream.listen((buses) {
      debugPrint('📍 Received ${buses.length} buses from stream');
      if (mounted) {
        setState(() {
          _busMarkers = buses.map((bus) => _createBusMarker(bus)).toList();
          debugPrint('🗺️ Created ${_busMarkers.length} bus markers');
        });
      }
    });
  }

  Marker _createBusMarker(LiveBus bus) {
    // Determine color based on speed
    Color busColor;
    if (bus.speedKmph < 15) {
      busColor = Colors.green; // Slow (shuttles, traffic)
    } else if (bus.speedKmph < 35) {
      busColor = AppColors.primaryYellow; // Medium
    } else {
      busColor = Colors.orange; // Fast (express buses)
    }

    return Marker(
      point: LatLng(bus.lat, bus.lon),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showBusInfo(bus),
        child: Transform.rotate(
          angle: bus.headingDeg * math.pi / 180, // Rotate based on heading
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                )
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(
              Icons.directions_bus,
              color: busColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showBusInfo(LiveBus bus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: AppColors.primaryYellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bus.routeName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Speed',
                    '${bus.speedKmph.toStringAsFixed(0)} km/h',
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    'Status',
                    bus.status,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _showEmergencyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E201E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Emergency Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildEmergencyOption(ctx, Icons.local_police,     Colors.blue,           'Police Control Room', '100'),
              _buildEmergencyOption(ctx, Icons.local_fire_department, Colors.orange,    'Fire Force',         '101'),
              _buildEmergencyOption(ctx, Icons.medical_services, Colors.red,            'Ambulance',          '102'),
              const Divider(color: Colors.white24, height: 24),
              _buildEmergencyOption(ctx, Icons.woman,            Colors.pinkAccent,     'Women Helpline',     '1091'),
              _buildEmergencyOption(ctx, Icons.child_care,       Colors.lightBlueAccent,'Child Helpline',     '1098'),
              const Divider(color: Colors.white24, height: 24),
              _buildEmergencyOption(ctx, Icons.sos,              Colors.redAccent,      'General Emergency (112)', '112', isPrimary: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(
    BuildContext ctx,
    IconData icon,
    Color color,
    String title,
    String number, {
    bool isPrimary = false,
  }) {
    return ListTile(
      onTap: () {
        Navigator.pop(ctx);
        _callNumber(number);
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_circle.png',
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('app_title').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc['live_buses'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEmergencyOptions,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sos,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // Show notifications modal
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, 
                        height: 4, 
                        decoration: BoxDecoration(
                          color: Colors.grey[300], 
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              NotificationService().clearHistory();
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: StreamBuilder<List<NotificationItem>>(
                          stream: NotificationService().historyStream,
                          initialData: NotificationService().history,
                          builder: (context, snapshot) {
                            final history = snapshot.data ?? [];
                            
                            if (history.isEmpty) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 20),
                                  Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc['no_notifications'],
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: history.length,
                              itemBuilder: (context, index) {
                                final item = history[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Theme.of(context).cardColor,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryYellow.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.directions_bus, color: AppColors.primaryYellow, size: 20),
                                    ),
                                    title: Text(loc[item.title], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(loc[item.body], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                        ),
                                      ],
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
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMapSection(ThemeData theme) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.30, // 30% of screen height - fits without scroll
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  _startLiveLocationUpdates();
                },
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location,
                        color: Colors.black, size: 22),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuickActions(
      BuildContext context, AppLocalizations loc, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc['quick_actions'],
          style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              color: Theme.of(context).textTheme.titleLarge?.color),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.alt_route,
              label: loc['shortest_route'],
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 500,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.confirmation_number_outlined,
              label: loc['my_ticket'],
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 550,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.campaign_outlined,
              label: loc['complaint'],
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
              iconColor: AppColors.primaryYellow,
              delay: 600,
            ),
            _buildActionCard(
              context: context,
              icon: Icons.security,
              label: loc['safety'],
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
            } else if (label.contains('Ticket') ||
                label.contains('ടിക്കറ്റ്')) {
              Navigator.pushNamed(context, '/ticket_validation');
            } else if (label.contains('Complaint') || label.contains('പരാതി')) {
              Navigator.pushNamed(context, '/complaint');
            } else if (label.contains('Safety') || label.contains('സുരക്ഷ')) {
              Navigator.pushNamed(context, '/safety');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label feature coming soon!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
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
                  borderRadius: BorderRadius.circular(12),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

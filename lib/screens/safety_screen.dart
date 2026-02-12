import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:async';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  double _currentSpeed = 0.0; // Speed in km/h
  final double _speedLimit = 80.0; // Speed limit in km/h
  bool _isLoadingSpeed = true;
  StreamSubscription<Position>? _positionStream;

  // Dynamic Data
  String _roadCondition = "Unknown";
  String _visibilityCondition = "Unknown";
  String _nextLocation = "Calculating...";
  String _timeToNext = "-- mins";

  @override
  void initState() {
    super.initState();
    _startSpeedTracking();
    _fetchRoadAndRouteInfo();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startSpeedTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoadingSpeed = false);
      }
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoadingSpeed = false);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoadingSpeed = false);
      }
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (mounted) {
        setState(() {
          // Speed is in m/s, convert to km/h
          _currentSpeed = (position.speed * 3.6).clamp(0.0, 200.0);
          _isLoadingSpeed = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting initial position: $e");
      if (mounted) {
        setState(() => _isLoadingSpeed = false);
      }
    }

    // Subscribe to position stream for live updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            // Speed is in m/s, convert to km/h and clamp to reasonable values
            _currentSpeed = (position.speed * 3.6).clamp(0.0, 200.0);
            _isLoadingSpeed = false;
          });
        }
      },
      onError: (e) => debugPrint("Location Stream Error: $e"),
    );
  }

  // Static locations for fallback (Copied for local calculation)
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

  Future<void> _fetchRoadAndRouteInfo() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      
      // 1. Determine "Weather" (Safer default)
      // Default to Good conditions to avoid false alarms
      String roadCond = "Dry";
      String visCond = "Good visibility";

      // Simple time-based check: Night time might mean lower visibility
      final hour = DateTime.now().hour;
      if (hour < 6 || hour > 18) {
        visCond = "Moderate visibility";
      }

      // 2. Find Nearest "Next Stop"
      String nextStop = "Destination";
      double minDistance = double.infinity;
      
      _staticLocations.forEach((name, coord) {
        double distance = Geolocator.distanceBetween(
          position.latitude, 
          position.longitude, 
          coord.latitude, 
          coord.longitude
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          nextStop = name;
        }
      });

      // If nearest known stop is too far (> 10km), try to get actual locality
      if (minDistance > 10000) {
         try {
           List<Placemark> placemarks = await placemarkFromCoordinates(
             position.latitude, position.longitude
           );
           if (placemarks.isNotEmpty) {
             final place = placemarks.first;
             // Use locality or subLocality
             String localName = place.locality ?? place.subLocality ?? place.name ?? "Unknown";
             if (localName != "Unknown") {
               nextStop = "Near $localName";
               // Reset distance for display purposes (it's "near")
               minDistance = 500; 
             }
           }
         } catch (e) {
           debugPrint("Geocoding failed: $e");
           // Fallback to the nearest static stop we found earlier
         }
      }
      
      // Calculate time: Distance (m) / Speed (m/s)
      // Assume average bus speed 40 km/h (~11 m/s)
      int minutes = (minDistance / 11.11 / 60).round();
      if (minutes < 1) minutes = 1;

      if (mounted) {
        setState(() {
          _roadCondition = roadCond;
          _visibilityCondition = visCond;
          _nextLocation = nextStop;
          _timeToNext = "$minutes mins away";
        });
      }

    } catch (e) {
       debugPrint("Error fetching route info: $e");
       if (mounted) {
         setState(() {
            _roadCondition = "Dry";
            _visibilityCondition = "Good visibility";
            _nextLocation = "Searching...";
            _timeToNext = "-- mins";
         });
       }
    }
  }

  String _getSpeedStatus() {
    if (_currentSpeed < _speedLimit * 0.8) {
      return "NORMAL";
    } else if (_currentSpeed < _speedLimit) {
      return "WARNING";
    } else {
      return "DANGER";
    }
  }

  Color _getStatusColor() {
    final status = _getSpeedStatus();
    switch (status) {
      case "NORMAL":
        return Colors.yellow;
      case "WARNING":
        return Colors.orange;
      case "DANGER":
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  Future<void> _callEmergency(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
     if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialer")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E201E), // Dark background text
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Safety",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Speedometer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111418), // Darker card
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _getStatusColor().withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              _getSpeedStatus() == "NORMAL"
                                  ? Icons.check_circle
                                  : _getSpeedStatus() == "WARNING"
                                      ? Icons.warning_amber_rounded
                                      : Icons.error,
                              color: _getStatusColor(),
                              size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _getSpeedStatus(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Custom Speedometer
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: CustomPaint(
                      painter: SpeedometerPainter(
                        percentage: (_currentSpeed / 100).clamp(0.0, 1.0),
                        statusColor: _getStatusColor(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "CURRENT SPEED",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _isLoadingSpeed
                                        ? "--"
                                        : _currentSpeed.toStringAsFixed(0),
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " km/h",
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Speed Limit",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "80 km/h",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.wb_sunny_outlined,
                    label: "ROAD",
                    value: _roadCondition,
                    subValue: _visibilityCondition,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.directions_bus_outlined,
                    label: "NEXT",
                    value: _nextLocation,
                    subValue: _timeToNext,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Actions",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildActionTile(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.redAccent,
              title: "Report Issue",
              subtitle: "Reckless driving, hazards",
              onTap: () {
                // Navigate to Report
                Navigator.pushNamed(context, '/complaint');
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: CupertinoIcons.phone_fill,
              iconColor: Colors.blueAccent,
              title: "Emergency Contacts",
              subtitle: "Police, Ambulance, Fire, Helplines",
              onTap: () => _showEmergencyOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E201E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Emergency Services",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildEmergencyOption(
                icon: Icons.local_police,
                color: Colors.blue,
                title: "Police Control Room",
                number: "100",
              ),
              _buildEmergencyOption(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                title: "Fire Force",
                number: "101",
              ),
              _buildEmergencyOption(
                icon: Icons.medical_services,
                color: Colors.red,
                title: "Ambulance",
                number: "102",
              ),
              const Divider(color: Colors.white24, height: 24),
              _buildEmergencyOption(
                icon: Icons.woman,
                color: Colors.pinkAccent,
                title: "Women Helpline",
                number: "1091",
              ),
               _buildEmergencyOption(
                icon: Icons.child_care,
                color: Colors.lightBlueAccent,
                title: "Child Helpline",
                number: "1098",
              ),
              const Divider(color: Colors.white24, height: 24),
               _buildEmergencyOption(
                icon: Icons.sos,
                color: Colors.redAccent,
                title: "General Emergency (112)",
                number: "112",
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required Color color,
    required String title,
    required String number,
    bool isPrimary = false,
  }) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _callEmergency(number);
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
        style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111418), // Dark card
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111418),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double percentage;
  final Color statusColor;

  SpeedometerPainter({
    required this.percentage,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    // Background Arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20;

    // Start from -135 degrees (225 degrees total sweep)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, // Start angle (135 degrees)
      pi * 1.5, // Sweep angle (270 degrees)
      false,
      bgPaint,
    );

    // Active Arc
    final activePaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20;

    // Gradient Shader for arc (Optional, making it solid yellow as per image)
    /*
    final rect = Rect.fromCircle(center: center, radius: radius);
    activePaint.shader = SweepGradient(
      startAngle: pi * 0.75,
      endAngle: pi * 0.75 + (pi * 1.5),
      colors: [Colors.yellow.shade700, Colors.yellow],
      stops: const [0.0, 1.0],
    ).createShader(rect);
    */

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5 * percentage,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

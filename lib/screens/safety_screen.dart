import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _startSpeedTracking();
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
                    value: "Dry",
                    subValue: "Good visibility",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.directions_bus_outlined,
                    label: "NEXT",
                    value: "Central St.",
                    subValue: "12 mins away",
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
              title: "Emergency",
              subtitle: "Direct support line",
              onTap: () {},
            ),
          ],
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
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
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

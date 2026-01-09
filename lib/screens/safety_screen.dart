import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
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
=======
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E12), // Dark olive/black theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Safety',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
<<<<<<< HEAD
        padding: const EdgeInsets.all(24.0),
=======
        padding: const EdgeInsets.all(20),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        child: Column(
          children: [
            // Speedometer Card
            Container(
<<<<<<< HEAD
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111418), // Darker card
                borderRadius: BorderRadius.circular(30),
=======
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF11131E), // Dark blueish
                borderRadius: BorderRadius.circular(40),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
<<<<<<< HEAD
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
=======
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Status Badge
                  Positioned(
                    top: 20,
                    right: 20,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
<<<<<<< HEAD
                        color: Colors.yellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.yellow.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
=======
                        color: Colors.yellow
                            .withValues(alpha: 0.1), // Match design
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.yellow.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.yellow, size: 16),
                          SizedBox(width: 6),
                          Text(
<<<<<<< HEAD
                            "NORMAL",
=======
                            'NORMAL',
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                            style: TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 20),
                  // Custom Speedometer
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: CustomPaint(
                      painter: SpeedometerPainter(percentage: 0.75),
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
                                    text: "64",
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
=======

                  // Speedometer Circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 0.75, // 75% speed
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[800],
                      color: AppColors.primaryYellow,
                      strokeCap: StrokeCap.round,
                    ),
                  ),

                  // Speed Text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CURRENT SPEED',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '64',
                              style: GoogleFonts.inter(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: 'km/h',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[400],
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                              ),
                            ),
                          ],
                        ),
                      ),
<<<<<<< HEAD
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
=======
                    ],
                  ),

                  Positioned(
                    bottom: 30,
                    child: Column(
                      children: [
                        Text(
                          'Speed Limit',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '80 km/h',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                    ),
                  ),
                ],
              ),
<<<<<<< HEAD
            ),

            const SizedBox(height: 20),

=======
            ).animate().scale(),

            const SizedBox(height: 20),

            // Info Cards Row
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.wb_sunny_outlined,
<<<<<<< HEAD
                    label: "ROAD",
                    value: "Dry",
                    subValue: "Good visibility",
=======
                    label: 'ROAD',
                    value: 'Dry',
                    subValue: 'Good visibility',
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.directions_bus_outlined,
<<<<<<< HEAD
                    label: "NEXT",
                    value: "Central St.",
                    subValue: "12 mins away",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
=======
                    label: 'NEXT',
                    value: 'Central St.',
                    subValue: '12 mins away',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
<<<<<<< HEAD
                "Quick Actions",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
=======
                'Quick Actions',
                style: AppTextStyles.heading2
                    .copyWith(color: Colors.white, fontSize: 18),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
              ),
            ),
            const SizedBox(height: 16),

            _buildActionTile(
<<<<<<< HEAD
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
=======
              icon: Icons.report_problem_outlined,
              color: Colors.red[400]!,
              title: 'Report Issue',
              subtitle: 'Reckless driving, hazards',
              onTap: () {},
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.support_agent,
              color: Colors.blue[400]!,
              title: 'Emergency',
              subtitle: 'Direct support line',
              onTap: () {},
            ).animate().fadeIn(delay: 400.ms),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
        color: const Color(0xFF111418), // Dark card
=======
        color: const Color(0xFF11131E),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
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
=======
          Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
<<<<<<< HEAD
              fontSize: 18,
=======
              fontSize: 20,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
<<<<<<< HEAD
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
=======
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
<<<<<<< HEAD
    required Color iconColor,
=======
    required Color color,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
<<<<<<< HEAD
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
=======
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF11131E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: onTap,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
      ),
    );
  }
}
<<<<<<< HEAD

class SpeedometerPainter extends CustomPainter {
  final double percentage;

  SpeedometerPainter({required this.percentage});

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
      ..color = Colors.yellow
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
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

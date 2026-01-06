import 'package:flutter/material.dart';
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
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Speedometer Card
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF11131E), // Dark blueish
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Status Badge
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.yellow
                            .withValues(alpha: 0.1), // Match design
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.yellow.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.yellow, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'NORMAL',
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
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    ),
                  ),
                ],
              ),
            ).animate().scale(),

            const SizedBox(height: 20),

            // Info Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.wb_sunny_outlined,
                    label: 'ROAD',
                    value: 'Dry',
                    subValue: 'Good visibility',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.directions_bus_outlined,
                    label: 'NEXT',
                    value: 'Central St.',
                    subValue: '12 mins away',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Actions',
                style: AppTextStyles.heading2
                    .copyWith(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),

            _buildActionTile(
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
        color: const Color(0xFF11131E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
      ),
    );
  }
}

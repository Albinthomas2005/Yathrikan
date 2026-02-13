
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Analytics', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartSection('Revenue Trend', const [40, 65, 55, 80, 70, 90, 85], Colors.greenAccent),
            const SizedBox(height: 20),
            _buildChartSection('Passenger Volume', const [30, 45, 40, 60, 50, 75, 70], Colors.blueAccent),
            const SizedBox(height: 20),
            _buildStatGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, List<double> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: ChartPainter(data: data, color: color),
              child: Container(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Avg. Ticket', '₹42.50', Colors.orange),
        _buildStatCard('Occupancy', '78%', Colors.purple),
        _buildStatCard('Peak Hour', '09:00 AM', Colors.redAccent),
        _buildStatCard('Online Bookings', '65%', Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().scale();
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  ChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final spacing = size.width / (data.length - 1);
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < data.length; i++) {
      final x = i * spacing;
      final y = size.height - (data[i] / maxVal * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.cubicTo(
          x - spacing / 2, size.height - (data[i - 1] / maxVal * size.height), // Control point 1
          x - spacing / 2, y, // Control point 2
          x, y
        );
      }
    }

    canvas.drawPath(path, paint);
    
    // Fill gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final gradient = LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

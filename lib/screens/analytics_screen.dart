import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class AnalyticsDataPoint {
  final String date;
  final int passengers;
  final double revenue;
  final String? route;

  const AnalyticsDataPoint({
    required this.date,
    required this.passengers,
    required this.revenue,
    this.route,
  });
}

// ── Sample weekly data ────────────────────────────────────────────────────────
const _weeklyData = [
  AnalyticsDataPoint(date: 'Mar 9',  passengers: 94,  revenue: 3290, route: 'Erumely – Kottayam'),
  AnalyticsDataPoint(date: 'Mar 10', passengers: 128, revenue: 4350, route: 'Kottayam – Erumely'),
  AnalyticsDataPoint(date: 'Mar 11', passengers: 110, revenue: 3810, route: 'Erumely – Kottayam'),
  AnalyticsDataPoint(date: 'Mar 12', passengers: 162, revenue: 5640, route: 'Kottayam – Pala'),
  AnalyticsDataPoint(date: 'Mar 13', passengers: 138, revenue: 4860, route: 'Erumely – Kottayam'),
  AnalyticsDataPoint(date: 'Mar 14', passengers: 187, revenue: 6530, route: 'Kottayam – Erumely'),
  AnalyticsDataPoint(date: 'Mar 15', passengers: 174, revenue: 6090, route: 'Erumely – Kottayam'),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Independently selected index per chart (-1 = nothing selected)
  int _revenueSelected    = -1;
  int _passengerSelected  = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            _buildChartSection(
              title: 'Revenue Trend',
              values: _weeklyData.map((d) => d.revenue).toList(),
              color: Colors.greenAccent,
              selectedIndex: _revenueSelected,
              onTap: (i) => setState(() =>
                  _revenueSelected = (_revenueSelected == i) ? -1 : i),
            ),
            const SizedBox(height: 8),
            _buildDetailPanel(_revenueSelected, Colors.greenAccent),
            const SizedBox(height: 20),

            _buildChartSection(
              title: 'Passenger Volume',
              values: _weeklyData.map((d) => d.passengers.toDouble()).toList(),
              color: Colors.blueAccent,
              selectedIndex: _passengerSelected,
              onTap: (i) => setState(() =>
                  _passengerSelected = (_passengerSelected == i) ? -1 : i),
            ),
            const SizedBox(height: 8),
            _buildDetailPanel(_passengerSelected, Colors.blueAccent),
            const SizedBox(height: 20),

            _buildStatGrid(),
          ],
        ),
      ),
    );
  }

  // ── Chart card ──────────────────────────────────────────────────────────────
  Widget _buildChartSection({
    required String title,
    required List<double> values,
    required Color color,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              if (selectedIndex != -1)
                Text(
                  _weeklyData[selectedIndex].date,
                  style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any point for details',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return GestureDetector(
                onTapDown: (details) {
                  final dx = details.localPosition.dx;
                  final spacing = w / (values.length - 1);
                  // Nearest point by X
                  int nearest = 0;
                  double minDist = double.infinity;
                  for (int i = 0; i < values.length; i++) {
                    final dist = (i * spacing - dx).abs();
                    if (dist < minDist) { minDist = dist; nearest = i; }
                  }
                  onTap(nearest);
                },
                child: CustomPaint(
                  painter: ChartPainter(
                    data: values,
                    color: color,
                    selectedIndex: selectedIndex,
                  ),
                  size: Size(w, h),
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ── Animated detail panel ───────────────────────────────────────────────────
  Widget _buildDetailPanel(int selectedIndex, Color accentColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: selectedIndex == -1
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : _DetailCard(
              key: ValueKey(selectedIndex),
              point: _weeklyData[selectedIndex],
              accentColor: accentColor,
            ),
    );
  }

  // ── Stat grid ───────────────────────────────────────────────────────────────
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

// ── Detail card widget ────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final AnalyticsDataPoint point;
  final Color accentColor;

  const _DetailCard({super.key, required this.point, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Data Point Details',
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.calendar_today_rounded, 'Date', point.date, Colors.white70),
          const SizedBox(height: 8),
          _row(Icons.people_alt_rounded, 'Passengers', '${point.passengers}', Colors.blueAccent),
          const SizedBox(height: 8),
          _row(Icons.currency_rupee_rounded, 'Revenue', '₹${point.revenue.toStringAsFixed(0)}', Colors.greenAccent),
          if (point.route != null) ...[
            const SizedBox(height: 8),
            _row(Icons.directions_bus_rounded, 'Route', point.route!, Colors.purpleAccent),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white30),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Chart painter ─────────────────────────────────────────────────────────────
class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final int selectedIndex;

  ChartPainter({required this.data, required this.color, this.selectedIndex = -1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / (data.length - 1);
    final maxVal  = data.reduce((a, b) => a > b ? a : b);

    // Helper: get Y for index
    double yFor(int i) => size.height - (data[i] / maxVal * size.height * 0.88) - size.height * 0.04;

    // ── Curve path ──────────────────────────────────────────────────────────
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * spacing;
      final y = yFor(i);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.cubicTo(
          (i - 1) * spacing + spacing / 2, yFor(i - 1),
          x - spacing / 2, y,
          x, y,
        );
      }
    }
    canvas.drawPath(path, paint);

    // ── Gradient fill ────────────────────────────────────────────────────────
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ── Data point dots ───────────────────────────────────────────────────────
    for (int i = 0; i < data.length; i++) {
      final x = i * spacing;
      final y = yFor(i);
      final isSelected = i == selectedIndex;

      if (isSelected) {
        // Outer glow ring
        canvas.drawCircle(
          Offset(x, y),
          10,
          Paint()..color = color.withValues(alpha: 0.2),
        );
        // White ring
        canvas.drawCircle(
          Offset(x, y),
          7,
          Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
        );
        // Filled dot
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()..color = color,
        );
      } else {
        // Small unselected dot
        canvas.drawCircle(
          Offset(x, y),
          3.5,
          Paint()..color = color.withValues(alpha: 0.7),
        );
        // Tiny white centre
        canvas.drawCircle(
          Offset(x, y),
          1.5,
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ChartPainter old) =>
      old.selectedIndex != selectedIndex || old.data != data || old.color != color;
}

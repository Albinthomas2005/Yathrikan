import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/bus_location_service.dart';
import '../services/support_ticket_service.dart';
import 'admin_routes_screen.dart';
import 'analytics_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.dashboard,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Admin Overview',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'HEALTHY',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 24),

                // Metrics Grid
                // Metrics Grid
                Builder(
                  builder: (context) {
                    final allBuses = BusLocationService().allLiveBuses;
                    final activeBuses = allBuses.where((b) => b.status == 'RUNNING').length;
                    
                    // Dynamic calculations based on active fleet
                    final livePax = activeBuses * 29;
                    final revenue = activeBuses * 4250.0; 
                    final pending = (activeBuses * 0.05).ceil();

                    // Simple number formatting
                    String formatNumber(int n) {
                      return n.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                        (Match m) => '${m[1]},'
                      );
                    }

                    String formatMoney(double n) {
                      if (n >= 10000000) {
                        return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
                      } else if (n >= 100000) {
                        return '₹${(n / 100000).toStringAsFixed(2)}L';
                      } else if (n >= 1000) {
                        return '₹${(n / 1000).toStringAsFixed(1)}k';
                      }
                      return '₹${n.toStringAsFixed(0)}';
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _MetricCard(
                          icon: Icons.directions_bus,
                          iconColor: AppColors.primaryYellow,
                          containerColor: const Color(0xFF6B5829),
                          title: 'ACTIVE BUSES',
                          value: '$activeBuses',
                          change: '+5%',
                          isPositive: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRoutesScreen())),
                        ),
                        _MetricCard(
                          icon: Icons.people,
                          iconColor: const Color(0xFF60A5FA),
                          containerColor: const Color(0xFF294168),
                          title: 'LIVE PAX',
                          value: formatNumber(livePax),
                          change: '+12%',
                          isPositive: true,
                          onTap: () => _showPaxDetails(livePax),
                        ),
                        _MetricCard(
                          icon: Icons.attach_money,
                          iconColor: const Color(0xFF34D399),
                          containerColor: const Color(0xFF1F4D44),
                          title: 'REVENUE',
                          value: formatMoney(revenue),
                          change: '+8%',
                          isPositive: true,
                          onTap: () => _showRevenueDetails(revenue),
                        ),
                        _MetricCard(
                          icon: Icons.more_horiz,
                          iconColor: const Color(0xFFF97316),
                          containerColor: const Color(0xFF633D29),
                          title: 'PENDING',
                          value: '$pending',
                          change: '-2%',
                          isPositive: false,
                          onTap: () => _showPendingDetails(pending),
                        ),
                      ],
                    );
                  },
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 28),

                // Provider Performance
                Text(
                  'Provider Performance',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOP PERFORMER',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'KSRTC vs Private',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Color(0xFF0F172A),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KSRTC',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Private',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 12,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 62,
                                child: Container(
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                              Expanded(
                                flex: 38,
                                child: Container(
                                  color: const Color(0xFF60A5FA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '62% Market Share',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            '38% Market Share',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'View Analytics',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),


                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 400.ms),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: [
                    _QuickActionButton(
                      icon: Icons.directions_bus,
                      label: 'All\nBuses',
                      iconColor: AppColors.primaryYellow,
                      onTap: () {
                        Navigator.pushNamed(context, '/admin-routes');
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.location_on,
                      label: 'Fleet\nTrack',
                      iconColor: AppColors.primaryYellow,
                      onTap: () {
                        Navigator.pushNamed(context, '/full_map');
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.support_agent,
                      label: 'User\nSupport',
                      iconColor: AppColors.primaryYellow,
                      onTap: () {
                        Navigator.pushNamed(context, '/admin-support');
                      },
                    ),

                    _QuickActionButton(
                      icon: Icons.trending_up,
                      label: 'Finance',
                      iconColor: AppColors.primaryYellow,
                      onTap: () {
                        Navigator.pushNamed(context, '/admin-finance');
                      },
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 28),

                // Recent Complaints
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Complaints',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin-support');
                      },
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 850.ms, duration: 400.ms),
                const SizedBox(height: 12),
                
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupportTicketService().pendingStream,
                  initialData: SupportTicketService().pendingTickets,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: Text(
                          'No active complaints.',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        ),
                      ).animate().fadeIn(delay: 900.ms);
                    }

                    // Show top 3 most recent
                    final displayTickets = tickets.take(3).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayTickets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = displayTickets[index];
                        final priorityColor = _getPriorityColor(ticket['priority'] as String);
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showTicketDetails(ticket),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(
                                    color: priorityColor,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getPriorityIcon(ticket['priority'] as String),
                                      color: priorityColor,
                                      size: 20,
                                    ),
                                  ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket['title'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ticket['category']} • ${ticket['userName']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white24,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (900 + (index * 50)).ms).slideX(begin: -0.1, end: 0);
                  },
                    );
                  },
                ),
                
                const SizedBox(height: 28),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showPaxDetails(int livePax) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger Details', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Total Live Pax', '$livePax'),
            _detailRow('Occupancy Rate', '78%'),
            _detailRow('Peak Route', 'Kottayam - Aluva'),
          ],
        ),
      ),
    );
  }

  void _showRevenueDetails(double revenue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue Breakdown', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Total Revenue', '₹${revenue.toStringAsFixed(0)}'),
            _detailRow('Online Bookings', '65%'),
            _detailRow('Cash Collection', '35%'),
          ],
        ),
      ),
    );
  }

  void _showPendingDetails(int pending) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pending Actions', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Pending Approvals', '$pending'),
            _detailRow('Maintenance Requests', '2'),
            _detailRow('Driver Reports', '5'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white70)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Area
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(ticket['priority'] as String).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPriorityIcon(ticket['priority'] as String),
                        color: _getPriorityColor(ticket['priority'] as String),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket['title'] as String,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                ticket['id'] as String,
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(ticket['priority'] as String).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getPriorityColor(ticket['priority'] as String).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  ticket['priority'] as String,
                                  style: GoogleFonts.inter(
                                    color: _getPriorityColor(ticket['priority'] as String),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white12, height: 1),
              
              // Content Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ticket['busId'] != null && ticket['busId'].toString().isNotEmpty) ...[
                      Text(
                        'Bus Involved',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus, color: AppColors.primaryYellow, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ticket['busId'] as String,
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryYellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Text(
                      'Description',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        ticket['description'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    if (ticket['evidence'] != null && (ticket['evidence'] as List).isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Attached Evidence',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: (ticket['evidence'] as List).length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final file = (ticket['evidence'] as List)[index];
                            final path = file['path'] as String;
                            final isVideo = file['type'] == 'video';
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                                image: isVideo
                                    ? null
                                    : DecorationImage(
                                        image: FileImage(File(path)),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) => {},
                                      ),
                              ),
                              child: isVideo
                                  ? const Center(
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                    
                    if (ticket['userName'] != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Reported By',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryYellow.withOpacity(0.2),
                            child: const Icon(Icons.person, color: AppColors.primaryYellow, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ticket['userName'] as String,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'User (App)',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const Divider(color: Colors.white12, height: 1),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!SupportTicketService().resolvedTickets.any((t) => t['id'] == ticket['id']))
                      ElevatedButton(
                        onPressed: () {
                          SupportTicketService().resolveTicket(ticket['id'] as String);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ticket status updated to Resolved'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Resolve',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF97316);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'HIGH':
        return Icons.warning_rounded;
      case 'MEDIUM':
        return Icons.info_outline;
      case 'LOW':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }
}


class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20, // Reduced from 24
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, // Reduced from 10
                      vertical: 4, // Reduced from 6
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3846),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      change,
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reduced from 12
                        fontWeight: FontWeight.w600,
                        color: isPositive ? const Color(0xFF34D399) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11, // Reduced from 12
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20, // Reduced from 24
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

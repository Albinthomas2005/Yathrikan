import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/support_ticket_service.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupportTicketService _ticketService = SupportTicketService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    if (!_ticketService.resolvedTickets.any((t) => t['id'] == ticket['id']))
                      ElevatedButton(
                        onPressed: () {
                          _ticketService.resolveTicket(ticket['id'] as String);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Support',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK ACTIONS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionItem(
                      icon: Icons.route,
                      label: 'Manage\nRoutes',
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin-routes'),
                    ),
                    _QuickActionItem(
                      icon: Icons.location_on,
                      label: 'Fleet\nTrack',
                      onTap: () => Navigator.pushNamed(context, '/full_map'),
                    ),
                    _QuickActionItem(
                      icon: Icons.support_agent,
                      label: 'User\nSupport',
                      isActive: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You are already on User Support')),
                        );
                      },
                    ),
                    _QuickActionItem(
                      icon: Icons.trending_up,
                      label: 'Finance',
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin-finance'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: const Color(0xFF0F172A),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryYellow,
                indicatorWeight: 3,
                labelColor: AppColors.primaryYellow,
                unselectedLabelColor: Colors.white54,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _ticketService.pendingStream,
                    initialData: _ticketService.pendingTickets,
                    builder: (context, snapshot) => Tab(text: 'Pending (${snapshot.data?.length ?? 0})'),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _ticketService.inProgressStream,
                    initialData: _ticketService.inProgressTickets,
                    builder: (context, snapshot) => Tab(text: 'In Progress (${snapshot.data?.length ?? 0})'),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _ticketService.resolvedStream,
                    initialData: _ticketService.resolvedTickets,
                    builder: (context, snapshot) => Tab(text: 'Resolved (${snapshot.data?.length ?? 0})'),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Tab
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _ticketService.pendingStream,
                  initialData: _ticketService.pendingTickets,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) return Center(child: Text('No pending tickets', style: GoogleFonts.inter(color: Colors.white54)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        return _TicketCard(
                          ticket: tickets[index],
                          onTap: () => _showTicketDetails(tickets[index]),
                        );
                      },
                    );
                  },
                ),
                // In Progress Tab
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _ticketService.inProgressStream,
                  initialData: _ticketService.inProgressTickets,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) return Center(child: Text('No tickets in progress', style: GoogleFonts.inter(color: Colors.white54)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        return _TicketCard(
                          ticket: tickets[index],
                          onTap: () => _showTicketDetails(tickets[index]),
                        );
                      },
                    );
                  },
                ),
                // Resolved Tab
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _ticketService.resolvedStream,
                  initialData: _ticketService.resolvedTickets,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) return Center(child: Text('0 resolved tickets', style: GoogleFonts.inter(color: Colors.white54)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        return _TicketCard(
                          ticket: tickets[index],
                          onTap: () => _showTicketDetails(tickets[index]),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryYellow
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? const Color(0xFF0F172A)
                    : AppColors.primaryYellow,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primaryYellow : Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final priority = ticket['priority'] as String;
    final userName = ticket['userName'] as String?;
    final upvotes = ticket['upvotes'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket['id'],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(priority),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            ticket['title'],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            ticket['description'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Info or Upvotes
              if (userName != null)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                )
              else if (upvotes != null)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$upvotes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),

              // Open Ticket Button
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open Ticket',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data - replace with real Firestore data later
  final List<Map<String, dynamic>> _routes = [
    {
      'id': '1',
      'routeName': 'Kottayam → Pala',
      'stops': 12,
      'distance': 28.5,
      'isActive': true,
      'lastUpdated': '2 hrs ago',
      'busesOnline': 4,
    },
    {
      'id': '2',
      'routeName': 'Kochi → Aluva',
      'stops': 8,
      'distance': 14.2,
      'isActive': true,
      'lastUpdated': 'Today, 08:30 AM',
      'busesOnline': 2,
    },
    {
      'id': '3',
      'routeName': 'Thrissur → Palakkad',
      'stops': 15,
      'distance': 67.0,
      'isActive': false,
      'lastUpdated': 'Oct 24',
      'busesOnline': 0,
      'maintenanceScheduled': 'Maintenance Scheduled: Oct 24',
    },
    {
      'id': '4',
      'routeName': 'Idukki → Munnar',
      'stops': 22,
      'distance': 45.1,
      'isActive': true,
      'lastUpdated': 'Yesterday',
      'busesOnline': 1,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRoutes {
    if (_searchQuery.isEmpty) return _routes;
    return _routes
        .where((route) => route['routeName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
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
          'Manage Routes',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search routes, stops or IDs...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Routes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredRoutes.length,
              itemBuilder: (context, index) {
                final route = _filteredRoutes[index];
                return _RouteCard(route: route);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new route
        },
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final bool isActive = route['isActive'] as bool;
    final int busesOnline = route['busesOnline'] as int;

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
              Expanded(
                child: Text(
                  route['routeName'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.white70,
                onPressed: () {
                  // TODO: Edit route
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stops and Distance
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                '${route['stops']} Stops',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.straighten,
                size: 16,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                '${route['distance']} km',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last Updated and Buses Online / Maintenance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: ${route['lastUpdated']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
              if (isActive)
                Text(
                  '$busesOnline Bus${busesOnline != 1 ? 'es' : ''} Online',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryYellow,
                  ),
                )
              else
                Text(
                  'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),

          // Maintenance info for inactive routes
          if (!isActive && route['maintenanceScheduled'] != null) ...[
            const SizedBox(height: 8),
            Text(
              route['maintenanceScheduled'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

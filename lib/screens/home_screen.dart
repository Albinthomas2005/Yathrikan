import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'route_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Route',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Yellow Header
          Container(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_circle.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yathrikan',
                          style: AppTextStyles.heading2,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Live buses near you',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter:
                            LatLng(10.8505, 76.2711), // Kerala, India
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.busway',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Arriving in', '8 min'),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildStatItem('Current Speed', '38 km/h'),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 30),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildActionCard(
                        context: context,
                        icon: Icons.alt_route,
                        label: 'Shortest Route',
                        color: const Color(0xFF1E1E1E),
                        iconColor: AppColors.primaryYellow,
                        delay: 500,
                        onTap: () =>
                            Navigator.pushNamed(context, '/shortest_route'),
                      ),
                      _buildActionCard(
                        context: context,
                        icon: Icons.confirmation_number_outlined,
                        label: 'My Ticket',
                        color: const Color(0xFF1E1E1E),
                        iconColor: AppColors.primaryYellow,
                        delay: 550,
                        onTap: () =>
                            Navigator.pushNamed(context, '/ticket_validation'),
                      ),
                      _buildActionCard(
                        context: context,
                        icon: Icons.campaign_outlined,
                        label: 'Complaint',
                        color: const Color(0xFF1E1E1E),
                        iconColor: AppColors.primaryYellow,
                        delay: 600,
                        onTap: () => Navigator.pushNamed(context, '/complaint'),
                      ),
                      _buildActionCard(
                        context: context,
                        icon: Icons.security,
                        label: 'Safety',
                        color: const Color(0xFF1E1E1E),
                        iconColor: AppColors.primaryYellow,
                        delay: 650,
                        onTap: () => Navigator.pushNamed(context, '/safety'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.split(' ')[0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: value.split(' ').length > 1 ? value.split(' ')[1] : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
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
                  shape: BoxShape.circle,
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

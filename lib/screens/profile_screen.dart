import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Profile',
                style: AppTextStyles.heading1.copyWith(fontSize: 32),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 30),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: AppColors.primaryYellow,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'user@example.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 30),

              // Menu Items
              _buildMenuItem(
                icon: CupertinoIcons.person,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.pushNamed(context, '/edit_profile');
                },
                delay: 300,
              ),
              _buildMenuItem(
                icon: CupertinoIcons.bell,
                title: 'Notifications',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon!')),
                  );
                },
                delay: 350,
              ),
              _buildMenuItem(
                icon: CupertinoIcons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                delay: 400,
              ),
              _buildMenuItem(
                icon: CupertinoIcons.question_circle,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Help & Support coming soon!')),
                  );
                },
                delay: 450,
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.arrow_right_square, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.95, 0.95)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideX(begin: 0.2, end: 0);
  }
}

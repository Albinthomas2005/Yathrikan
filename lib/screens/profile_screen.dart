import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
<<<<<<< HEAD
import '../utils/app_localizations.dart';
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

<<<<<<< HEAD
  Future<void> _handleLogout(BuildContext context, AppLocalizations loc) async {
    // Show confirmation
    bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(loc.translate('logout')),
              content: Text(loc.translate('logout_confirm')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.translate('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.translate('logout'),
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ));

    if (confirm != true) return;

=======
  Future<void> _handleLogout(BuildContext context) async {
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
=======

    return Scaffold(
      backgroundColor: Colors.white,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
<<<<<<< HEAD
                loc.translate('profile'),
                style: AppTextStyles.heading1.copyWith(
                    fontSize: 32, color: theme.textTheme.titleLarge?.color),
=======
                'Profile',
                style: AppTextStyles.heading1.copyWith(fontSize: 32),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                      color: Colors.black.withValues(alpha: 0.1),
=======
                      color: Colors.grey.withValues(alpha: 0.2),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                context: context,
                icon: CupertinoIcons.person,
                title: loc.translate('edit_profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/edit-profile');
=======
                icon: CupertinoIcons.person,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.pushNamed(context, '/edit_profile');
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                },
                delay: 300,
              ),
              _buildMenuItem(
<<<<<<< HEAD
                context: context,
                icon: CupertinoIcons.bell,
                title: loc.translate('notifications'),
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
=======
                icon: CupertinoIcons.bell,
                title: 'Notifications',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon!')),
                  );
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                },
                delay: 350,
              ),
              _buildMenuItem(
<<<<<<< HEAD
                context: context,
                icon: CupertinoIcons.settings,
                title: loc.translate('settings'),
=======
                icon: CupertinoIcons.settings,
                title: 'Settings',
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                delay: 400,
              ),
              _buildMenuItem(
<<<<<<< HEAD
                context: context,
                icon: CupertinoIcons.question_circle,
                title: loc.translate('help_support'),
                onTap: () {
                  Navigator.pushNamed(context, '/help');
=======
                icon: CupertinoIcons.question_circle,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Help & Support coming soon!')),
                  );
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                },
                delay: 450,
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
<<<<<<< HEAD
                  onPressed: () => _handleLogout(context, loc),
=======
                  onPressed: () => _handleLogout(context),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
<<<<<<< HEAD
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_right_square, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('logout'),
                        style: const TextStyle(
=======
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.arrow_right_square, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
    required BuildContext context,
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
=======
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
=======
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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

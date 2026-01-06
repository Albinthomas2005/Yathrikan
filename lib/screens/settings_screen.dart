import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading2),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Settings',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            _buildSwitchTile(
              title: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSwitchTile(
              title: 'Dark Mode',
              value: _darkModeEnabled,
              onChanged: (val) => setState(() => _darkModeEnabled = val),
            ),
            const SizedBox(height: 20),
            const Text('Support',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            _buildOptionTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
            _buildOptionTile(
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            _buildOptionTile(
              title: 'About App',
              icon: Icons.info_outline,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Yathrikan',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Yathrikan',
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Log Out',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      {required String title,
      required bool value,
      required Function(bool) onChanged}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: CupertinoSwitch(
        value: value,
        activeColor: AppColors.primaryYellow,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildOptionTile(
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

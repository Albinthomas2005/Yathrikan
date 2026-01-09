<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/settings_provider.dart';
import '../utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.translate('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final isDark = settings.themeMode == ThemeMode.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSwitchItem(
                  context,
                  loc.translate('notifications'),
                  loc.translate('receive_updates'),
                  true,
                  (val) {
                    // Placeholder for notification logic
                  },
                ),
                _buildSwitchItem(
                  context,
                  loc.translate('dark_mode'),
                  loc.translate('enable_dark_theme'),
                  isDark,
                  (val) {
                    settings.toggleTheme(val);
                  },
                ),
                _buildSwitchItem(
                  context,
                  loc.translate('location_access'),
                  loc.translate('allow_location'),
                  settings.isLocationEnabled,
                  (val) {
                    settings.toggleLocation(val);
                  },
                ),
                const Divider(height: 40),
                _buildActionItem(
                  context,
                  loc.translate('language'),
                  settings.locale.languageCode == 'ml' ? 'മലയാളം' : 'English',
                  () => _showLanguageDialog(context, settings),
                ),
                _buildActionItem(
                    context, loc.translate('privacy_policy'), "", () {}),
                _buildActionItem(
                    context, loc.translate('terms_of_service'), "", () {}),
                _buildActionItem(context, loc.translate('about_app'),
                    "Version 1.0.0", () {}),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, String title, String subtitle,
      bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color)),
                Text(subtitle,
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color, fontSize: 12)),
              ],
            ),
          ),
          CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.primaryYellow,
              onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, String title, String trailing, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color)),
            Row(
              children: [
                Text(trailing,
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color, fontSize: 14)),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: Colors.grey),
              ],
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  trailing: settings.locale.languageCode == 'en'
                      ? const Icon(Icons.check, color: AppColors.primaryYellow)
                      : null,
                  onTap: () {
                    settings.setLanguage('en');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('മലയാളം'),
                  trailing: settings.locale.languageCode == 'ml'
                      ? const Icon(Icons.check, color: AppColors.primaryYellow)
                      : null,
                  onTap: () {
                    settings.setLanguage('ml');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        });
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
  }
}

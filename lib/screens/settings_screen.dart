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
                  context,
                  'Accessibility & Voice',
                  '',
                  () {
                    Navigator.pushNamed(context, '/accessibility-voice');
                  },
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
            ),
          ],
        ),
      ),
    );
  }

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
  }
}

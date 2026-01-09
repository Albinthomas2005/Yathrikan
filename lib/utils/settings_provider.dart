import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _isLocationEnabled = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isLocationEnabled => _isLocationEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final langCode = prefs.getString('languageCode') ?? 'en';

    // Check actual permission status, not just pref
    final permission = await Geolocator.checkPermission();
    final isPermitted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    _isLocationEnabled = isPermitted;
    // We update _isLocationEnabled based on actual system permission,
    // but we can also store a preference user intetion if needed.
    // For now, syncing with system permission is safer.

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
  }

  Future<void> toggleLocation(bool value) async {
    if (value) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _isLocationEnabled = true;
      } else {
        _isLocationEnabled = false;
        await Geolocator.openAppSettings();
      }
    } else {
      // Cannot revoke permission programmatically on all OS, but we can direct to settings
      // or just ignore location updates in app.
      // For better UX, we'll open settings if they try to turn it off,
      // or just update our local state to stop fetching.
      _isLocationEnabled = false;
      await Geolocator.openAppSettings();
    }
    notifyListeners();
  }

  // Method to re-check permission (e.g. when returning from settings)
  Future<void> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    _isLocationEnabled = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    notifyListeners();
  }
}

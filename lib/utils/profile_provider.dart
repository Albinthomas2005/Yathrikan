import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  String? _profilePicturePath;

  String? get profilePicturePath => _profilePicturePath;

  ProfileProvider() {
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    _profilePicturePath = prefs.getString('profilePicturePath');
    notifyListeners();
  }

  Future<void> setProfilePicture(String path) async {
    _profilePicturePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePicturePath', path);
  }

  Future<void> clearProfilePicture() async {
    _profilePicturePath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profilePicturePath');
  }
}

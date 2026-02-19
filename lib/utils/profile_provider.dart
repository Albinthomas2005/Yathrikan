import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  String? _profilePicturePath;

  String? get profilePicturePath => _profilePicturePath;

  ProfileProvider() {
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    _profilePicturePath = prefs.getString('profile_picture_path');
    notifyListeners();
  }

  Future<void> updateProfilePicture(String path) async {
    _profilePicturePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture_path', path);
  }

  // Alias for compatibility
  void setProfilePicture(String path) => updateProfilePicture(path);
}

import 'package:flutter/foundation.dart';

class ProfileProvider with ChangeNotifier {
  String? _profilePicturePath;

  String? get profilePicturePath => _profilePicturePath;

  void updateProfilePicture(String path) {
    _profilePicturePath = path;
    notifyListeners();
  }

  // Alias for compatibility
  void setProfilePicture(String path) => updateProfilePicture(path);
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if a user email is an admin
  Future<bool> isAdmin(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      print('DEBUG AdminService: Checking email: $normalizedEmail');

      // Query the admins collection to check if this email exists
      final adminDoc =
          await _firestore.collection('admins').doc(normalizedEmail).get();

      print('DEBUG AdminService: Document exists: ${adminDoc.exists}');
      if (adminDoc.exists) {
        print('DEBUG AdminService: Document data: ${adminDoc.data()}');
      }

      return adminDoc.exists;
    } catch (e) {
      // If there's an error, default to not admin
      print('DEBUG AdminService: Error checking admin: $e');
      return false;
    }
  }

  // Add an admin email to Firestore (you can call this once to set up your admin)
  Future<void> addAdmin(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _firestore.collection('admins').doc(normalizedEmail).set({
        'email': normalizedEmail,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add admin: $e');
    }
  }

  // Remove an admin email from Firestore
  Future<void> removeAdmin(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _firestore.collection('admins').doc(normalizedEmail).delete();
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }

  // Get all admin emails
  Future<List<String>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }
}

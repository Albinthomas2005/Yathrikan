import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/admin_service.dart';

/// One-time setup function to add your admin email
/// Call this once from anywhere in your app, then remove it
Future<void> setupInitialAdmin(BuildContext context) async {
  try {
    final adminService = AdminService();

    // Add your admin email
    await adminService.addAdmin('albinthomastkh2005@gmail.com');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin email added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    debugPrint('✅ Admin setup complete!');
    debugPrint('Admin email: albinthomastkh2005@gmail.com');
    debugPrint('You can now remove this function and file.');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint('❌ Error setting up admin: $e');
  }
}

/// Alternative: Run this as a standalone function without context
Future<void> setupInitialAdminStandalone() async {
  try {
    await Firebase.initializeApp();
    final adminService = AdminService();

    // Add your admin email
    await adminService.addAdmin('albinthomastkh2005@gmail.com');

    debugPrint('✅ Admin setup complete!');
    debugPrint('Admin email: albinthomastkh2005@gmail.com');
    debugPrint('You can now remove this function and file.');
  } catch (e) {
    debugPrint('❌ Error setting up admin: $e');
  }
}

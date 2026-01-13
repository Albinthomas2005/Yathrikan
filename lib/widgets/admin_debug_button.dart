import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Add this button TEMPORARILY to any screen to test and add admin
class AdminDebugButton extends StatefulWidget {
  const AdminDebugButton({super.key});

  @override
  State<AdminDebugButton> createState() => _AdminDebugButtonState();
}

class _AdminDebugButtonState extends State<AdminDebugButton> {
  String _message = '';
  final AdminService _adminService = AdminService();

  Future<void> _testAndAddAdmin() async {
    setState(() => _message = 'Checking...');

    try {
      // Check current status
      final isAdmin =
          await _adminService.isAdmin('albinthomastkh2005@gmail.com');
      print('Current admin status: $isAdmin');

      if (!isAdmin) {
        // Add the admin
        setState(() => _message = 'Adding admin email...');
        await _adminService.addAdmin('albinthomastkh2005@gmail.com');

        // Verify it was added
        final checkAgain =
            await _adminService.isAdmin('albinthomastkh2005@gmail.com');
        setState(() => _message = checkAgain
            ? '✅ Admin added! Email: albinthomastkh2005@gmail.com\nNow logout and login again!'
            : '❌ Failed to add admin');
      } else {
        setState(() => _message =
            '✅ Email already an admin!\nalbinthomastkh2005@gmail.com');
      }

      // List all admins
      final allAdmins = await _adminService.getAllAdmins();
      print('All admins: $allAdmins');
      setState(
          () => _message += '\n\nAll admins in DB:\n${allAdmins.join('\n')}');
    } catch (e) {
      setState(() => _message = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _testAndAddAdmin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('🔧 DEBUG: Test & Add Admin Email'),
        ),
        if (_message.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(
              _message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }
}

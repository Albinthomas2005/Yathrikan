// ONE-TIME SCRIPT - RUN ONCE THEN DELETE THIS FILE
// This will add your admin email to Firestore

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/admin_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AddAdminApp());
}

class AddAdminApp extends StatelessWidget {
  const AddAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AddAdminScreen(),
    );
  }
}

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  String _status = 'Ready to add admin email...';
  bool _isLoading = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    // Auto-run on start
    _addAdminEmail();
  }

  Future<void> _addAdminEmail() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding albinthomastkh2005@gmail.com to Firestore...';
    });

    try {
      final adminService = AdminService();

      // Add your admin email
      await adminService.addAdmin('albinthomastkh2005@gmail.com');

      // Verify it was added
      final isAdmin =
          await adminService.isAdmin('albinthomastkh2005@gmail.com');

      setState(() {
        _isLoading = false;
        _success = true;
        _status = isAdmin
            ? '✅ SUCCESS!\n\nAdmin email added successfully!\n\nalbinthomastkh2005@gmail.com\n\nYou can now:\n1. Close this app\n2. Delete add_admin_once.dart file\n3. Run your main app\n4. Login with this email\n5. You will be redirected to Admin Panel'
            : '❌ ERROR: Email was not added properly. Please check Firestore manually.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _success = false;
        _status =
            '❌ ERROR:\n\n$e\n\nPlease add admin email manually via Firebase Console:\n\n1. Go to Firebase Console\n2. Open Firestore Database\n3. Create collection: admins\n4. Add document ID: albinthomastkh2005@gmail.com\n5. Add field: email = albinthomastkh2005@gmail.com';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLoading
                    ? Icons.cloud_upload
                    : _success
                        ? Icons.check_circle
                        : Icons.error,
                size: 80,
                color: _isLoading
                    ? Colors.blue
                    : _success
                        ? Colors.green
                        : Colors.red,
              ),
              const SizedBox(height: 30),
              Text(
                _isLoading
                    ? 'Adding Admin...'
                    : _success
                        ? 'Success!'
                        : 'Error',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (_success) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Close the app
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text('Done - Close App'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

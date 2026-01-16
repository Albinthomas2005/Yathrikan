import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Utility screen to add admin emails to Firestore
/// This should be run once to set up your admin account
/// Navigate to this screen and add your admin email
class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String _message = '';
  List<String> _currentAdmins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    final admins = await _adminService.getAllAdmins();
    setState(() {
      _currentAdmins = admins;
    });
  }

  Future<void> _addAdmin() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter an email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await _adminService.addAdmin(_emailController.text.trim());
      setState(() {
        _message = 'Admin added successfully!';
        _emailController.clear();
        _isLoading = false;
      });
      await _loadAdmins();
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeAdmin(String email) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.removeAdmin(email);
      setState(() {
        _message = 'Admin removed successfully!';
      });
      await _loadAdmins();
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Admin Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter the email address that should have admin access:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'admin@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Admin'),
              ),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('Error')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('Error')
                        ? Colors.red.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            const Text(
              'Current Admin Emails',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _currentAdmins.isEmpty
                  ? const Center(
                      child: Text(
                        'No admin emails configured',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _currentAdmins.length,
                      itemBuilder: (context, index) {
                        final email = _currentAdmins[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings),
                            title: Text(email),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeAdmin(email),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class TicketValidationScreen extends StatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  State<TicketValidationScreen> createState() => _TicketValidationScreenState();
}

class _TicketValidationScreenState extends State<TicketValidationScreen> {
  final TextEditingController _pinController = TextEditingController();

  void _showValidationDialog(
      BuildContext context, bool success, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ticket Validation',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validate your ride',
              style: AppTextStyles.heading2.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to verify your ticket today.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Manual Entry Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pin, color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Manual Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter the 6-digit PIN code from your purchase receipt.',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: '000 - 000',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Mock Validation Logic
                        // Assume a valid ticket PIN is "123456"
                        // In reality this would call an API
                        final pin = _pinController.text;
                        if (pin == '123456') {
                          _showValidationDialog(
                              context,
                              true,
                              'Ticket Validated!',
                              'Your ride is confirmed. Have a safe journey.');
                        } else {
                          _showValidationDialog(
                              context,
                              false,
                              'Invalid Ticket',
                              'The PIN you entered is not valid. Please try again.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Verify Ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY().fadeIn(),

            const SizedBox(height: 30),

            // Scan QR Function
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage('assets/images/bus_interior_overlay.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black54,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan QR Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use your camera to instantly validate your digital ticket.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 30),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon:
                    Icon(Icons.help_outline, color: Colors.grey[600], size: 18),
                label: Text(
                  'Having trouble? Contact Support',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';
=======
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

class TicketValidationScreen extends StatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  State<TicketValidationScreen> createState() => _TicketValidationScreenState();
}

class _TicketValidationScreenState extends State<TicketValidationScreen> {
  final TextEditingController _pinController = TextEditingController();

<<<<<<< HEAD
  Future<void> _handleVerification() async {
    final loc = AppLocalizations.of(context);
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow)),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Close loader

    // Show success dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('ticket_verified')),
        backgroundColor: Colors.green,
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
=======
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
<<<<<<< HEAD
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('ticket_validation'),
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
=======
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ticket Validation',
          style: AppTextStyles.heading2,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
<<<<<<< HEAD
        padding: const EdgeInsets.all(24.0),
=======
        padding: const EdgeInsets.all(20),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
<<<<<<< HEAD
              loc.translate('validate_ride'),
              style: AppTextStyles.heading1.copyWith(
                  fontSize: 24, color: theme.textTheme.displayLarge?.color),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('choose_verify_method'),
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                  fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Option 1: Manual Entry Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
<<<<<<< HEAD
                    blurRadius: 15,
                    offset: const Offset(0, 5),
=======
                    blurRadius: 20,
                    offset: const Offset(0, 4),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.keyboard,
                            color: Color(0xFF8B7000), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.translate('manual_entry'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
<<<<<<< HEAD
                    loc.translate('enter_pin_hint'),
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  // PIN Input
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "123 - 000 - 000",
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, letterSpacing: 2),
                        icon: const Icon(Icons.pin_outlined, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        loc.translate('verify_ticket'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                      ),
                    ),
                  ),
                ],
              ),
<<<<<<< HEAD
            ),

            const SizedBox(height: 25),

            // Option 2: Scan QR Code Card
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage(
                      'assets/images/bus_interior.jpg'), // Placeholder
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black54, // Darken image
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Placeholder for bus image if asset not found, use gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.black87],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.qrcode_viewfinder,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('scan_qr'),
                          style: const TextStyle(
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
<<<<<<< HEAD
                        const SizedBox(height: 8),
                        Text(
                          loc.translate('scan_qr_desc'),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(loc.translate('scan_ticket')),
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                    body: MobileScanner(
                                      onDetect: (capture) {
                                        final List<Barcode> barcodes =
                                            capture.barcodes;
                                        if (barcodes.isNotEmpty) {
                                          // Handle code
                                          debugPrint(
                                              'Barcode found! ${barcodes.first.rawValue}');
                                          Navigator.pop(
                                              context); // Close scanner
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(loc.translate(
                                                  'ticket_verified')),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(loc.translate('scan_now')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
<<<<<<< HEAD
            ),

            const SizedBox(height: 40),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    loc.translate('contact_support'),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            )
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';
import '../models/payment_model.dart';
import 'payment_screen.dart';
import 'ticket_details_screen.dart';

class TicketValidationScreen extends StatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  State<TicketValidationScreen> createState() => _TicketValidationScreenState();
}

class _TicketValidationScreenState extends State<TicketValidationScreen> {
  final TextEditingController _pinController = TextEditingController();

  Future<void> _handleVerification() async {
    final ticketId = _pinController.text.trim();

    if (ticketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a ticket number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow)),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context); // Close loader

    // Create dummy ticket data for manual entry
    // In a real app, we would fetch this from an API based on the ticketId
    final ticketData = TicketData(
      routeName: 'CHANGANASSERY - MUNDAKKAYAM',
      busId: 'KL33B7747',
      fromLocation: 'KARUKACHAL',
      toLocation: 'KANJIRAPALLY',
      fare: 10.0,
      qrCodeData: ticketId,
    );

    // Navigate to payment screen (Razorpay)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          ticketData: ticketData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('ticket_validation'),
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
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
                      ),
                    ),
                  ),
                ],
              ),
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
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                          final scannedValue =
                                              barcodes.first.rawValue ?? '';
                                          debugPrint(
                                              'Barcode found! $scannedValue');
                                          Navigator.pop(
                                              context); // Close scanner

                                          // Parse QR code data
                                          TicketData? ticketData;

                                          // Try to parse structured QR data
                                          if (scannedValue.contains('|')) {
                                            ticketData = TicketData.fromQrCode(
                                                scannedValue);
                                          } else {
                                            // Fallback: Use default ticket data for demo
                                            ticketData = TicketData(
                                              routeName:
                                                  'CHANGANASSERY - MUNDAKKAYAM',
                                              busId: 'KL33B7747',
                                              fromLocation: 'KARUKACHAL',
                                              toLocation: 'KANJIRAPALLY',
                                              fare: 10.0,
                                              qrCodeData: scannedValue,
                                            );
                                          }

                                          if (ticketData != null) {
                                            // Navigate to Mock payment screen
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PaymentScreen(
                                                  ticketData: ticketData!,
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Show error if QR parsing failed
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Invalid QR code format'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
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
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_model.dart';
import '../services/razorpay_service.dart';
import '../utils/constants.dart';
import 'payment_success_screen.dart';

class RazorpayPaymentScreen extends StatefulWidget {
  final TicketData ticketData;

  const RazorpayPaymentScreen({
    super.key,
    required this.ticketData,
  });

  @override
  State<RazorpayPaymentScreen> createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen> {
  late RazorpayService _razorpayService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();

    // Auto-start payment after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startPayment();
      }
    });
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _startPayment() {
    setState(() => _isProcessing = true);

    HapticFeedback.mediumImpact();

    final transactionId = PaymentTransaction.generateTransactionId();

    _razorpayService.openCheckout(
      amount: widget.ticketData.fare,
      transactionId: transactionId,
      ticketData: widget.ticketData,
      onPaymentSuccess: (transaction) {
        // Update transaction with complete data
        final completeTransaction = transaction.copyWith(
          amount: widget.ticketData.fare,
          routeName: widget.ticketData.routeName,
          busId: widget.ticketData.busId,
          fromLocation: widget.ticketData.fromLocation,
          toLocation: widget.ticketData.toLocation,
        );

        if (mounted) {
          setState(() => _isProcessing = false);

          // Navigate to success screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                transaction: completeTransaction,
                ticketData: widget.ticketData,
              ),
            ),
          );
        }
      },
      onPaymentError: (error) {
        if (mounted) {
          setState(() => _isProcessing = false);

          _showErrorDialog(error);
        }
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Payment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to scanner
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _startPayment(); // Retry payment
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          'Payment',
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Payment Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment,
                  size: 50,
                  color: AppColors.primaryYellow,
                ),
              ),

              const SizedBox(height: 32),

              // Amount Display
              Text(
                '₹${widget.ticketData.fare.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 16),

              // Route Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Route',
                      widget.ticketData.routeName,
                      Icons.route,
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Bus',
                      widget.ticketData.busId,
                      Icons.directions_bus,
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'From',
                      widget.ticketData.fromLocation,
                      Icons.location_on_outlined,
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'To',
                      widget.ticketData.toLocation,
                      Icons.location_on,
                      theme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please use Card payment only (Credit/Debit). Do not use UPI.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Processing Indicator
              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Opening Razorpay...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _startPayment,
                  icon: const Icon(Icons.payment),
                  label:
                      Text('Pay ₹${widget.ticketData.fare.toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Powered by Razorpay
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Secured by ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Razorpay',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF528FF0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryYellow),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

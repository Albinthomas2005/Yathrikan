import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';
import 'payment_success_screen.dart';

class MockPaymentScreen extends StatefulWidget {
  final TicketData ticketData;

  const MockPaymentScreen({
    super.key,
    required this.ticketData,
  });

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  @override
  void initState() {
    super.initState();
    // No initialization needed
  }

  @override
  void dispose() {
    super.dispose();
  }

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption(
      id: 'credit_card',
      name: 'Credit Card',
      icon: Icons.credit_card,
      color: Colors.purple,
    ),
    PaymentMethodOption(
      id: 'debit_card',
      name: 'Debit Card',
      icon: Icons.credit_card,
      color: Colors.blue,
    ),
    PaymentMethodOption(
      id: 'upi',
      name: 'UPI',
      icon: Icons.account_balance,
      color: Colors.green,
    ),
    PaymentMethodOption(
      id: 'google_pay',
      name: 'Google Pay',
      icon: Icons.payment,
      color: Colors.orange,
    ),
    PaymentMethodOption(
      id: 'phonepe',
      name: 'PhonePe',
      icon: Icons.phone_android,
      color: const Color(0xFF5F259F),
    ),
    PaymentMethodOption(
      id: 'paytm',
      name: 'Paytm',
      icon: Icons.wallet,
      color: const Color(0xFF00BAF2),
    ),
  ];

  void _handlePayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final transactionId = PaymentTransaction.generateTransactionId();

    // Create success transaction
    final completeTransaction = PaymentTransaction(
      transactionId: transactionId,
      paymentMethod: _selectedPaymentMethod!.toUpperCase(),
      amount: widget.ticketData.fare,
      timestamp: DateTime.now(),
      status: PaymentStatus.success,
      routeName: widget.ticketData.routeName,
      busId: widget.ticketData.busId,
      fromLocation: widget.ticketData.fromLocation,
      toLocation: widget.ticketData.toLocation,
    );

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
          'Select Payment Method',
          style: AppTextStyles.heading2
              .copyWith(color: theme.textTheme.titleLarge?.color),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryYellow,
                          AppColors.primaryYellow.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryYellow.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${widget.ticketData.fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Route Details
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
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

                  const SizedBox(height: 32),

                  // Payment Methods Title
                  Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method Options
                  ...(_paymentMethods.map((method) {
                    final isSelected = _selectedPaymentMethod == method.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _isProcessing
                            ? null
                            : () {
                                setState(() {
                                  _selectedPaymentMethod = method.id;
                                });
                                HapticFeedback.selectionClick();
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? method.color.withValues(alpha: 0.1)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? method.color
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: method.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method.icon,
                                  color: method.color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  method.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: method.color,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ),

          // Bottom Payment Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${widget.ticketData.fare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
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
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
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

class PaymentMethodOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  PaymentMethodOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

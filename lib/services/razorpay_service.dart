import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_model.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentTransaction)? onSuccess;
  Function(String)? onError;

  // Razorpay Test Mode Credentials
  // Replace with your actual Razorpay API keys
  static const String _keyId =
      'rzp_test_1DP5mmOlF5G5ag'; // Replace with your test key
  // Note: Key secret is not needed in client-side code

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Initialize payment
  void openCheckout({
    required double amount,
    required String transactionId,
    required TicketData ticketData,
    required Function(PaymentTransaction) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) {
    onSuccess = onPaymentSuccess;
    onError = onPaymentError;

    // Convert amount to paise (Razorpay uses smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': _keyId,
      'amount': amountInPaise, // Amount in paise
      'name': 'Yathrikan',
      'description':
          'Bus Ticket: ${ticketData.fromLocation} to ${ticketData.toLocation}',
      'prefill': {'contact': '8888888888', 'email': 'customer@example.com'},
      'theme': {
        'color': '#FFD700' // Yellow theme matching app
      },
      'notes': {
        'transaction_id': transactionId,
        'route': ticketData.routeName,
        'bus': ticketData.busId,
        'from': ticketData.fromLocation,
        'to': ticketData.toLocation,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      if (onError != null) {
        onError!('Failed to open payment: $e');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');

    if (onSuccess != null) {
      final transaction = PaymentTransaction(
        transactionId:
            response.orderId ?? PaymentTransaction.generateTransactionId(),
        paymentMethod: 'RAZORPAY',
        amount: 0, // Amount should be passed from the calling screen
        timestamp: DateTime.now(),
        status: PaymentStatus.success,
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
        routeName: '', // These will be updated from the calling screen
        busId: '',
        fromLocation: '',
        toLocation: '',
      );
      onSuccess!(transaction);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    if (onError != null) {
      onError!('Payment failed: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // Handle external wallet payment if needed
  }

  void dispose() {
    _razorpay.clear();
  }
}

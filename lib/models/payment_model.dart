import 'package:flutter/foundation.dart';

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
}

/// Payment transaction model
class PaymentTransaction {
  final String transactionId;
  final String paymentMethod;
  final double amount;
  final DateTime timestamp;
  final PaymentStatus status;
  // Razorpay fields removed

  final String? errorMessage;

  // Bus/Route information
  final String routeName;
  final String busId;
  final String fromLocation;
  final String toLocation;

  PaymentTransaction({
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    required this.routeName,
    required this.busId,
    required this.fromLocation,
    required this.toLocation,
  });

  /// Generate a unique transaction ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toString().substring(0, 6);
    return 'TXN$timestamp$random';
  }

  /// Create a copy with updated fields
  PaymentTransaction copyWith({
    String? transactionId,
    String? paymentMethod,
    double? amount,
    DateTime? timestamp,
    PaymentStatus? status,
    String? errorMessage,
    String? routeName,
    String? busId,
    String? fromLocation,
    String? toLocation,
  }) {
    return PaymentTransaction(
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      routeName: routeName ?? this.routeName,
      busId: busId ?? this.busId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'errorMessage': errorMessage,
      'routeName': routeName,
      'busId': busId,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
    };
  }

  @override
  String toString() {
    return 'PaymentTransaction(id: $transactionId, amount: ₹$amount, status: $status)';
  }
}

/// Ticket data to pass between screens
class TicketData {
  final String routeName;
  final String busId;
  final String fromLocation;
  final String toLocation;
  final double fare;
  final String? qrCodeData;

  TicketData({
    required this.routeName,
    required this.busId,
    required this.fromLocation,
    required this.toLocation,
    required this.fare,
    this.qrCodeData,
  });

  /// Parse from QR code data
  /// Expected format: "ROUTE:CHANGANASSERY-MUNDAKKAYAM|FARE:10|BUS:KL33B7747|FROM:KARUKACHAL|TO:KANJIRAPALLY"
  static TicketData? fromQrCode(String qrData) {
    try {
      final Map<String, String> data = {};
      final parts = qrData.split('|');

      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          data[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      return TicketData(
        routeName: data['ROUTE'] ?? 'Unknown Route',
        busId: data['BUS'] ?? 'Unknown Bus',
        fromLocation: data['FROM'] ?? 'Unknown',
        toLocation: data['TO'] ?? 'Unknown',
        fare: double.tryParse(data['FARE'] ?? '0') ?? 0.0,
        qrCodeData: qrData,
      );
    } catch (e) {
      debugPrint('Error parsing QR code: $e');
      return null;
    }
  }
}

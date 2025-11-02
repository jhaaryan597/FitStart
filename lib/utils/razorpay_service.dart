import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentError;
  Function()? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    if (onPaymentError != null) {
      onPaymentError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    if (onExternalWallet != null) {
      onExternalWallet!();
    }
  }

  /// Open Razorpay checkout
  ///
  /// Parameters:
  /// - amount: Amount in paisa (multiply by 100)
  /// - orderId: Optional order ID from your backend
  /// - name: Name of the item/service being purchased
  /// - description: Description of the purchase
  /// - prefillContact: Pre-filled phone number
  /// - prefillEmail: Pre-filled email
  void openCheckout({
    required int amount,
    String? orderId,
    required String name,
    required String description,
    String prefillContact = '9999999999',
    String prefillEmail = 'test@example.com',
  }) {
    debugPrint('=== Razorpay Checkout ===');
    debugPrint('Amount: $amount paisa (₹${amount / 100})');
    debugPrint('Name: $name');
    debugPrint('Description: $description');

    var options = {
      // Test API Key - Replace with your actual key from Razorpay Dashboard
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount, // Amount in paisa
      'name': 'FitStart',
      'description': description,
      'prefill': {
        'contact': prefillContact,
        'email': prefillEmail,
      },
      'theme': {
        'color': '#C1FF72', // Your neonGreen color
      },
    };

    // Add order_id if provided
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      debugPrint('Opening Razorpay checkout...');
      _razorpay.open(options);
      debugPrint('Razorpay checkout opened successfully');
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

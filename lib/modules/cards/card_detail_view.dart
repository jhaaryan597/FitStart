import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/modules/cards/cards_list_view.dart';
import 'package:FitStart/utils/razorpay_service.dart';

class CardDetailView extends StatefulWidget {
  final CardData cardData;

  const CardDetailView({Key? key, required this.cardData}) : super(key: key);

  @override
  State<CardDetailView> createState() => _CardDetailViewState();
}

class _CardDetailViewState extends State<CardDetailView> {
  late RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    _razorpayService = RazorpayService();
    _razorpayService.onPaymentSuccess = _handlePaymentSuccess;
    _razorpayService.onPaymentError = _handlePaymentError;
    _razorpayService.onExternalWallet = _handleExternalWallet;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment was successful
    _showSuccessDialog(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Payment failed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message ?? 'Unknown error'}"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet() {
    // External wallet was selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("External wallet selected"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = widget.cardData.price + widget.cardData.gst;

    return Scaffold(
      backgroundColor: colorWhite,
      appBar: AppBar(
        backgroundColor: neonGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Get Fit Card',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: neonGreen,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // Top curved section with card image
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: neonGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.cardData.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.credit_card, size: 80),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.cardData.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // What you get
                const Text(
                  'What you get',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Facilities list
                ...widget.cardData.facilities.map((facility) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          _getFacilityIcon(facility.name),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              facility.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${facility.count}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),

                // Payment Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentRow(
                          widget.cardData.name, '₹${widget.cardData.price}'),
                      const SizedBox(height: 12),
                      _buildPaymentRow('GST @ 18%', '₹${widget.cardData.gst}'),
                      const SizedBox(height: 12),
                      const Divider(color: borderColor),
                      const SizedBox(height: 12),
                      _buildPaymentRow(
                        'Total Paid',
                        '₹$totalPaid',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // Open Razorpay payment
              final totalAmount = widget.cardData.price + widget.cardData.gst;

              _razorpayService.openCheckout(
                amount: totalAmount * 100, // Convert to paisa
                name: widget.cardData.name,
                description: "Purchase of ${widget.cardData.name}",
                prefillContact: '9999999999',
                prefillEmail: 'test@example.com',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: neonGreen,
              foregroundColor: textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Proceed to Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getFacilityIcon(String facilityName) {
    IconData icon;
    switch (facilityName) {
      case 'Steam Room':
        icon = Icons.hot_tub;
        break;
      case 'Swimming Pool':
        icon = Icons.pool;
        break;
      case 'Shower Rooms':
        icon = Icons.shower;
        break;
      case 'Health Café':
        icon = Icons.restaurant;
        break;
      default:
        icon = Icons.check_circle;
    }
    return Icon(icon, color: textPrimary, size: 24);
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: neonGreen,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${widget.cardData.name} has been activated.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: textPrimary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

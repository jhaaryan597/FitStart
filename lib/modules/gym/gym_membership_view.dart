import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/razorpay_service.dart';
import 'package:FitStart/services/ml_recommendation_service.dart';

class GymMembershipView extends StatefulWidget {
  final Gym gym;

  const GymMembershipView({Key? key, required this.gym}) : super(key: key);

  @override
  State<GymMembershipView> createState() => _GymMembershipViewState();
}

class _GymMembershipViewState extends State<GymMembershipView> {
  String _selectedPlan = 'monthly';
  int _totalBill = 0;
  bool _withTrainer = false;
  late RazorpayService _razorpayService;

  final Map<String, Map<String, dynamic>> _plans = {
    'daily': {'label': 'Daily Pass', 'multiplier': 1},
    'monthly': {'label': 'Monthly', 'multiplier': 1},
    'quarterly': {
      'label': 'Quarterly (3 months)',
      'multiplier': 3,
      'discount': 0.1
    },
    'yearly': {
      'label': 'Yearly (12 months)',
      'multiplier': 12,
      'discount': 0.2
    },
  };

  @override
  void initState() {
    super.initState();
    _calculateTotalBill();

    // Initialize Razorpay
    _razorpayService = RazorpayService();
    _razorpayService.onPaymentSuccess = _handlePaymentSuccess;
    _razorpayService.onPaymentError = _handlePaymentError;
    _razorpayService.onExternalWallet = _handleExternalWallet;

    // Track gym view for ML recommendations
    MLRecommendationService.trackGymView(widget.gym.id);
  }

  void _calculateTotalBill() {
    int baseprice = _selectedPlan == 'daily'
        ? widget.gym.dailyPrice
        : widget.gym.monthlyPrice;

    int multiplier = _plans[_selectedPlan]!['multiplier'];
    double discount = _plans[_selectedPlan]!['discount'] ?? 0.0;

    int total = baseprice * multiplier;
    total = (total * (1 - discount)).round();

    if (_withTrainer && widget.gym.hasPersonalTrainer) {
      // Add 4 trainer sessions per month
      total += widget.gym.trainerPrice * 4 * multiplier;
    }

    setState(() {
      _totalBill = total;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Save membership to Supabase
    await _saveMembershipToSupabase(
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      razorpayPaymentId: response.paymentId,
      razorpayOrderId: response.orderId,
      razorpaySignature: response.signature,
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RootView(currentScreen: 1)),
        (route) => false,
      );

      _showSnackBar(context, "Payment successful! Membership activated.");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackBar(
      context,
      "Payment failed: ${response.message ?? 'Unknown error'}",
    );
  }

  void _handleExternalWallet() {
    _showSnackBar(context, "External wallet selected");
  }

  Future<void> _saveMembershipToSupabase({
    required String paymentStatus,
    required String paymentMethod,
    DateTime? joiningDate,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final planData = _plans[_selectedPlan]!;
      final multiplier = planData['multiplier'] as int;

      // Calculate membership period
      final startDate = joiningDate ?? DateTime.now();
      DateTime endDate;

      if (_selectedPlan == 'daily') {
        endDate = startDate.add(const Duration(days: 1));
      } else {
        endDate = DateTime(
          startDate.year,
          startDate.month + multiplier,
          startDate.day,
        );
      }

      await Supabase.instance.client.from('orders').insert({
        'user_id': user.id,
        'venue_id': 'GYM_${widget.gym.id}',
        'venue_name': widget.gym.name,
        'venue_type': 'gym',
        'booking_date': DateFormat('EEEE, dd MMM yyyy').format(startDate),
        'booking_times': [
          'Membership: ${planData['label']}',
          if (_withTrainer) 'With Personal Trainer',
          'Valid until: ${DateFormat('dd MMM yyyy').format(endDate)}',
        ],
        'total_amount': _totalBill,
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      });

      // Track gym membership for ML recommendations
      MLRecommendationService.trackGymMembership(widget.gym.id);
    } catch (e) {
      print('Error saving membership to Supabase: $e');
    }
  }

  Future<void> _handlePayAtGym() async {
    // Show date picker for joining date
    final DateTime? joiningDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor500,
              onPrimary: colorWhite,
              surface: colorWhite,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Select your joining date',
    );

    if (joiningDate == null) return;

    // Save membership to Supabase with pay at gym status
    await _saveMembershipToSupabase(
      paymentStatus: 'pay_at_venue',
      paymentMethod: 'pay_at_gym',
      joiningDate: joiningDate,
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RootView(currentScreen: 1)),
        (route) => false,
      );

      _showSnackBar(
        context,
        "Membership confirmed! Join by ${DateFormat('dd MMM yyyy').format(joiningDate)}",
      );
    }
  }

  void _showPaymentOptionsDialog() {
    final planName = _plans[_selectedPlan]!['label'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Payment Method',
            style: titleTextStyle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Online Payment Option
              InkWell(
                onTap: () {
                  Navigator.pop(context);

                  String description =
                      "$planName membership for ${widget.gym.name}";
                  if (_withTrainer) {
                    description += " with Personal Trainer";
                  }

                  _razorpayService.openCheckout(
                    amount: _totalBill * 100, // Convert to paisa
                    name: widget.gym.name,
                    description: description,
                    prefillContact: '9999999999',
                    prefillEmail: 'test@example.com',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                    border: Border.all(color: primaryColor500),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, color: primaryColor500, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay Online',
                              style: subTitleTextStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pay now via Razorpay',
                              style: descTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: primaryColor500, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Pay at Gym Option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _handlePayAtGym();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                    border: Border.all(color: neonGreen),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, color: neonGreen, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay at Gym',
                              style: subTitleTextStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose joining date & pay later',
                              style: descTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: neonGreen, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlue500),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Get Membership',
          style: titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gym Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.gym.imageAsset,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gym.name,
                          style: subTitleTextStyle.copyWith(fontSize: 16),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.gym.type,
                          style: descTextStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Plan
            Text(
              "Select Membership Plan:",
              style: subTitleTextStyle,
            ),
            const SizedBox(height: 12),

            ...(_plans.entries.map((entry) {
              final planKey = entry.key;
              final planData = entry.value;
              final isSelected = _selectedPlan == planKey;

              int basePrice = planKey == 'daily'
                  ? widget.gym.dailyPrice
                  : widget.gym.monthlyPrice;
              int multiplier = planData['multiplier'];
              double discount = planData['discount'] ?? 0.0;
              int price = (basePrice * multiplier * (1 - discount)).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPlan = planKey;
                    });
                    _calculateTotalBill();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor100 : colorWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor500 : neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryColor500 : neutral500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    planData['label'],
                                    style: normalTextStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? primaryColor500
                                          : neutral700,
                                    ),
                                  ),
                                  if (discount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${(discount * 100).toInt()}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹$price',
                                style: priceTextStyle.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),

            if (widget.gym.hasPersonalTrainer) ...[
              const SizedBox(height: 24),
              Text(
                "Add-ons:",
                style: subTitleTextStyle,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _withTrainer = !_withTrainer;
                  });
                  _calculateTotalBill();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _withTrainer ? primaryColor100 : colorWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _withTrainer ? primaryColor500 : neutral200,
                      width: _withTrainer ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _withTrainer
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: _withTrainer ? primaryColor500 : neutral500,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Trainer',
                              style: normalTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    _withTrainer ? primaryColor500 : neutral700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '4 sessions/month • ₹${widget.gym.trainerPrice}/session',
                              style: descTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Membership Benefits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: primaryColor500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Membership Benefits',
                        style: subTitleTextStyle.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('Unlimited gym access'),
                  _buildBenefitItem('Access to all equipment'),
                  if (widget.gym.hasGroupClasses)
                    _buildBenefitItem('Free group classes'),
                  _buildBenefitItem('Locker facility'),
                  _buildBenefitItem('Member discounts'),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: lightBlue300,
              offset: Offset(0, 0),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Amount:",
                  style: descTextStyle,
                ),
                Text(
                  "INR $_totalBill",
                  style: priceTextStyle,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                  ),
                ),
                onPressed: () {
                  _showPaymentOptionsDialog();
                },
                child: Text(
                  "Get Membership",
                  style: buttonTextStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: primaryColor500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: normalTextStyle.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(
      content: Text(message),
      margin: const EdgeInsets.all(16),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }
}

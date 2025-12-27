import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/model/field_order.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/utils/time_utils.dart';
import 'package:FitStart/utils/razorpay_service.dart';
import 'package:FitStart/utils/animation_utils.dart';
import 'package:FitStart/services/favorites_service.dart';
import 'package:FitStart/services/ml_recommendation_service.dart';

class BookingView extends StatefulWidget {
  final SportField field;

  const BookingView({Key? key, required this.field}) : super(key: key);

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  // DATE
  final int _currentMonth = TimeUtils.getCurrentMonth();
  final int _currentYear = TimeUtils.getCurrentYear();
  int _selectedMonth = TimeUtils.getCurrentMonth();
  String _selectedMonthName = TimeUtils.getCurrentMonthName();
  int _selectedYear = TimeUtils.getCurrentYear();
  final bool _isNextMonthValid = true;
  bool _isPrevMonthValid = false;
  List<int> _availableDates = TimeUtils.getAvailableDateList(
      month: TimeUtils.getCurrentMonth(), year: TimeUtils.getCurrentYear());
  int _selectedDate = 0;

  // TIME
  final String _selectedTime = "";

  final TextEditingController _controller = TextEditingController();
  final dateFormat = DateFormat("EEEE, dd MMM yyyy");
  int _totalBill = 0;
  bool _enableCreateOrderBtn = false;
  final List<String> _selectedTimes = [];

  // Razorpay
  late RazorpayService _razorpayService;

  // Favorites
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });

    // Initialize Razorpay
    _razorpayService = RazorpayService();
    _razorpayService.onPaymentSuccess = _handlePaymentSuccess;
    _razorpayService.onPaymentError = _handlePaymentError;
    _razorpayService.onExternalWallet = _handleExternalWallet;

    // Check favorite status
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(widget.field.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final success = await FavoritesService.toggleFavorite(widget.field.id);
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      // Track favorite/unfavorite for ML recommendations
      if (_isFavorite) {
        MLRecommendationService.trackFavorite(widget.field.id, 'sports_venue');
      } else {
        MLRecommendationService.trackUnfavorite(
            widget.field.id, 'sports_venue');
      }

      _showSnackBar(
        context,
        _isFavorite ? 'Added to favorites' : 'Removed from favorites',
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment was successful
    DateTime selectedDateTime =
        DateTime(_selectedYear, _selectedMonth, _selectedDate);

    // Add to dummy list for backward compatibility
    dummyUserOrderList.add(
      FieldOrder(
        field: widget.field,
        user: sampleUser,
        selectedDate: dateFormat.format(selectedDateTime).toString(),
        selectedTime: _selectedTimes,
      ),
    );

    // Save to Supabase
    await _saveOrderToSupabase(
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
          (route) => false);

      _showSnackBar(context, "Payment successful! Order created.");
    }
  }

  Future<void> _saveOrderToSupabase({
    required String paymentStatus,
    required String paymentMethod,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    try {
      DateTime selectedDateTime =
          DateTime(_selectedYear, _selectedMonth, _selectedDate);

      await ApiService.createBooking(
        venueId: widget.field.id,
        date: selectedDateTime,
        startTime: _selectedTimes.isNotEmpty ? _selectedTimes.first : '00:00',
        endTime: _selectedTimes.isNotEmpty ? _selectedTimes.last : '23:59',
        totalPrice: _totalBill.toDouble(),
        additionalInfo: {
          'venue_name': widget.field.name,
          'booking_times': _selectedTimes,
          'payment_status': paymentStatus,
          'payment_method': paymentMethod,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
        },
      );

      // Track booking for ML recommendations
      MLRecommendationService.trackVenueBooking(widget.field.id);
    } catch (e) {
      print('Error saving order: $e');
    }
  }

  Future<void> _handlePayAtVenue() async {
    // Payment will be done at venue
    DateTime selectedDateTime =
        DateTime(_selectedYear, _selectedMonth, _selectedDate);

    // Add to dummy list for backward compatibility
    dummyUserOrderList.add(
      FieldOrder(
        field: widget.field,
        user: sampleUser,
        selectedDate: dateFormat.format(selectedDateTime).toString(),
        selectedTime: _selectedTimes,
      ),
    );

    // Save to Supabase
    await _saveOrderToSupabase(
      paymentStatus: 'pay_at_venue',
      paymentMethod: 'pay_at_venue',
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RootView(currentScreen: 1)),
          (route) => false);

      _showSnackBar(context, "Booking confirmed! Pay at venue.");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Payment failed
    _showSnackBar(
        context, "Payment failed: ${response.message ?? 'Unknown error'}");
  }

  void _handleExternalWallet() {
    // External wallet was selected
    _showSnackBar(context, "External wallet selected");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: backgroundColor,
              statusBarIconBrightness: Brightness.dark,
            ),
            title: const Text("Booking"),
            backgroundColor: backgroundColor,
            centerTitle: true,
            foregroundColor: primaryColor500,
            actions: [
              _isLoadingFavorite
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : ScaleOnTap(
                      child: (_isFavorite
                          ? PulseAnimation(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                onPressed: _toggleFavorite,
                                tooltip: 'Remove from favorites',
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.favorite_border,
                                color: primaryColor500,
                              ),
                              onPressed: _toggleFavorite,
                              tooltip: 'Add to favorites',
                            )),
                    ),
            ],
          ),
          SliverPadding(
            padding:
                const EdgeInsets.only(right: 24, left: 24, bottom: 24, top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Venue Name",
                        style: subTitleTextStyle,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: primaryColor100, width: 2),
                            color: lightBlue100,
                            borderRadius:
                                BorderRadius.circular(borderRadiusSize)),
                        child: Row(
                          children: [
                            Image.asset(
                              "assets/icons/pin.png",
                              width: 24,
                              height: 24,
                              color: primaryColor500,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(widget.field.name,
                                style: normalTextStyle.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pick a date", style: subTitleTextStyle),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_isPrevMonthValid) {
                                        setState(() {
                                          // update month and year
                                          if (_selectedMonth - 1 == 0) {
                                            _selectedMonth = 12;
                                            _selectedYear = _selectedYear - 1;
                                          } else {
                                            _selectedMonth = _selectedMonth - 1;
                                          }

                                          // update view
                                          _selectedMonthName =
                                              TimeUtils.getMonthNameWithLocale(
                                                  month: _selectedMonth);
                                          _isPrevMonthValid =
                                              _selectedMonth > _currentMonth ||
                                                  _selectedYear > _currentYear;
                                          _availableDates =
                                              TimeUtils.getAvailableDateList(
                                                  month: _selectedMonth,
                                                  year: _selectedYear);
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: (_isPrevMonthValid)
                                            ? neutral700
                                            : neutral50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.arrow_back_ios_rounded,
                                        size: 16,
                                        color: (_isPrevMonthValid)
                                            ? Colors.white
                                            : neutral700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "$_selectedMonthName $_selectedYear",
                                    style: descTextStyle,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (_isNextMonthValid) {
                                        setState(() {
                                          // update month and year
                                          if (_selectedMonth + 1 == 13) {
                                            _selectedMonth = 1;
                                            _selectedYear = _selectedYear + 1;
                                          } else {
                                            _selectedMonth = _selectedMonth + 1;
                                          }

                                          // update view
                                          _selectedMonthName =
                                              TimeUtils.getMonthNameWithLocale(
                                                  month: _selectedMonth);
                                          _isPrevMonthValid =
                                              _selectedMonth > _currentMonth ||
                                                  _selectedYear > _currentYear;
                                          _availableDates =
                                              TimeUtils.getAvailableDateList(
                                                  month: _selectedMonth,
                                                  year: _selectedYear);
                                        });
                                      }
                                      debugPrint(
                                          "selected month = $_selectedMonthName, selected year: $_selectedYear");
                                      debugPrint(
                                          "_isPrevMonthValid = $_isPrevMonthValid");
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: (_isNextMonthValid)
                                            ? neutral700
                                            : neutral50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: (_isNextMonthValid)
                                            ? Colors.white
                                            : neutral700,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              // const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 6,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: _availableDates
                                    .map((e) => GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedDate = e;
                                            });
                                          },
                                          child: Container(
                                            width: 40,
                                            decoration: BoxDecoration(
                                                color: (_selectedDate == e)
                                                    ? primaryColor100
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: (_selectedDate == e)
                                                        ? primaryColor500
                                                        : neutral200,
                                                    width: 1)),
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              e.toString(),
                                              style: descTextStyle.copyWith(
                                                color: (_selectedDate == e)
                                                    ? primaryColor500
                                                    : neutral700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pick a Time",
                                style: subTitleTextStyle,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: primaryColor100,
                                          border: Border.all(
                                              color: primaryColor500),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "Choosed",
                                        style: descTextStyle,
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                            border:
                                                Border.all(color: neutral200)),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "Empty",
                                        style: descTextStyle,
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: neutral200,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "Not Available",
                                        style: descTextStyle,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              // const SizedBox(height: 16,),
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 2,
                                children: availableTimeList.map(
                                  (e) {
                                    final isSelected =
                                        _selectedTimes.contains(e.time);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (e.isAvailable) {
                                            // _selectedTime = e.time;
                                            debugPrint(
                                                "selected time: $_selectedTime");

                                            if (_selectedTimes
                                                .contains(e.time)) {
                                              _selectedTimes.remove(e.time);
                                              _enableCreateOrderBtn =
                                                  _selectedTimes.isNotEmpty &&
                                                      _selectedDate != 0;
                                              _totalBill -= widget.field.price;
                                            } else {
                                              _selectedTimes.add(e.time);
                                              _enableCreateOrderBtn =
                                                  _selectedTimes.isNotEmpty &&
                                                      _selectedDate != 0;
                                              _totalBill += widget.field.price;
                                            }
                                          }
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: (isSelected)
                                                ? primaryColor100
                                                : e.isAvailable
                                                    ? Colors.white
                                                    : neutral200,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: (isSelected)
                                                    ? primaryColor500
                                                    : e.isAvailable
                                                        ? neutral200
                                                        : neutral200,
                                                width: 1)),
                                        alignment: Alignment.center,
                                        child: Text(
                                          e.time,
                                          style: descTextStyle.copyWith(
                                            color: (isSelected)
                                                ? primaryColor500
                                                : e.isAvailable
                                                    ? neutral700
                                                    : neutral500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
              color: lightBlue300,
              offset: Offset(0, 0),
              blurRadius: 10,
            )
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total:",
                    style: descTextStyle,
                  ),
                  Text(
                    "INR $_totalBill",
                    style: priceTextStyle,
                  ),
                ],
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusSize))),
                    onPressed: !_enableCreateOrderBtn
                        ? null
                        : () {
                            _showPaymentOptionsDialog();
                          },
                    child: Text(
                      "Proceed to Pay",
                      style: buttonTextStyle,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentOptionsDialog() {
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
                  // Open Razorpay payment
                  DateTime selectedDateTime =
                      DateTime(_selectedYear, _selectedMonth, _selectedDate);

                  String description =
                      "Booking for ${widget.field.name} on ${dateFormat.format(selectedDateTime)}";

                  _razorpayService.openCheckout(
                    amount: _totalBill * 100, // Convert to paisa
                    name: widget.field.name,
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
              // Pay at Venue Option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _handlePayAtVenue();
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
                      Icon(Icons.store, color: neonGreen, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay at Venue',
                              style: subTitleTextStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pay when you arrive',
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
    _controller.dispose();
    _razorpayService.dispose();
    super.dispose();
  }
}

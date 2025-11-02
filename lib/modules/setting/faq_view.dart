import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';

class FAQView extends StatefulWidget {
  const FAQView({Key? key}) : super(key: key);

  @override
  State<FAQView> createState() => _FAQViewState();
}

class _FAQViewState extends State<FAQView> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I book a sports venue?',
      'answer':
          'To book a venue:\n1. Browse or search for a venue\n2. Tap on the venue to view details\n3. Click "Book Now"\n4. Select your preferred date and time slots\n5. Proceed to payment\n6. Receive confirmation',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept multiple payment methods through Razorpay:\n• Credit/Debit Cards (Visa, Mastercard, Amex)\n• UPI (Google Pay, PhonePe, Paytm, etc.)\n• Net Banking\n• Wallets (Paytm, PhonePe, etc.)\nAll transactions are secure and encrypted.',
    },
    {
      'question': 'Can I cancel or modify my booking?',
      'answer':
          'Yes, you can cancel bookings:\n1. Go to Profile → Bookings & Transactions\n2. Select your booking\n3. Choose "Cancel Booking"\n\nCancellation Policy:\n• Cancel 24+ hours before: Full refund\n• Cancel 12-24 hours before: 50% refund\n• Cancel less than 12 hours: No refund\n\nNote: Modifications are not allowed. Please cancel and create a new booking.',
    },
    {
      'question': 'How do refunds work?',
      'answer':
          'Refunds are processed based on our cancellation policy:\n• Approved refunds take 5-7 business days\n• Refunded to original payment method\n• You\'ll receive an email notification\n• Track refund status in Transactions\n\nFor issues, contact support@fitstart.com',
    },
    {
      'question': 'How accurate are venue locations?',
      'answer':
          'Venue locations are verified and use GPS coordinates for accuracy. To find nearby venues:\n1. Enable location services\n2. Grant FitStart location permission\n3. Venues are sorted by distance\n\nYou can also view venues on the map and get directions through your preferred navigation app.',
    },
    {
      'question': 'What are the operating hours?',
      'answer':
          'Each venue has its own operating hours, displayed on the venue details page. Most venues operate:\n• Weekdays: 6 AM - 10 PM\n• Weekends: 6 AM - 11 PM\n\nSome venues may have different hours. Always check the specific venue\'s schedule before booking.',
    },
    {
      'question': 'How do I add venues to favorites?',
      'answer':
          'To favorite a venue:\n1. Navigate to any venue details or booking page\n2. Tap the heart icon in the top-right corner\n3. View all favorites in Profile → Favorites\n\nFavorites sync across all your devices when you\'re logged in.',
    },
    {
      'question': 'Can I book multiple time slots?',
      'answer':
          'Yes! When booking:\n1. Select your date\n2. Tap multiple time slots (they\'ll highlight)\n3. Total price updates automatically\n4. Proceed to payment for all slots\n\nYou\'ll pay for all selected slots in one transaction.',
    },
    {
      'question': 'What if the venue is closed?',
      'answer':
          'If a venue is temporarily closed:\n• You\'ll see a notice on the venue page\n• Existing bookings may be cancelled with full refund\n• Check back later or choose another venue\n\nFor permanent closures, we\'ll notify you via email if you have upcoming bookings.',
    },
    {
      'question': 'How do I contact the venue?',
      'answer':
          'Venue contact information is available on the details page:\n• Phone number (tap to call)\n• Address (tap for directions)\n• Operating hours\n\nFor booking-related queries, contact our support team.',
    },
    {
      'question': 'Is my payment information secure?',
      'answer':
          'Absolutely! We use:\n• Razorpay for secure payment processing\n• Industry-standard encryption (SSL/TLS)\n• PCI DSS compliance\n• No payment data stored on our servers\n\nYour card details are never shared with us or the venues.',
    },
    {
      'question': 'Can I book for someone else?',
      'answer':
          'Yes! When you make a booking:\n• It\'s tied to your account\n• You can share booking details\n• Venue access is for the booked party\n\nJust show the booking confirmation at the venue. Some venues may require the booker\'s ID.',
    },
    {
      'question': 'What are the venue facilities?',
      'answer':
          'Each venue lists available facilities:\n• WiFi\n• Changing Rooms\n• Lockers\n• Toilets\n• Canteen\n• Charging Areas\n\nFacility icons are shown on the venue details page. Availability may vary by venue.',
    },
    {
      'question': 'How do I report a problem?',
      'answer':
          'To report an issue:\n1. Go to Profile → Support and Help\n2. Use Email Support or Phone Support\n3. Provide:\n   • Your booking ID\n   • Venue name\n   • Description of the issue\n   • Screenshots (if applicable)\n\nWe aim to respond within 24 hours.',
    },
    {
      'question': 'Can I get a receipt/invoice?',
      'answer':
          'Yes! After successful payment:\n• Confirmation email with receipt\n• View in Bookings & Transactions\n• Download or share receipt\n\nReceipts include:\n• Booking details\n• Payment amount\n• Transaction ID\n• Venue information',
    },
  ];

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
          'FAQ',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor100, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: primaryColor500,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Frequently Asked Questions',
                      style: subTitleTextStyle.copyWith(
                        fontSize: 16,
                        color: neutral700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isExpanded
                                        ? primaryColor100
                                        : lightBlue100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Q${index + 1}',
                                    style: normalTextStyle.copyWith(
                                      color: primaryColor500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    faq['question']!,
                                    style: normalTextStyle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: neutral700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: primaryColor500,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(
                                  color: neutral200,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  faq['answer']!,
                                  style: normalTextStyle.copyWith(
                                    color: neutral700,
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 40,
                    color: primaryColor500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Still have questions?',
                    style: subTitleTextStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team for personalized assistance.',
                    style: descTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.headset_mic, size: 20),
                      label: const Text('Contact Support'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

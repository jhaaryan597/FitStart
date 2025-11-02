import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/modules/referral/referral_activity_view.dart';

class ReferralView extends StatelessWidget {
  const ReferralView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const referralCode = 'FITSTART100';
    const totalReward = 1000;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlue500),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Referral',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reward Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB4E856),
                      Color(0xFFD4F582),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    // Background coin icons
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.monetization_on,
                        size: 120,
                        color: Colors.yellow.withOpacity(0.2),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -30,
                      child: Icon(
                        Icons.monetization_on,
                        size: 140,
                        color: Colors.yellow.withOpacity(0.15),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Refer to your friends',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: darkBlue500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Earn 500 Fitcoins',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: darkBlue500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total Reward',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: darkBlue300,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹$totalReward',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkBlue500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Referral Code Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: neutral200,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Referral Code',
                      style: TextStyle(
                        fontSize: 14,
                        color: darkBlue300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: darkBlue500,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: referralCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy,
                            size: 20,
                            color: darkBlue300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // How it works section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How it works?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkBlue500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepItem(
                    number: '1',
                    title: 'Share Your Code',
                    description:
                        'Share your unique referral code with friends.',
                    icon: Icons.share,
                    color: const Color(0xFFB4E856),
                  ),
                  const SizedBox(height: 12),
                  _buildStepItem(
                    number: '2',
                    title: 'Friend Signs Up',
                    description:
                        'Your friend signs up for FitStart using your code.',
                    icon: Icons.person_add,
                    color: const Color(0xFFD4F582),
                  ),
                  const SizedBox(height: 12),
                  _buildStepItem(
                    number: '3',
                    title: 'Both Earn Coins',
                    description: 'Both you and your friend earn 500 coins.',
                    icon: Icons.card_giftcard,
                    color: const Color(0xFFE0F99E),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: backgroundColor,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReferralActivityView(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB4E856),
              foregroundColor: darkBlue500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'See Referral Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: darkBlue500,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number. $title',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: darkBlue300,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

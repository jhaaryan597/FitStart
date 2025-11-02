import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';

class ReferralActivityView extends StatelessWidget {
  const ReferralActivityView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final referrals = _getDummyReferrals();
    final totalReferrals = referrals.length;
    final totalCoinsEarned = totalReferrals * 500;
    final availableCoins = totalCoinsEarned - 2000; // Some coins might be used

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
          'Referral Activity',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Section
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkBlue500,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Total Referrals', totalReferrals.toString()),
              const SizedBox(height: 8),
              _buildSummaryRow(
                  'Total Coins Earned', totalCoinsEarned.toString()),
              const SizedBox(height: 8),
              _buildSummaryRow('Available Coins', availableCoins.toString()),
              const SizedBox(height: 32),

              // Referral List
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkBlue500,
                ),
              ),
              const SizedBox(height: 16),

              // Referral Items
              ...referrals.map((referral) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildReferralItem(referral),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: neutral400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: darkBlue500,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralItem(ReferralItem referral) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: referral.avatarColor,
          backgroundImage: referral.avatarImage != null
              ? AssetImage(referral.avatarImage!)
              : null,
          child: referral.avatarImage == null
              ? Icon(
                  referral.icon ?? Icons.person,
                  color: Colors.white,
                  size: 24,
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Name and Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                referral.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                referral.date,
                style: const TextStyle(
                  fontSize: 13,
                  color: neutral400,
                ),
              ),
            ],
          ),
        ),
        // Coins Earned
        Text(
          '+${referral.coinsEarned} FitCoins',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  List<ReferralItem> _getDummyReferrals() {
    return [
      ReferralItem(
        name: 'Rahul Sharma',
        date: '15/05/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFF90CAF9),
        icon: Icons.person,
      ),
      ReferralItem(
        name: 'Priya Patel',
        date: '15/05/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFFFFCC80),
        icon: Icons.person,
      ),
      ReferralItem(
        name: 'Arjun Singh',
        date: '15/05/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFF80CBC4),
        icon: Icons.person,
      ),
      ReferralItem(
        name: 'Ananya Reddy',
        date: '15/04/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFFE1BEE7),
        icon: Icons.person,
      ),
      ReferralItem(
        name: 'Vikas Mehta',
        date: '15/04/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFF757575),
        icon: Icons.person,
      ),
      ReferralItem(
        name: 'Sneha Iyer',
        date: '15/04/2024',
        coinsEarned: 500,
        avatarColor: const Color(0xFFFFAB91),
        icon: Icons.person,
      ),
    ];
  }
}

class ReferralItem {
  final String name;
  final String date;
  final int coinsEarned;
  final Color avatarColor;
  final String? avatarImage;
  final IconData? icon;

  ReferralItem({
    required this.name,
    required this.date,
    required this.coinsEarned,
    required this.avatarColor,
    this.avatarImage,
    this.icon,
  });
}

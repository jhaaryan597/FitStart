import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportHelpView extends StatelessWidget {
  const SupportHelpView({Key? key}) : super(key: key);

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
          'Support and Help',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Methods Section
            Text(
              'Contact Us',
              style: titleTextStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@fitstart.com',
              onTap: () {
                _launchUrl('mailto:support@fitstart.com');
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+91 1800-123-4567',
              onTap: () {
                _launchUrl('tel:+911800-123-4567');
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Available Mon-Fri, 9 AM - 6 PM',
              onTap: () {
                _showComingSoonDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.public,
              title: 'Visit Our Website',
              subtitle: 'www.fitstart.com',
              onTap: () {
                _launchUrl('https://www.fitstart.com');
              },
            ),
            const SizedBox(height: 32),

            // Common Issues Section
            Text(
              'Common Issues',
              style: titleTextStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            _buildHelpTopicCard(
              icon: Icons.credit_card_outlined,
              title: 'Payment Issues',
              description: 'Problems with payments or refunds',
              onTap: () {
                _showHelpDialog(
                  context,
                  'Payment Issues',
                  'If you\'re experiencing payment issues:\n\n'
                      '1. Check your internet connection\n'
                      '2. Verify your payment method details\n'
                      '3. Ensure sufficient balance\n'
                      '4. Try a different payment method\n\n'
                      'For refunds, please contact support with your booking ID.',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildHelpTopicCard(
              icon: Icons.calendar_today_outlined,
              title: 'Booking Problems',
              description: 'Issues with creating or managing bookings',
              onTap: () {
                _showHelpDialog(
                  context,
                  'Booking Problems',
                  'If you can\'t complete a booking:\n\n'
                      '1. Make sure you\'ve selected a date and time\n'
                      '2. Check venue availability\n'
                      '3. Verify your account is logged in\n'
                      '4. Clear app cache and try again\n\n'
                      'To cancel a booking, go to Bookings & Transactions.',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildHelpTopicCard(
              icon: Icons.account_circle_outlined,
              title: 'Account Settings',
              description: 'Help with profile and account management',
              onTap: () {
                _showHelpDialog(
                  context,
                  'Account Settings',
                  'Managing your account:\n\n'
                      '1. Update profile from Profile tab\n'
                      '2. Change email in Edit Profile\n'
                      '3. Reset password via Settings\n'
                      '4. Delete account in Settings (permanent)\n\n'
                      'Contact support for account recovery.',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildHelpTopicCard(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              description: 'Issues with finding nearby venues',
              onTap: () {
                _showHelpDialog(
                  context,
                  'Location Services',
                  'If locations aren\'t working:\n\n'
                      '1. Enable location services in device settings\n'
                      '2. Grant FitStart location permissions\n'
                      '3. Ensure GPS is turned on\n'
                      '4. Check for a stable internet connection\n\n'
                      'You can also manually search for venues.',
                );
              },
            ),
            const SizedBox(height: 32),

            // Feedback Section
            Text(
              'Send Feedback',
              style: titleTextStyle.copyWith(fontSize: 20),
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
                    Icons.feedback_outlined,
                    size: 48,
                    color: primaryColor500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'d love to hear from you!',
                    style: subTitleTextStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your thoughts, suggestions, or report bugs to help us improve FitStart.',
                    style: descTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _launchUrl(
                            'mailto:feedback@fitstart.com?subject=App Feedback');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Send Feedback'),
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: normalTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: descTextStyle.copyWith(
                      color: neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: neutral500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTopicCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor500,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: normalTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: descTextStyle.copyWith(
                      color: neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: neutral500,
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showHelpDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: titleTextStyle,
          ),
          content: Text(
            content,
            style: normalTextStyle.copyWith(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Got it',
                style: normalTextStyle.copyWith(
                  color: primaryColor500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Coming Soon',
            style: titleTextStyle,
          ),
          content: Text(
            'Live chat support will be available soon. For now, please contact us via email or phone.',
            style: normalTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'OK',
                style: normalTextStyle.copyWith(
                  color: primaryColor500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

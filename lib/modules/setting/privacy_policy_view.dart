import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

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
          'Privacy Policy',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              icon: Icons.security,
              title: 'Data Collection',
              content:
                  'We collect information you provide directly to us, including your name, email address, profile information, and booking history. We use this information to provide and improve our services, process your bookings, and communicate with you.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.lock_outline,
              title: 'Data Security',
              content:
                  'We implement industry-standard security measures to protect your personal information. Your data is encrypted both in transit and at rest. We use Supabase as our backend provider, which complies with SOC 2 Type II standards.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.share_outlined,
              title: 'Information Sharing',
              content:
                  'We do not sell your personal information to third parties. We may share your information with venue operators only for the purpose of processing your bookings. We may also share data with service providers who assist us in operating our platform.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.location_on_outlined,
              title: 'Location Data',
              content:
                  'We collect location data to show you nearby venues and calculate distances. You can control location permissions through your device settings. Location data is used solely to enhance your experience and is not shared with third parties.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.cookie_outlined,
              title: 'Cookies and Tracking',
              content:
                  'We use cookies and similar technologies to remember your preferences, analyze app usage, and improve our services. You can manage cookie preferences through your device settings.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.person_remove_outlined,
              title: 'Your Rights',
              content:
                  'You have the right to access, update, or delete your personal information at any time. You can also request a copy of your data or object to its processing. Contact our support team to exercise these rights.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.child_care_outlined,
              title: 'Children\'s Privacy',
              content:
                  'Our services are not intended for users under the age of 13. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.update_outlined,
              title: 'Policy Updates',
              content:
                  'We may update this privacy policy from time to time. We will notify you of any significant changes via email or through the app. Your continued use of our services after such modifications constitutes acceptance of the updated policy.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor100, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: primaryColor500,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last updated: October 2025',
                      style: descTextStyle.copyWith(
                        color: neutral700,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightBlue100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primaryColor500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: subTitleTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: normalTextStyle.copyWith(
              color: neutral700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';

class LegalInformationView extends StatelessWidget {
  const LegalInformationView({Key? key}) : super(key: key);

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
          'Legal Information',
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
              icon: Icons.gavel,
              title: 'Terms of Service',
              content: 'By using FitStart, you agree to these terms:\n\n'
                  '1. You must be at least 13 years old to use this service\n'
                  '2. You are responsible for maintaining account security\n'
                  '3. You agree to provide accurate booking information\n'
                  '4. Cancellations are subject to our refund policy\n'
                  '5. We reserve the right to suspend accounts for policy violations\n'
                  '6. You agree not to misuse or abuse the platform\n'
                  '7. Venue availability and pricing may change without notice',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.copyright,
              title: 'Intellectual Property',
              content:
                  'All content, features, and functionality of FitStart are owned by FitStart and are protected by international copyright, trademark, and other intellectual property laws.\n\n'
                  'You may not:\n'
                  '• Copy, modify, or distribute our content\n'
                  '• Use our trademarks without permission\n'
                  '• Reverse engineer the application\n'
                  '• Create derivative works\n\n'
                  'Venue images are credited to their respective photographers on Unsplash.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.verified_user,
              title: 'User Responsibilities',
              content: 'As a FitStart user, you agree to:\n\n'
                  '• Provide accurate personal and payment information\n'
                  '• Respect venue rules and regulations\n'
                  '• Arrive on time for your bookings\n'
                  '• Use facilities responsibly\n'
                  '• Not engage in fraudulent activities\n'
                  '• Report any issues or safety concerns\n'
                  '• Respect other users and staff\n'
                  '• Follow applicable laws and regulations',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.block,
              title: 'Prohibited Activities',
              content: 'The following activities are strictly prohibited:\n\n'
                  '• Creating fake accounts or bookings\n'
                  '• Using the service for illegal purposes\n'
                  '• Harassing other users or venue staff\n'
                  '• Attempting to hack or disrupt the service\n'
                  '• Submitting false reviews or ratings\n'
                  '• Reselling bookings without authorization\n'
                  '• Sharing account credentials\n\n'
                  'Violations may result in account suspension or legal action.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.warning_amber,
              title: 'Liability and Disclaimers',
              content:
                  'FitStart provides venue booking services "as is" without warranties:\n\n'
                  '• We are not responsible for venue quality or safety\n'
                  '• Venue operators are independent third parties\n'
                  '• We don\'t guarantee continuous, uninterrupted service\n'
                  '• Technical issues may occasionally occur\n'
                  '• Users are responsible for their own safety\n'
                  '• We are not liable for injuries at venues\n'
                  '• Maximum liability is limited to booking amount\n\n'
                  'Always follow venue safety guidelines.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.people,
              title: 'Third-Party Services',
              content: 'FitStart integrates with third-party services:\n\n'
                  '• MongoDB (database)\n'
                  '• Node.js/Express (backend API)\n'
                  '• Razorpay (payment processing)\n'
                  '• Google Maps (location services)\n'
                  '• Unsplash (venue images)\n\n'
                  'These services have their own terms and privacy policies. We are not responsible for their practices or availability. Payment data is handled securely by Razorpay and never stored by us.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.refresh,
              title: 'Modifications to Service',
              content: 'FitStart reserves the right to:\n\n'
                  '• Modify or discontinue features at any time\n'
                  '• Change pricing and booking policies\n'
                  '• Update terms and conditions\n'
                  '• Add or remove venues from the platform\n'
                  '• Implement new features or improvements\n\n'
                  'We will notify users of significant changes via email or in-app notifications. Continued use after changes constitutes acceptance.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.balance,
              title: 'Dispute Resolution',
              content: 'In case of disputes:\n\n'
                  '1. Contact our support team first for resolution\n'
                  '2. We will attempt mediation within 14 days\n'
                  '3. Unresolved disputes may be subject to arbitration\n'
                  '4. Governing law: India\n'
                  '5. Jurisdiction: Courts of Mumbai, India\n\n'
                  'Most issues can be resolved through our support channels. We encourage communication before taking legal action.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.language,
              title: 'International Users',
              content: 'FitStart is currently available in India:\n\n'
                  '• Services are provided under Indian law\n'
                  '• Payment in Indian Rupees (INR)\n'
                  '• Support primarily in English and Hindi\n'
                  '• Some features may vary by region\n\n'
                  'International users may access the service but should be aware of local regulations and currency conversion fees applied by their payment providers.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.contact_mail,
              title: 'Contact Information',
              content: 'For legal inquiries, contact:\n\n'
                  'FitStart Legal Department\n'
                  'Email: legal@fitstart.com\n'
                  'Address: Mumbai, Maharashtra, India\n\n'
                  'For general support:\n'
                  'Email: support@fitstart.com\n'
                  'Phone: +91 1800-123-4567\n\n'
                  'Business hours: Monday-Friday, 9 AM - 6 PM IST',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor100, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: primaryColor500,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Document Information',
                          style: subTitleTextStyle.copyWith(
                            fontSize: 16,
                            color: neutral700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version: 1.0\n'
                    'Last Updated: October 2025\n'
                    'Effective Date: October 2025\n\n'
                    'These terms constitute the entire agreement between you and FitStart.',
                    style: descTextStyle.copyWith(
                      color: neutral700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    Icons.description_outlined,
                    size: 40,
                    color: primaryColor500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need clarification?',
                    style: subTitleTextStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our legal team for questions about these terms.',
                    style: descTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Email legal department
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.email, size: 20),
                      label: const Text('Contact Legal Team'),
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
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

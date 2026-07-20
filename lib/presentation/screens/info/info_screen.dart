import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme_config.dart';

class InfoSection {
  final String heading;
  final String body;
  const InfoSection({required this.heading, required this.body});
}

class InfoScreen extends StatelessWidget {
  final String title;
  final List<InfoSection> sections;

  const InfoScreen({super.key, required this.title, required this.sections});

  static InfoScreen privacy() => InfoScreen(
        title: 'Privacy Policy',
        sections: const [
          InfoSection(
            heading: 'Information We Collect',
            body: 'We collect information you provide when registering,'
                ' making deposits, or updating your profile — including your'
                ' name, email address, phone number, and national ID.'
                ' We also collect transaction data to process your deposits'
                ' and generate account statements.',
          ),
          InfoSection(
            heading: 'How We Use Your Information',
            body: 'Your information is used to operate and improve the SACCO'
                ' services, process transactions, send account notifications,'
                ' comply with legal obligations, and provide customer support.',
          ),
          InfoSection(
            heading: 'Data Security',
            body: 'We implement industry-standard encryption and secure storage'
                ' practices. Access tokens are stored in device secure storage.'
                ' API communication is protected with TLS.'
                ' We do not sell your personal data to third parties.',
          ),
          InfoSection(
            heading: 'Data Retention',
            body: 'We retain your personal data for as long as your account is'
                ' active or as required by law. You may request deletion of'
                ' your account and associated data by contacting support.',
          ),
          InfoSection(
            heading: 'Contact Us',
            body: 'For privacy-related questions or data requests, contact our'
                ' Data Protection Officer at privacy@advancecompany.co.ke.',
          ),
        ],
      );

  static InfoScreen terms() => InfoScreen(
        title: 'Terms of Service',
        sections: const [
          InfoSection(
            heading: 'Membership',
            body: 'Membership in the SACCO is open to all eligible employees'
                ' and approved individuals. By registering, you agree to abide'
                ' by the SACCO\'s by-laws, rules, and policies as updated'
                ' from time to time.',
          ),
          InfoSection(
            heading: 'Deposits',
            body: 'Monthly deposits are subject to a maximum limit as set by'
                ' the SACCO board. Deposits made via M-Pesa are subject to'
                ' confirmation and approval by an authorised officer.'
                ' Approved deposits are final and non-refundable except as'
                ' provided by policy.',
          ),
          InfoSection(
            heading: 'Account Security',
            body: 'You are responsible for maintaining the confidentiality of'
                ' your login credentials. Do not share your password or OTP'
                ' codes with anyone. Report any unauthorised access immediately'
                ' to support.',
          ),
          InfoSection(
            heading: 'Termination',
            body: 'The SACCO reserves the right to suspend or terminate your'
                ' account if you violate these terms, provide false information,'
                ' or engage in fraudulent activity.',
          ),
          InfoSection(
            heading: 'Governing Law',
            body: 'These terms are governed by the laws of Kenya. Any disputes'
                ' shall be resolved under the jurisdiction of Kenyan courts.',
          ),
        ],
      );

  static InfoScreen support() => InfoScreen(
        title: 'Help & Support',
        sections: const [
          InfoSection(
            heading: 'Getting Started',
            body: 'To make a deposit, tap "Make Deposit" on the dashboard.'
                ' Enter the amount and M-Pesa reference number, then submit.'
                ' A SACCO officer will review and approve within 1-2 business days.',
          ),
          InfoSection(
            heading: 'Beneficiaries',
            body: 'Add beneficiaries under the Beneficiaries section.'
                ' Provide their full name, relationship, ID number, and upload'
                ' supporting documents. Beneficiaries must be verified by an'
                ' admin before they are active.',
          ),
          InfoSection(
            heading: 'Documents',
            body: 'Upload required documents (national ID, KRA PIN, payslips)'
                ' in the Documents section. Supported formats: PDF, JPG, PNG.'
                ' Max file size: 10 MB per document.',
          ),
          InfoSection(
            heading: 'Two-Factor Authentication',
            body: 'Enable 2FA in Settings → Security for extra account'
                ' protection. You will need an authenticator app such as'
                ' Google Authenticator or Authy. Once enabled, you will be'
                ' prompted for a 6-digit code at each login.',
          ),
          InfoSection(
            heading: 'Contact Support',
            body: 'Email: support@advancecompany.co.ke\n'
                'Phone: +254 700 000 000\n'
                'Office hours: Monday - Friday, 8 am - 5 pm (EAT)',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final s = sections[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.heading,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

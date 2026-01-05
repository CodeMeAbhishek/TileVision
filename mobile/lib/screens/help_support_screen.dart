import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/responsive_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'cloudbrickstudio@gmail.com',
      queryParameters: {
        'subject': 'TileVision Support Request',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Fallback: copy email to clipboard
      // You could add clipboard functionality here
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Fallback: show snackbar with number
      // You could add clipboard functionality here
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: spacing * 2),
              
              // Help Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(spacing * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.help_outline,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: spacing * 1.5),
                          Expanded(
                            child: Text(
                              'Need Help?',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Text(
                        'We\'re here to help! If you have any questions or need assistance, please reach out to us.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: spacing * 2),
              
              // Contact Options
              Text(
                'Contact Us',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: spacing),
              
              _buildContactCard(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Abhishek Gupta',
                subtitle: '+91 78978 87210',
                onTap: () => _launchPhone('+917897887210'),
                color: Colors.green,
              ),
              
              SizedBox(height: spacing),
              
              _buildContactCard(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Harshit Prajapati',
                subtitle: '+91 87809 45744',
                onTap: () => _launchPhone('+918780945744'),
                color: Colors.green,
              ),
              
              SizedBox(height: spacing),
              
              _buildContactCard(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'cloudbrickstudio@gmail.com',
                onTap: _launchEmail,
                color: theme.colorScheme.primary,
              ),
              
              SizedBox(height: spacing * 2),
              
              // Other Options
              Text(
                'Resources',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: spacing),
              
              _buildContactCard(
                context: context,
                icon: Icons.book_outlined,
                title: 'Documentation',
                subtitle: 'View user guide and tutorials',
                onTap: () {
                  // TODO: Add documentation URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Documentation coming soon'),
                    ),
                  );
                },
                color: theme.colorScheme.secondary,
              ),
              
              SizedBox(height: spacing),
              
              _buildContactCard(
                context: context,
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Found an issue? Let us know',
                onTap: _launchEmail,
                color: Colors.orange,
              ),
              
              SizedBox(height: spacing * 2),
              
              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: spacing),
              
              _buildFAQItem(
                context: context,
                question: 'How do I use TileVision?',
                answer: 'Take or select a photo of your room, choose the floor area, select a tile, and see how it looks in your space!',
              ),
              
              SizedBox(height: spacing),
              
              _buildFAQItem(
                context: context,
                question: 'What is the image limit?',
                answer: 'Your image limit is set by your administrator. Check your Profile screen to see how many images you have remaining.',
              ),
              
              SizedBox(height: spacing),
              
              _buildFAQItem(
                context: context,
                question: 'Can I save my projects?',
                answer: 'Yes! Your projects are automatically saved to your History. You can also save favorites to the Saved section.',
              ),
              
              SizedBox(height: spacing * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final spacing = ResponsiveHelper.getSpacing(context);
    
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(spacing * 1.5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              SizedBox(width: spacing * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    final theme = Theme.of(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing * 2,
              0,
              spacing * 2,
              spacing * 1.5,
            ),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'Getting Started',
            [
              _buildHelpItem(
                'How to start a chat',
                'To start a new chat, go to the People screen and tap on a contact. You can then start sending messages.',
                Icons.chat_bubble_outline,
              ),
              _buildHelpItem(
                'Creating a group',
                'Navigate to the Groups screen and tap the + button. Choose group type and add members to create your group.',
                Icons.group_add,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Privacy & Security',
            [
              _buildHelpItem(
                'Message encryption',
                'All text messages are end-to-end encrypted. Only you and the recipient can read the messages.',
                Icons.security,
              ),
              // _buildHelpItem(
              //   'Managing notifications',
              //   'You can customize notification settings in your profile settings.',
              //   Icons.notifications_none,
              // ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Account Settings',
            [
              _buildHelpItem(
                'Update profile',
                'Go to Profile screen to update your information and profile picture.',
                Icons.person_outline,
              ),
              _buildHelpItem(
                'Friend requests',
                'Accept or decline friend requests from the Friend Requests screen.',
                Icons.people_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need more help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact our support team for additional assistance.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                const email = 'linnminhtet9623@gmail.com';
                const subject = 'PrivyChat Support Request';
                const body = 'Dear Support Team,\n\nI need assistance with: \n\nDetails: \n\nThank you,\n';
                
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: email,
                  query: encodeQueryParameters(<String, String>{
                    'subject': subject,
                    'body': body,
                  }),
                );

                try {
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please install an email app to contact support'),
                          // duration: Duration(seconds: 3),
                          // behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open email app. Please try again later.'),
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }
}
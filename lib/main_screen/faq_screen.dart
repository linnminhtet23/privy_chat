import 'package:flutter/material.dart';
import 'package:privy_chat/widgets/my_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: const Text('FAQ'),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQSection(
            'General',
            [
              {
                'question': 'What is PrivyChat?',
                'answer':
                    'PrivyChat is a secure messaging app designed for private conversations with end-to-end encryption.',
              },
              {
                'question': 'Is PrivyChat free to use?',
                'answer': 'Yes, PrivyChat is completely free to use.',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQSection(
            'Chat Features',
            [
              {
                'question': 'Can I create group chats?',
                'answer':
                    'Yes, you can create group chats and add multiple participants.',
              },
              {
                'question': 'Can I share media files?',
                'answer':
                    'Yes, you can share images, videos, and documents securely.',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQSection(
            'Security',
            [
              {
                'question': 'Is my data secure?',
                'answer':
                    'Yes, all messages are encrypted end-to-end, meaning only you and the recipient can read them.',
              },
              {
                'question': 'Can someone else read my messages?',
                'answer':
                    'No, your messages are encrypted and can only be read by the intended recipients.',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQSection(
            'Account',
            [
              {
                'question': 'How do I change my profile picture?',
                'answer':
                    'Go to Profile, tap on your current profile picture, and select a new image.',
              },
              // {
              //   'question': 'Can I delete my account?',
              //   'answer':
              //       'Yes, you can delete your account from the Privacy & Security settings.',
              // },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(String title, List<Map<String, String>> faqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "How can we help you?",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
                "How do I track my bus?",
                "Go to the home screen and enter your bus number or select a route.",
                textColor),
            _buildFAQItem(
                "How do I book a ticket?",
                "Use the 'Shortest Route' feature to find connections and book tickets.",
                textColor),
            _buildFAQItem(
                "Can I file a complaint?",
                "Yes, navigate to the complaint section from the home screen.",
                textColor),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryYellow),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(CupertinoIcons.chat_bubble_2_fill,
                      color: AppColors.primaryYellow, size: 40),
                  const SizedBox(height: 10),
                  Text("Still need help?",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor)),
                  const SizedBox(height: 5),
                  Text("Contact our support team anytime.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: theme.textTheme.bodySmall?.color)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Contact Us"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, Color? textColor) {
    return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        ),
        child: ExpansionTile(
          iconColor: AppColors.primaryYellow,
          collapsedIconColor: textColor,
          title: Text(question,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer,
                  style: TextStyle(color: textColor?.withValues(alpha: 0.7))),
            )
          ],
        ));
  }
}

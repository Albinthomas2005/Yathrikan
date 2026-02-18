import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccessibilityVoiceScreen extends StatelessWidget {
  const AccessibilityVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accessibility & Voice',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Voice Settings Coming Soon',
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ),
    );
  }
}

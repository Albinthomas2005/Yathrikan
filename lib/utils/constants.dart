import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryYellow = Color(0xFFFFD700); // Vibrant yellow
  static const Color darkBlack = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color white = Colors.white;
}

class AppTextStyles {
  // Headings
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.darkBlack,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBlack,
      );

  // Body
  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBlack,
      );

  static TextStyle get bodyRegular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkBlack,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.greyText,
      );
}

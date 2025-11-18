import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// أنماط النصوص بخط Tajawal العربي الجميل
class AppTextStyles {
  // العناوين الرئيسية
  static TextStyle get displayLarge => GoogleFonts.tajawal(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.tajawal(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displaySmall => GoogleFonts.tajawal(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // العناوين
  static TextStyle get headlineLarge => GoogleFonts.tajawal(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textGold,
    height: 1.2,
  );

  static TextStyle get headlineMedium => GoogleFonts.tajawal(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.tajawal(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // النصوص العادية
  static TextStyle get bodyLarge => GoogleFonts.tajawal(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // نصوص الأزرار
  static TextStyle get buttonLarge => GoogleFonts.tajawal(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.pureBlack,
    letterSpacing: 0.5,
  );

  static TextStyle get buttonMedium => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.pureBlack,
    letterSpacing: 0.5,
  );

  // نصوص الحقول
  static TextStyle get inputLabel => GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get inputText => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputHint => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.lightGray,
  );

  // نصوص صغيرة
  static TextStyle get caption => GoogleFonts.tajawal(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get overline => GoogleFonts.tajawal(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );
}

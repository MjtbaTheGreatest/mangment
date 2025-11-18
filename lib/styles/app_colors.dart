import 'package:flutter/material.dart';

/// ألوان التطبيق الفخمة بتدرجات أصفر وأسود
class AppColors {
  // الألوان الأساسية - تدرجات الأصفر الذهبي
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color lightGold = Color(0xFFFFF4C4);
  static const Color mediumGold = Color(0xFFFFBF00);
  static const Color darkGold = Color(0xFFB8860B);

  // تدرجات الأسود الأنيق
  static const Color pureBlack = Color(0xFF000000);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2D2D2D);
  static const Color mediumGray = Color(0xFF424242);
  static const Color lightGray = Color(0xFF757575);

  // ألوان التأثير الزجاجي (Glassmorphism)
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x33000000);
  static const Color glassGold = Color(0x22FFD700);

  // التدرجات الفخمة للخلفيات
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFBF00), Color(0xFFB8860B)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
  );

  // ألوان النصوص
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textGold = Color(0xFFFFD700);

  // ألوان الحالات
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color danger = Color(0xFFFF5252); // نفس error
  static const Color warning = Color(0xFFFFC107);
  
  // ألوان إضافية للنصوص
  static const Color white40 = Color(0x66FFFFFF);
  static const Color info = Color(0xFF2196F3);
}

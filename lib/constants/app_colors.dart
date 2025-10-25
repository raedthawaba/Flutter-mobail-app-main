import 'package:flutter/material.dart';

class AppColors {
  // ألوان مستوحاة من النضال والتحرر
  static const Color primaryGreen = Color(0xFF2E7D32); // الأخضر الزيتوني
  static const Color primaryRed = Color(0xFFB71C1C); // الأحمر الداكن
  static const Color primaryBlack = Color(0xFF212121); // الأسود الأنيق
  static const Color primaryWhite = Color(0xFFFAFAFA); // الأبيض النقي
  static const Color earthBrown = Color(0xFF5D4037); // البني الترابي
  
  // ألوان ثانوية
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color lightRed = Color(0xFFE57373);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color darkRed = Color(0xFF880E4F);
  
  // ألوان النصوص
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // ألوان الخلفيات
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF303030);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // ألوان الحالات
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // إضافات للشاشات الجديدة
  static const Color primaryColor = primaryGreen; // Alias for primaryGreen
  static const Color backgroundColor = Color(0xFFF8F9FA); // خلفية فاتحة
  static const Color accentColor = Color(0xFF2196F3); // لون إضافي
  static const Color borderColor = Color(0xFFE0E0E0); // لون الحدود
  
  // تدرجات لونية
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, darkGreen],
  );
  
  static const LinearGradient martyrGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, darkRed],
  );
  
  static const LinearGradient freedomGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryRed],
  );
}
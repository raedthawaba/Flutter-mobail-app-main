import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';

  // ValueNotifiers للتحديث الديناميكي
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar', 'SA'));

  /// تهيئة الخدمة وتحميل الإعدادات المحفوظة
  Future<void> initialize() async {
    themeModeNotifier.value = await getSavedThemeMode();
    localeNotifier.value = await getSavedLanguage();
  }

  /// الحصول على وضع المظهر المحفوظ
  Future<ThemeMode> getSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey) ?? 'النظام';
      
      switch (theme) {
        case 'فاتح':
          return ThemeMode.light;
        case 'داكن':
          return ThemeMode.dark;
        case 'النظام':
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      return ThemeMode.system;
    }
  }

  /// حفظ وضع المظهر مع التحديث الديناميكي
  Future<void> saveThemeMode(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
      
      // تحديث ThemeMode فوراً
      switch (theme) {
        case 'فاتح':
          themeModeNotifier.value = ThemeMode.light;
          break;
        case 'داكن':
          themeModeNotifier.value = ThemeMode.dark;
          break;
        case 'النظام':
        default:
          themeModeNotifier.value = ThemeMode.system;
          break;
      }
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  /// الحصول على اللغة المحفوظة
  Future<Locale> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(_languageKey) ?? 'العربية';
      
      switch (language) {
        case 'العربية':
          return const Locale('ar', 'SA');
        case 'English':
          return const Locale('en', 'US');
        default:
          return const Locale('ar', 'SA');
      }
    } catch (e) {
      return const Locale('ar', 'SA');
    }
  }

  /// حفظ اللغة مع التحديث الديناميكي
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
      
      // تحديث Locale فوراً
      switch (language) {
        case 'العربية':
          localeNotifier.value = const Locale('ar', 'SA');
          break;
        case 'English':
          localeNotifier.value = const Locale('en', 'US');
          break;
        default:
          localeNotifier.value = const Locale('ar', 'SA');
          break;
      }
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  /// تحويل ThemeMode إلى نص عربي
  String themeModeToArabic(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
      default:
        return 'النظام';
    }
  }

  /// تحويل Locale إلى نص عربي
  String localeToArabic(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'العربية';
    }
  }
}

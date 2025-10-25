import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _keyLanguage = 'app_language';
  
  static const List<String> supportedLanguages = [
    'ar', // Arabic
    'en', // English
  ];

  // Default language is Arabic for Arabic user base
  static const String defaultLanguage = 'ar';

  // Get current language
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? defaultLanguage;
  }

  // Set language and save to preferences
  static Future<bool> setLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keyLanguage, languageCode);
  }

  // Get locale from language code
  static List<Locale> getSupportedLocales() {
    return supportedLanguages.map((code) => Locale(code)).toList();
  }

  // Check if language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }

  // Get display name for language
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }

  // Get all languages with their display names
  static Map<String, String> getAllLanguages() {
    return {
      'ar': 'العربية',
      'en': 'English',
    };
  }
}
class AppConstants {
  // معلومات التطبيق
  static const String appName = 'توثيق الشهداء والجرحى والأسرى';
  static const String appVersion = '2.0.0 - Premium Edition';
  static const String buildDate = '2025-10-25';
  
  // مفاتيح التخزين المحلي الأساسية
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserType = 'user_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // مفاتيح المفضلة والبحث المتقدم
  static const String keyFavoriteMartyrs = 'favorite_martyrs';
  static const String keyFavoriteInjured = 'favorite_injured';
  static const String keyFavoritePrisoners = 'favorite_prisoners';
  static const String keyRecentSearches = 'recent_searches';
  static const String keySearchFilters = 'search_filters';
  
  // مفاتيح الإعدادات المتقدمة
  static const String keyAutoBackup = 'auto_backup';
  static const String keyMapPreferences = 'map_preferences';
  static const String keyNotificationSettings = 'notification_settings';
  static const String keyAdvancedFeatures = 'advanced_features';
  
  // مفاتيح الإحصائيات والبيانات
  static const String keyStatisticsCache = 'statistics_cache';
  static const String keyLastBackup = 'last_backup';
  static const String keyDataVersion = 'data_version';
  
  // أنواع المستخدمين
  static const String userTypeAdmin = 'admin';
  static const String userTypeRegular = 'regular';
  
  // أسماء الجداول في قاعدة البيانات
  static const String tableUsers = 'users';
  static const String tableMartyrs = 'martyrs';
  static const String tableInjured = 'injured';
  static const String tablePrisoners = 'prisoners';
  
  // حالات السجلات
  static const String statusPending = 'قيد المراجعة';
  static const String statusApproved = 'تم التوثيق';
  static const String statusRejected = 'مرفوض';
  
  // درجات الإصابة
  static const List<String> injuryDegrees = [
    'خفيفة',
    'متوسطة',
    'خطيرة',
    'حرجة'
  ];
  
  // أنواع الملفات المدعومة
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // الحد الأقصى لحجم الملفات (بالميجابايت)
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  
  // أقسام التطبيق الأساسية
  static const String sectionMartyrs = 'الشهداء';
  static const String sectionInjured = 'الجرحى';
  static const String sectionPrisoners = 'الأسرى';
  
  // الأقسام المميزة الجديدة
  static const String sectionFavorites = 'المفضلة';
  static const String sectionSearch = 'البحث المتقدم';
  static const String sectionStatistics = 'الإحصائيات';
  static const String sectionMaps = 'الخرائط';
  static const String sectionBackup = 'النسخ الاحتياطي';
  static const String sectionAnalytics = 'التحليل الذكي';
  
  // رسائل التأكيد الأساسية
  static const String confirmLogout = 'هل أنت متأكد من تسجيل الخروج؟';
  static const String confirmDelete = 'هل أنت متأكد من حذف هذا السجل؟';
  static const String confirmSubmit = 'هل أنت متأكد من إرسال هذا النموذج؟';
  
  // رسائل التأكيد للميزات المميزة
  static const String confirmAddToFavorites = 'هل تريد إضافة هذا السجل للمفضلة؟';
  static const String confirmRemoveFromFavorites = 'هل تريد حذف هذا السجل من المفضلة؟';
  static const String confirmBackupData = 'هل تريد إنشاء نسخة احتياطية من جميع البيانات؟';
  static const String confirmRestoreData = 'هل تريد استعادة البيانات من النسخة الاحتياطية؟';
  static const String confirmClearSearchHistory = 'هل تريد مسح تاريخ البحث؟';
  static const String confirmEnableLocation = 'هل تريد تفعيل خدمة الموقع للخرائط؟';
  
  // معايير البحث المتقدم
  static const Map<String, String> searchCriteria = {
    'name': 'الاسم',
    'location': 'الموقع',
    'date': 'التاريخ',
    'degree': 'درجة الإصابة',
    'status': 'الحالة',
    'notes': 'الملاحظات',
    'images': 'الصور'
  };
  
  // محافظات اليمن
  static const List<String> yemenGovernorates = [
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'ذمار',
    'حضرموت',
    'أبين',
    'البيضاء',
    'لحج',
    'مأرب',
    'الجوف',
    'صعدة',
    'مارب',
    'نهم',
    'عمران',
    'حجة',
    'ريمة',
    'إب',
    'أرخبيل سقطرى',
    'ريمة',
    'ظفار'
  ];
  
  // أنواع البيانات للتصدير
  static const Map<String, String> exportTypes = {
    'json': 'JSON - للتطبيقات',
    'csv': 'CSV - للجداول',
    'pdf': 'PDF - للتقارير',
    'xml': 'XML - للبيانات'
  };
  
  // إعدادات الخرائط الافتراضية
  static const Map<String, dynamic> defaultMapSettings = {
    'enableLocation': true,
    'showClusters': true,
    'defaultZoom': 13,
    'mapType': 'satellite',
    'showSatelliteImages': true
  };
  
  // مستويات الأمان للبيانات
  static const Map<String, int> securityLevels = {
    'public': 1,
    'restricted': 2,
    'confidential': 3,
    'secret': 4
  };
}

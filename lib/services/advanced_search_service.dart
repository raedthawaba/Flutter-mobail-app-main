import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'firebase_database_service.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';

class AdvancedSearchService {
  static final AdvancedSearchService _instance = AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  late SharedPreferences _prefs;
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  // تهيئة الخدمة
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _dbService.initializeFirebase(); // تهيئة Firebase
  }

  // البحث مع فلاتر متقدمة
  Future<Map<String, dynamic>> searchWithFilters({
    required String query,
    String? type,
    String? location,
    String? dateFrom,
    String? dateTo,
    String? status,
    String? injuryDegree,
    bool? isFavorite,
  }) async {
    Map<String, dynamic> results = {
      'martyrs': [],
      'injured': [],
      'prisoners': [],
      'total': 0,
      'hasResults': false,
    };

    try {
      // البحث في الشهداء
      List<Martyr> martyrs = await _searchMartyrs(query, location, dateFrom, dateTo, status, isFavorite);
      
      // البحث في الجرحى
      List<Injured> injured = await _searchInjured(query, location, dateFrom, dateTo, status, injuryDegree, isFavorite);
      
      // البحث في أسرى
      List<Prisoner> prisoners = await _searchPrisoners(query, location, dateFrom, dateTo, status, isFavorite);

      // تطبيق فلتر النوع إذا كان محدد
      if (type != null && type.isNotEmpty && type != 'favorites') {
        switch (type.toLowerCase()) {
          case 'martyrs':
            results['martyrs'] = martyrs;
            results['injured'] = [];
            results['prisoners'] = [];
            break;
          case 'injured':
            results['martyrs'] = [];
            results['injured'] = injured;
            results['prisoners'] = [];
            break;
          case 'prisoners':
            results['martyrs'] = [];
            results['injured'] = [];
            results['prisoners'] = prisoners;
            break;
        }
      } else {
        // إرجاع جميع النتائج
        results['martyrs'] = martyrs;
        results['injured'] = injured;
        results['prisoners'] = prisoners;
      }

      // حساب النتائج
      results['total'] = martyrs.length + injured.length + prisoners.length;
      results['hasResults'] = results['total'] > 0;

    } catch (e) {
      print('خطأ في البحث: $e');
    }

    return results;
  }

  // البحث في الشهداء
  Future<List<Martyr>> _searchMartyrs(String query, String? location, String? dateFrom, String? dateTo, String? status, bool? isFavorite) async {
    try {
      List<Martyr> allMartyrs = await _dbService.getAllMartyrs();
      
      return allMartyrs.where((martyr) {
        // فلتر النص
        if (query.isNotEmpty) {
          bool matchesName = martyr.fullName.toLowerCase().contains(query.toLowerCase()) ||
                           (martyr.nickname?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                           (martyr.tribe?.toLowerCase().contains(query.toLowerCase()) ?? false);
          if (!matchesName) return false;
        }

        // فلتر الموقع
        if (location != null && location.isNotEmpty) {
          if (!martyr.deathPlace.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }

        // فلتر التاريخ
        if (dateFrom != null || dateTo != null) {
          try {
            DateTime martyrDate = martyr.deathDate;
            if (dateFrom != null) {
              DateTime fromDate = DateTime.parse(dateFrom);
              if (martyrDate.isBefore(fromDate)) return false;
            }
            if (dateTo != null) {
              DateTime toDate = DateTime.parse(dateTo);
              if (martyrDate.isAfter(toDate)) return false;
            }
          } catch (e) {
            print('خطأ في تاريخ الشهداء: $e');
          }
        }

        // فلتر الحالة
        if (status != null && status.isNotEmpty) {
          if (martyr.status != status) return false;
        }

        // فلتر المفضلة
        if (isFavorite == true) {
          // يمكن تنفيذ منطق المفضلة هنا
        }

        return true;
      }).toList();
    } catch (e) {
      print('خطأ في البحث عن الشهداء: $e');
      return [];
    }
  }

  // البحث في الجرحى
  Future<List<Injured>> _searchInjured(String query, String? location, String? dateFrom, String? dateTo, String? status, String? injuryDegree, bool? isFavorite) async {
    try {
      List<Injured> allInjured = await _dbService.getAllInjured();
      
      return allInjured.where((injured) {
        // فلتر النص
        if (query.isNotEmpty) {
          bool matchesName = injured.fullName.toLowerCase().contains(query.toLowerCase()) ||
                           (injured.tribe?.toLowerCase().contains(query.toLowerCase()) ?? false);
          if (!matchesName) return false;
        }

        // فلتر الموقع
        if (location != null && location.isNotEmpty) {
          if (!injured.injuryPlace.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }

        // فلتر التاريخ
        if (dateFrom != null || dateTo != null) {
          try {
            DateTime injuryDate = injured.injuryDate;
            if (dateFrom != null) {
              DateTime fromDate = DateTime.parse(dateFrom);
              if (injuryDate.isBefore(fromDate)) return false;
            }
            if (dateTo != null) {
              DateTime toDate = DateTime.parse(dateTo);
              if (injuryDate.isAfter(toDate)) return false;
            }
          } catch (e) {
            print('خطأ في تاريخ الجرحى: $e');
          }
        }

        // فلتر الحالة
        if (status != null && status.isNotEmpty) {
          if (injured.status != status) return false;
        }

        // فلتر درجة الإصابة
        if (injuryDegree != null && injuryDegree.isNotEmpty) {
          if (injured.injuryDegree != injuryDegree) return false;
        }

        // فلتر المفضلة
        if (isFavorite == true) {
          // يمكن تنفيذ منطق المفضلة هنا
        }

        return true;
      }).toList();
    } catch (e) {
      print('خطأ في البحث عن الجرحى: $e');
      return [];
    }
  }

  // البحث في أسرى
  Future<List<Prisoner>> _searchPrisoners(String query, String? location, String? dateFrom, String? dateTo, String? status, bool? isFavorite) async {
    try {
      List<Prisoner> allPrisoners = await _dbService.getAllPrisoners();
      
      return allPrisoners.where((prisoner) {
        // فلتر النص
        if (query.isNotEmpty) {
          bool matchesName = prisoner.fullName.toLowerCase().contains(query.toLowerCase()) ||
                           (prisoner.tribe?.toLowerCase().contains(query.toLowerCase()) ?? false);
          if (!matchesName) return false;
        }

        // فلتر الموقع
        if (location != null && location.isNotEmpty) {
          if (!prisoner.capturePlace.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }

        // فلتر التاريخ
        if (dateFrom != null || dateTo != null) {
          try {
            DateTime captureDate = prisoner.captureDate;
            if (dateFrom != null) {
              DateTime fromDate = DateTime.parse(dateFrom);
              if (captureDate.isBefore(fromDate)) return false;
            }
            if (dateTo != null) {
              DateTime toDate = DateTime.parse(dateTo);
              if (captureDate.isAfter(toDate)) return false;
            }
          } catch (e) {
            print('خطأ في تاريخ الأسرى: $e');
          }
        }

        // فلتر الحالة
        if (status != null && status.isNotEmpty) {
          if (prisoner.status != status) return false;
        }

        // فلتر المفضلة
        if (isFavorite == true) {
          // يمكن تنفيذ منطق المفضلة هنا
        }

        return true;
      }).toList();
    } catch (e) {
      print('خطأ في البحث عن أسرى: $e');
      return [];
    }
  }

  // حفظ البحث الحديث
  Future<void> saveRecentSearch(String query) async {
    try {
      List<String> searches = _prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
      
      // إزالة البحث إذا كان موجوداً مسبقاً
      searches.remove(query);
      
      // إضافة البحث في البداية
      searches.insert(0, query);
      
      // الاحتفاظ بآخر 10 عمليات بحث فقط
      if (searches.length > 10) {
        searches = searches.sublist(0, 10);
      }
      
      await _prefs.setStringList(AppConstants.keyRecentSearches, searches);
    } catch (e) {
      print('خطأ في حفظ البحث: $e');
    }
  }

  // الحصول على عمليات البحث الحديثة
  List<String> getRecentSearches() {
    return _prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
  }

  // مسح تاريخ البحث
  Future<void> clearRecentSearches() async {
    await _prefs.remove(AppConstants.keyRecentSearches);
  }

  // حفظ إعدادات البحث
  Future<void> saveSearchFilters(Map<String, dynamic> filters) async {
    try {
      String filtersJson = json.encode(filters);
      await _prefs.setString(AppConstants.keySearchFilters, filtersJson);
    } catch (e) {
      print('خطأ في حفظ فلاتر البحث: $e');
    }
  }

  // الحصول على إعدادات البحث المحفوظة
  Map<String, dynamic>? getSavedFilters() {
    try {
      String? filtersJson = _prefs.getString(AppConstants.keySearchFilters);
      if (filtersJson != null) {
        return json.decode(filtersJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('خطأ في استعادة فلاتر البحث: $e');
    }
    return null;
  }

  // اقتراحات البحث الذكي
  List<String> getSearchSuggestions(String partialQuery) {
    List<String> suggestions = [];
    
    // اقتراحات من عمليات البحث السابقة
    List<String> recent = getRecentSearches();
    suggestions.addAll(recent.where((search) => 
      search.toLowerCase().contains(partialQuery.toLowerCase())
    ));
    
    // اقتراحات من المحافظات اليمنية
    for (String governorate in AppConstants.yemenGovernorates) {
      if (governorate.toLowerCase().contains(partialQuery.toLowerCase())) {
        suggestions.add(governorate);
      }
    }
    
    // اقتراحات من أنواع البيانات
    if (partialQuery.toLowerCase().contains('شهيد')) {
      suggestions.addAll(['شهيد جديد', 'شهيد مدني', 'شهيد مقاتل']);
    }
    if (partialQuery.toLowerCase().contains('جريح')) {
      suggestions.addAll(['جريح جديد', 'جريح خفيف', 'جريح شديد']);
    }
    if (partialQuery.toLowerCase().contains('أسير')) {
      suggestions.addAll(['أسير جديد', 'أسير محرر', 'أسير مختفي']);
    }
    
    // إزالة التكرارات والحد إلى 10 اقتراحات
    suggestions = suggestions.toSet().toList();
    if (suggestions.length > 10) {
      suggestions = suggestions.take(10).toList();
    }
    
    return suggestions;
  }

  // اقتراحات من أسماء معروفة
  List<String> _getKnownNamesSuggestions(String query) {
    // في التطبيق الحقيقي، ستقرأ من قاعدة بيانات
    List<String> commonNames = [
      'أحمد محمد',
      'فاطمة علي',
      'محمد أحمد',
      'عائشة محمد',
      'خالد أحمد'
    ];
    
    return commonNames.where((name) => 
      name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // إحصائيات البحث
  Map<String, dynamic> getSearchStatistics() {
    List<String> recentSearches = getRecentSearches();
    
    return {
      'totalSearches': recentSearches.length,
      'lastSearch': recentSearches.isNotEmpty ? recentSearches.first : null,
      'mostSearchedTerms': _getMostSearchedTerms(recentSearches),
      'searchTypes': _analyzeSearchTypes(recentSearches)
    };
  }

  // تحليل المصطلحات الأكثر بحثاً
  List<String> _getMostSearchedTerms(List<String> searches) {
    Map<String, int> termCounts = {};
    
    for (String search in searches) {
      List<String> terms = search.split(' ');
      for (String term in terms) {
        termCounts[term] = (termCounts[term] ?? 0) + 1;
      }
    }
    
    // ترتيب حسب العدد
    List<MapEntry<String, int>> sorted = termCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((entry) => entry.key).toList();
  }

  // تحليل أنواع البحث
  Map<String, int> _analyzeSearchTypes(List<String> searches) {
    Map<String, int> typeCounts = {
      'اسم': 0,
      'موقع': 0,
      'تاريخ': 0,
      'حالة': 0,
      'أخرى': 0
    };
    
    for (String search in searches) {
      if (search.contains(AppConstants.yemenGovernorates.toString())) {
        typeCounts['موقع'] = (typeCounts['موقع'] ?? 0) + 1;
      } else if (search.contains(RegExp(r'\d{4}-\d{2}-\d{2}'))) {
        typeCounts['تاريخ'] = (typeCounts['تاريخ'] ?? 0) + 1;
      } else if (search.contains('قيد المراجعة') || search.contains('تم التوثيق')) {
        typeCounts['حالة'] = (typeCounts['حالة'] ?? 0) + 1;
      } else if (search.contains(' ') && search.split(' ').length > 1) {
        typeCounts['اسم'] = (typeCounts['اسم'] ?? 0) + 1;
      } else {
        typeCounts['أخرى'] = (typeCounts['أخرى'] ?? 0) + 1;
      }
    }
    
    return typeCounts;
  }
}

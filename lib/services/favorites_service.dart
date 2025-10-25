import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  late SharedPreferences _prefs;

  // تهيئة الخدمة
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // إضافة عنصر للمفضلة
  Future<bool> addToFavorites(String type, String id) async {
    try {
      List<String> favorites = _prefs.getStringList(_getFavoritesKey(type)) ?? [];
      
      if (!favorites.contains(id)) {
        favorites.add(id);
        await _prefs.setStringList(_getFavoritesKey(type), favorites);
        return true;
      }
      return false; // موجود مسبقاً
    } catch (e) {
      print('خطأ في إضافة المفضلة: $e');
      return false;
    }
  }

  // إزالة عنصر من المفضلة
  Future<bool> removeFromFavorites(String type, String id) async {
    try {
      List<String> favorites = _prefs.getStringList(_getFavoritesKey(type)) ?? [];
      
      if (favorites.contains(id)) {
        favorites.remove(id);
        await _prefs.setStringList(_getFavoritesKey(type), favorites);
        return true;
      }
      return false; // غير موجود
    } catch (e) {
      print('خطأ في حذف المفضلة: $e');
      return false;
    }
  }

  // التحقق من كون العنصر في المفضلة
  bool isFavorite(String type, String id) {
    List<String> favorites = _prefs.getStringList(_getFavoritesKey(type)) ?? [];
    return favorites.contains(id);
  }

  // الحصول على جميع المفضلة لنوع معين
  List<String> getFavorites(String type) {
    return _prefs.getStringList(_getFavoritesKey(type)) ?? [];
  }

  // الحصول على عدد المفضلة لكل نوع
  Map<String, int> getFavoritesCount() {
    return {
      'martyrs': getFavorites('martyrs').length,
      'injured': getFavorites('injured').length,
      'prisoners': getFavorites('prisoners').length,
    };
  }

  // مسح جميع المفضلة
  Future<void> clearAllFavorites() async {
    try {
      await _prefs.remove(AppConstants.keyFavoriteMartyrs);
      await _prefs.remove(AppConstants.keyFavoriteInjured);
      await _prefs.remove(AppConstants.keyFavoritePrisoners);
    } catch (e) {
      print('خطأ في مسح المفضلة: $e');
    }
  }

  // مسح مفضلة نوع معين
  Future<void> clearFavorites(String type) async {
    try {
      await _prefs.remove(_getFavoritesKey(type));
    } catch (e) {
      print('خطأ في مسح المفضلة: $e');
    }
  }

  // البحث في المفضلة
  List<String> searchInFavorites(String query, String type) {
    // هذا مجرد مثال، في التطبيق الحقيقي ستحتاج لقاعدة بيانات
    List<String> favorites = getFavorites(type);
    return favorites.where((id) => 
      id.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // الحصول على مفاتيح المفضلة
  String _getFavoritesKey(String type) {
    switch (type.toLowerCase()) {
      case 'martyrs':
        return AppConstants.keyFavoriteMartyrs;
      case 'injured':
        return AppConstants.keyFavoriteInjured;
      case 'prisoners':
        return AppConstants.keyFavoritePrisoners;
      default:
        throw ArgumentError('نوع المفضلة غير مدعوم: $type');
    }
  }

  // إحصائيات المفضلة
  Map<String, dynamic> getFavoritesStatistics() {
    final counts = getFavoritesCount();
    return {
      'total': counts.values.reduce((a, b) => a + b),
      'martyrs': counts['martyrs'] ?? 0,
      'injured': counts['injured'] ?? 0,
      'prisoners': counts['prisoners'] ?? 0,
      'hasFavorites': (counts.values.reduce((a, b) => a + b) > 0)
    };
  }
}
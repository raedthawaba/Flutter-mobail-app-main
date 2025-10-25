import '../services/api_service.dart';
import '../models/user.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';

class ApiRepository {
  final ApiService _apiService;
  
  ApiRepository(this._apiService);
  
  // ===== AUTH REPOSITORY =====
  
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      return User.fromMap(response['user']);
    } catch (e) {
      throw Exception('فشل في تسجيل الدخول: $e');
    }
  }
  
  Future<User> register({
    required String username,
    required String password,
    required String fullName,
    required String userType,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiService.register(
        username: username,
        password: password,
        fullName: fullName,
        userType: userType,
        phoneNumber: phoneNumber,
      );
      return User.fromMap(response);
    } catch (e) {
      throw Exception('فشل في إنشاء الحساب: $e');
    }
  }
  
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      return User.fromMap(response);
    } catch (e) {
      throw Exception('فشل في جلب بيانات المستخدم: $e');
    }
  }
  
  Future<void> logout() async {
    await _apiService.logout();
  }
  
  bool get isAuthenticated => _apiService.isAuthenticated;
  
  // ===== MARTYRS REPOSITORY =====
  
  Future<List<Martyr>> getMartyrs({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final response = await _apiService.getMartyrs(
        skip: skip,
        limit: limit,
        status: status,
      );
      
      return response.map((data) => Martyr.fromMap(data)).toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات الشهداء: $e');
    }
  }
  
  Future<Martyr> createMartyr(Martyr martyr) async {
    try {
      final martyrData = martyr.toMap();
      // Convert DateTime objects to ISO strings
      martyrData['birth_date'] = martyr.birthDate?.toIso8601String();
      martyrData['death_date'] = martyr.deathDate.toIso8601String();
      martyrData['created_at'] = martyr.createdAt.toIso8601String();
      
      // Remove fields that shouldn't be sent to API
      martyrData.remove('id');
      martyrData.remove('added_by_user_id');
      martyrData.remove('updated_at');
      
      final response = await _apiService.createMartyr(martyrData);
      return Martyr.fromMap(response);
    } catch (e) {
      throw Exception('فشل في إضافة الشهيد: $e');
    }
  }
  
  // ===== INJURED REPOSITORY =====
  
  Future<List<Injured>> getInjured({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final response = await _apiService.getInjured(
        skip: skip,
        limit: limit,
        status: status,
      );
      
      return response.map((data) => Injured.fromMap(data)).toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات الجرحى: $e');
    }
  }
  
  Future<Injured> createInjured(Injured injured) async {
    try {
      final injuredData = injured.toMap();
      // Convert DateTime objects to ISO strings
      injuredData['injury_date'] = injured.injuryDate.toIso8601String();
      injuredData['created_at'] = injured.createdAt.toIso8601String();
      
      // Remove fields that shouldn't be sent to API
      injuredData.remove('id');
      injuredData.remove('added_by_user_id');
      injuredData.remove('updated_at');
      
      final response = await _apiService.createInjured(injuredData);
      return Injured.fromMap(response);
    } catch (e) {
      throw Exception('فشل في إضافة الجريح: $e');
    }
  }
  
  // ===== PRISONERS REPOSITORY =====
  
  Future<List<Prisoner>> getPrisoners({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final response = await _apiService.getPrisoners(
        skip: skip,
        limit: limit,
        status: status,
      );
      
      return response.map((data) => Prisoner.fromMap(data)).toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات الأسرى: $e');
    }
  }
  
  Future<Prisoner> createPrisoner(Prisoner prisoner) async {
    try {
      final prisonerData = prisoner.toMap();
      // Convert DateTime objects to ISO strings
      prisonerData['capture_date'] = prisoner.captureDate.toIso8601String();
      prisonerData['release_date'] = prisoner.releaseDate?.toIso8601String();
      prisonerData['created_at'] = prisoner.createdAt.toIso8601String();
      
      // Remove fields that shouldn't be sent to API
      prisonerData.remove('id');
      prisonerData.remove('added_by_user_id');
      prisonerData.remove('updated_at');
      
      final response = await _apiService.createPrisoner(prisonerData);
      return Prisoner.fromMap(response);
    } catch (e) {
      throw Exception('فشل في إضافة الأسير: $e');
    }
  }
  
  // ===== FILE UPLOAD REPOSITORY =====
  
  Future<String> uploadPhoto(String filePath) async {
    try {
      final response = await _apiService.uploadPhoto(filePath);
      return response['file_path'] as String;
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }
  
  Future<String> uploadDocument(String filePath) async {
    try {
      final response = await _apiService.uploadDocument(filePath);
      return response['file_path'] as String;
    } catch (e) {
      throw Exception('فشل في رفع الوثيقة: $e');
    }
  }
  
  // ===== ADMIN REPOSITORY =====
  
  Future<Map<String, int>> getStatistics() async {
    try {
      final response = await _apiService.getStatistics();
      return {
        'martyrs': response['total_martyrs'] as int,
        'injured': response['total_injured'] as int,
        'prisoners': response['total_prisoners'] as int,
        'pending': (response['pending_martyrs'] as int) +
                   (response['pending_injured'] as int) +
                   (response['pending_prisoners'] as int),
      };
    } catch (e) {
      throw Exception('فشل في جلب الإحصائيات: $e');
    }
  }
  
  Future<List<User>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.getUsers(
        skip: skip,
        limit: limit,
      );
      
      return response.map((data) => User.fromMap(data)).toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات المستخدمين: $e');
    }
  }
  
  // ===== CONNECTIVITY REPOSITORY =====
  
  Future<bool> checkServerHealth() async {
    try {
      await _apiService.healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // ===== UTILITY METHODS =====
  
  void setBaseUrl(String url) {
    _apiService.setBaseUrl(url);
  }
  
  void enableLogging() {
    _apiService.setLogging(true);
  }
  
  void disableLogging() {
    _apiService.setLogging(false);
  }
}
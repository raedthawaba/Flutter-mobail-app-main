import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';

class ApiService {
  static const String baseUrl = 'https://your-backend-url.railway.app'; // سيتم تحديثه لاحقاً
  static const String localUrl = 'http://localhost:8000'; // للتطوير
  
  late Dio _dio;
  String? _token;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
    _loadToken();
  }
  
  void _setupInterceptors() {
    // Request interceptor - add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        print('🚀 API Request: ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.requestOptions.uri} - ${error.message}');
        handler.next(error);
      },
    ));
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }
  
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }
  
  // ===== AUTH METHODS =====
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['access_token'];
      await _saveToken(token);
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String userType,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'full_name': fullName,
        'user_type': userType,
        'phone_number': phoneNumber,
      });
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    await _clearToken();
  }
  
  // ===== MARTYRS METHODS =====
  
  Future<List<Map<String, dynamic>>> getMartyrs({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get('/martyrs', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createMartyr(Map<String, dynamic> martyrData) async {
    try {
      final response = await _dio.post('/martyrs', data: martyrData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== INJURED METHODS =====
  
  Future<List<Map<String, dynamic>>> getInjured({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get('/injured', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createInjured(Map<String, dynamic> injuredData) async {
    try {
      final response = await _dio.post('/injured', data: injuredData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== PRISONERS METHODS =====
  
  Future<List<Map<String, dynamic>>> getPrisoners({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get('/prisoners', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createPrisoner(Map<String, dynamic> prisonerData) async {
    try {
      final response = await _dio.post('/prisoners', data: prisonerData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== FILE UPLOAD METHODS =====
  
  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/upload/photo', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> uploadDocument(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/upload/document', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== ADMIN METHODS =====
  
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _dio.get('/admin/stats');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/admin/users', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== HEALTH CHECK =====
  
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ===== ERROR HANDLING =====
  
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انقطع الاتصال بالخادم. تحقق من اتصال الإنترنت.';
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        
        if (statusCode == 401) {
          return 'غير مخول بالوصول. تحقق من بيانات الدخول.';
        } else if (statusCode == 403) {
          return 'ليس لديك صلاحية للقيام بهذا الإجراء.';
        } else if (statusCode == 404) {
          return 'البيانات المطلوبة غير موجودة.';
        } else if (statusCode == 422) {
          if (errorData is Map && errorData.containsKey('detail')) {
            return 'خطأ في البيانات: ${errorData['detail']}';
          }
          return 'خطأ في تنسيق البيانات المرسلة.';
        } else if (statusCode == 500) {
          return 'خطأ في الخادم. حاول مرة أخرى لاحقاً.';
        }
        
        if (errorData is Map && errorData.containsKey('detail')) {
          return errorData['detail'].toString();
        }
        
        return 'حدث خطأ في الخادم (${statusCode ?? 'غير معروف'}).';
      
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب.';
      
      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('SocketException') == true) {
          return 'لا يمكن الاتصال بالخادم. تحقق من اتصال الإنترنت.';
        }
        return 'حدث خطأ غير متوقع: ${e.message ?? 'خطأ غير معروف'}';
    }
  }
  
  // ===== UTILITY METHODS =====
  
  bool get isAuthenticated => _token != null;
  
  String? get token => _token;
  
  // لتغيير الـ base URL (مفيد للتنوع بين التطوير والإنتاج)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
  
  // لتفعيل/إلغاء تفعيل طباعة الـ logs
  void setLogging(bool enabled) {
    if (enabled) {
      if (!_dio.interceptors.any((i) => i is LogInterceptor)) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ));
      }
    } else {
      _dio.interceptors.removeWhere((i) => i is LogInterceptor);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'user_dashboard_screen.dart';
import 'debug_error_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // تخزين الـ debug logs
  final List<String> _debugLogs = [];
  
  void _addLog(String message) {
    _debugLogs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    print(message);
  }

  @override
  void initState() {
    super.initState();
    _addLog('=== SplashScreen: initState started ===');
    try {
      _initAnimations();
      _addLog('✓ Animations initialized');
      _cleanAndCheckAuth().catchError((error, stackTrace) {
        _addLog('❌ FATAL ERROR in _cleanAndCheckAuth');
        _addLog('Error: $error');
        if (mounted) {
          _showErrorScreen(error.toString(), stackTrace.toString());
        }
      });
    } catch (e, stackTrace) {
      _addLog('❌ FATAL ERROR in initState');
      _addLog('Error: $e');
      if (mounted) {
        _showErrorScreen(e.toString(), stackTrace.toString());
      }
    }
  }

  // عرض شاشة خطأ واضحة
  void _showErrorScreen(String error, [String stackTrace = '']) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DebugErrorScreen(
          errorMessage: error,
          stackTrace: stackTrace,
          debugLogs: _debugLogs,
        ),
      ),
    );
  }

  // تنظيف البيانات القديمة وفحص حالة المصادقة
  Future<void> _cleanAndCheckAuth() async {
    try {
      _addLog('=== Step 1: Cleaning old data ===');
      try {
        final prefs = await SharedPreferences.getInstance();
        final keysToCheck = ['user_role', 'role'];
        for (var key in keysToCheck) {
          if (prefs.containsKey(key)) {
            _addLog('Removing old key: $key');
            await prefs.remove(key);
          }
        }
        _addLog('✓ Old data cleaned successfully');
      } catch (e, st) {
        _addLog('⚠ Error cleaning old data: $e');
        // نستمر حتى لو فشل التنظيف
      }
      
      _addLog('=== Step 2: Checking auth status ===');
      await _checkAuthStatus();
      _addLog('✓ Auth check completed');
    } catch (e, stackTrace) {
      _addLog('❌ FATAL ERROR in _cleanAndCheckAuth');
      _addLog('Error: $e');
      if (mounted) {
        _showErrorScreen(e.toString(), stackTrace.toString());
      }
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _addLog('=== Auth Check: Starting ===');
      
      // انتظار لمدة ثانيتين لعرض شاشة البداية
      _addLog('Waiting 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));
      _addLog('✓ Wait completed');

      if (!mounted) {
        _addLog('⚠ Widget not mounted, returning');
        return;
      }

      _addLog('Calling isLoggedIn...');
      final bool isLoggedIn = await _authService.isLoggedIn().catchError((error) {
        _addLog('❌ ERROR in isLoggedIn: $error');
        return false;
      });
      _addLog('✓ isLoggedIn = $isLoggedIn');
      
      if (!mounted) {
        _addLog('⚠ Widget not mounted after isLoggedIn');
        return;
      }

      if (isLoggedIn) {
        _addLog('User is logged in, checking admin status...');
        
        final bool isAdmin = await _authService.isAdmin().catchError((error) {
          _addLog('❌ ERROR in isAdmin: $error');
          return false;
        });
        _addLog('✓ isAdmin = $isAdmin');
        
        // للتحقق: طباعة بيانات المستخدم الحالي
        try {
          final currentUser = await _authService.getCurrentUser();
          if (currentUser != null) {
            _addLog('✓ User email = ${currentUser.email}');
            _addLog('✓ User userType = ${currentUser.userType}');
          } else {
            _addLog('⚠ getCurrentUser returned null!');
          }
        } catch (e) {
          _addLog('❌ ERROR getting current user: $e');
        }
        
        if (!mounted) {
          _addLog('⚠ Widget not mounted after getting user info');
          return;
        }
        
        // توجيه المستخدم حسب نوعه
        if (isAdmin) {
          _addLog('✓ Navigating to Admin Dashboard');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          _addLog('✓ Navigating to User Dashboard');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
          );
        }
      } else {
        _addLog('✓ User not logged in, navigating to Login');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      
      _addLog('✓ Navigation completed successfully');
    } catch (e, stackTrace) {
      _addLog('❌ FATAL ERROR in _checkAuthStatus');
      _addLog('Error: $e');
      // في حالة حدوث خطأ، عرض شاشة خطأ
      if (mounted) {
        _showErrorScreen(e.toString(), stackTrace.toString());
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.freedomGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // شعار التطبيق
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlack.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.people_outline,
                          size: 60,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // اسم التطبيق
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryWhite,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryBlack,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // وصف مختصر
                      Text(
                        'منصة توثيق الشهداء والجرحى والأسرى',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite.withOpacity(0.9),
                          shadows: const [
                            Shadow(
                              color: AppColors.primaryBlack,
                              blurRadius: 5,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // مؤشر التحميل
                      const SpinKitWave(
                        color: AppColors.primaryWhite,
                        size: 40,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryWhite.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

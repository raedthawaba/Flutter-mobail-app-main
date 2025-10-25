import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'user_dashboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    print('=== SplashScreen: initState started ===');
    try {
      _initAnimations();
      print('=== SplashScreen: Animations initialized ===');
      _cleanAndCheckAuth().catchError((error, stackTrace) {
        print('=== FATAL ERROR in _cleanAndCheckAuth ===');
        print('Error: $error');
        print('StackTrace: $stackTrace');
        // عرض شاشة خطأ
        if (mounted) {
          _showErrorScreen(error.toString());
        }
      });
    } catch (e, stackTrace) {
      print('=== FATAL ERROR in initState ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        _showErrorScreen(e.toString());
      }
    }
  }

  // عرض شاشة خطأ واضحة
  void _showErrorScreen(String error) {
    setState(() {
      // سنعرض رسالة خطأ في البناء
    });
    // بعد 3 ثواني، ننتقل لشاشة تسجيل الدخول
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  // تنظيف البيانات القديمة وفحص حالة المصادقة
  Future<void> _cleanAndCheckAuth() async {
    try {
      print('=== Step 1: Cleaning old data ===');
      try {
        final prefs = await SharedPreferences.getInstance();
        final keysToCheck = ['user_role', 'role'];
        for (var key in keysToCheck) {
          if (prefs.containsKey(key)) {
            print('Removing old key: $key');
            await prefs.remove(key);
          }
        }
        print('✓ Old data cleaned successfully');
      } catch (e, st) {
        print('⚠ Error cleaning old data: $e');
        print('StackTrace: $st');
        // نستمر حتى لو فشل التنظيف
      }
      
      print('=== Step 2: Checking auth status ===');
      await _checkAuthStatus();
      print('=== Step 3: Auth check completed ===');
    } catch (e, stackTrace) {
      print('=== FATAL ERROR in _cleanAndCheckAuth ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        _showErrorScreen(e.toString());
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
      print('=== Auth Check: Starting ===');
      
      // انتظار لمدة ثانيتين لعرض شاشة البداية
      print('=== Auth Check: Waiting 2 seconds ===');
      await Future.delayed(const Duration(seconds: 2));
      print('=== Auth Check: Wait completed ===');

      if (!mounted) {
        print('=== Auth Check: Widget not mounted, returning ===');
        return;
      }

      print('=== Auth Check: Calling isLoggedIn ===');
      print('=== Auth Check: Calling isLoggedIn ===');
      final bool isLoggedIn = await _authService.isLoggedIn().catchError((error) {
        print('ERROR in isLoggedIn: $error');
        return false;
      });
      print('✓ Auth Check: isLoggedIn = $isLoggedIn');
      
      if (!mounted) {
        print('=== Auth Check: Widget not mounted after isLoggedIn, returning ===');
        return;
      }

      if (isLoggedIn) {
        print('=== Auth Check: User is logged in, checking admin status ===');
        
        final bool isAdmin = await _authService.isAdmin().catchError((error) {
          print('ERROR in isAdmin: $error');
          return false;
        });
        print('✓ Auth Check: isAdmin = $isAdmin');
        
        // للتحقق: طباعة بيانات المستخدم الحالي
        try {
          final currentUser = await _authService.getCurrentUser();
          if (currentUser != null) {
            print('✓ Auth Check: User email = ${currentUser.email}');
            print('✓ Auth Check: User userType = ${currentUser.userType}');
          } else {
            print('⚠ Auth Check: getCurrentUser returned null!');
          }
        } catch (e) {
          print('ERROR getting current user: $e');
        }
        
        if (!mounted) {
          print('=== Auth Check: Widget not mounted after getting user info, returning ===');
          return;
        }
        
        // توجيه المستخدم حسب نوعه
        if (isAdmin) {
          print('=== Auth Check: Navigating to Admin Dashboard ===');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          print('=== Auth Check: Navigating to User Dashboard ===');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
          );
        }
      } else {
        print('=== Auth Check: User not logged in, navigating to Login Screen ===');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      
      print('=== Auth Check: Navigation completed successfully ===');
    } catch (e, stackTrace) {
      print('=== FATAL ERROR in _checkAuthStatus ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      // في حالة حدوث خطأ، عرض شاشة خطأ
      if (mounted) {
        _showErrorScreen(e.toString());
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
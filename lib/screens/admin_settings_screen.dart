import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'admin_account_settings_screen.dart';
import 'app_settings_screen.dart';
import 'admin_data_management_screen.dart';
import 'login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthService _authService = AuthService();
  String? _adminName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final adminName = await _authService.getCurrentUserName();
      if (mounted) {
        setState(() {
          _adminName = adminName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.primaryWhite,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateToAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminAccountSettingsScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            const Text('حول التطبيق'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تطبيق توثيق الشهداء والجرحى والأسرى',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('الإصدار: 1.0.0'),
            SizedBox(height: 4),
            Text('تاريخ البناء: 2025-10-20'),
            SizedBox(height: 8),
            Text(
              'تم تطوير هذا التطبيق لتوثيق وإدارة بيانات الشهداء والجرحى والأسرى.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryWhite,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          color: color,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.05),
                    AppColors.primaryWhite,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة معلومات المسؤول
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: AppColors.primaryWhite.withOpacity(0.2),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 40,
                                color: AppColors.primaryWhite,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _adminName ?? 'المسؤول العام',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'مسؤول النظام',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryWhite.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // عنوان قسم إعدادات الحساب
                      Text(
                        'إعدادات الحساب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // إعدادات الحساب
                      _buildSettingCard(
                        title: 'إدارة الحساب',
                        subtitle: 'تغيير بيانات الحساب وكلمة المرور',
                        icon: Icons.account_circle,
                        color: AppColors.primaryGreen,
                        onTap: _navigateToAccountSettings,
                      ),

                      const SizedBox(height: 20),

                      // عنوان قسم إعدادات التطبيق
                      Text(
                        'إعدادات التطبيق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // إعدادات عامة
                      _buildSettingCard(
                        title: 'إعدادات التطبيق',
                        subtitle: 'الإشعارات، النسخ الاحتياطي، الأمان',
                        icon: Icons.settings,
                        color: AppColors.info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppSettingsScreen(),
                            ),
                          );
                        },
                      ),

                      _buildSettingCard(
                        title: 'إدارة البيانات',
                        subtitle: 'إضافة بيانات تجريبية للأقسام الثلاثة',
                        icon: Icons.storage,
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDataManagementScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // عنوان قسم معلومات وخروج
                      Text(
                        'معلومات وخروج',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // معلومات وخروج
                      _buildSettingCard(
                        title: 'حول التطبيق',
                        subtitle: 'معلومات التطبيق والإصدار',
                        icon: Icons.info_outline,
                        color: AppColors.info,
                        onTap: _showAboutDialog,
                      ),

                      _buildSettingCard(
                        title: 'تسجيل الخروج',
                        subtitle: 'خروج من التطبيق',
                        icon: Icons.logout,
                        color: AppColors.error,
                        onTap: _logout,
                      ),

                      const SizedBox(height: 20),

                      // معلومات أسفل الصفحة
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'تطبيق توثيق الشهداء والجرحى والأسرى',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الإصدار 1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

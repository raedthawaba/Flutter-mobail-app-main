import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/info_card.dart';
import '../services/backup_service.dart';
import '../services/theme_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final BackupService _backupService = BackupService();
  final ThemeService _themeService = ThemeService();
  
  bool _notificationsEnabled = true;
  bool _dailyNotifications = true;
  bool _weeklyNotifications = true;
  bool _securityNotifications = true;
  bool _autoBackup = false;
  String _backupFrequency = 'أسبوعياً';
  bool _biometricAuth = false;
  bool _appLock = false;
  String _appTheme = 'النظام';
  String _language = 'العربية';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _dailyNotifications = prefs.getBool('daily_notifications') ?? true;
      _weeklyNotifications = prefs.getBool('weekly_notifications') ?? true;
      _securityNotifications = prefs.getBool('security_notifications') ?? true;
      _autoBackup = prefs.getBool('auto_backup') ?? false;
      _backupFrequency = prefs.getString('backup_frequency') ?? 'أسبوعياً';
      _biometricAuth = prefs.getBool('biometric_auth') ?? false;
      _appLock = prefs.getBool('app_lock') ?? false;
      _appTheme = prefs.getString('app_theme') ?? 'النظام';
      _language = prefs.getString('language') ?? 'العربية';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _createBackup() async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'إنشاء نسخة احتياطية',
      content: 'هل تريد إنشاء نسخة احتياطية من بيانات التطبيق الآن؟',
      confirmText: 'إنشاء',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      // عرض مربع حوار التقدم
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              const Text('جاري إنشاء النسخة الاحتياطية...'),
            ],
          ),
        ),
      );

      try {
        // إنشاء النسخة الاحتياطية فعلياً
        await _backupService.createBackup();

        if (mounted) {
          Navigator.pop(context); // إغلاق مربع حوار التقدم
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إنشاء النسخة الاحتياطية بنجاح وحفظها في السحابة'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // إغلاق مربع حوار التقدم
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      // جلب قائمة النسخ الاحتياطية
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              const Text('جاري تحميل النسخ الاحتياطية...'),
            ],
          ),
        ),
      );

      final backups = await _backupService.getBackupsList();
      
      if (mounted) {
        Navigator.pop(context); // إغلاق مربع حوار التقدم
        
        if (backups.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد نسخ احتياطية متاحة'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        // عرض قائمة بالنسخ الاحتياطية
        final selectedBackup = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('اختر نسخة احتياطية'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  final date = DateTime.parse(backup['created_at']);
                  final stats = backup['statistics'] ?? {};
                  
                  return ListTile(
                    title: Text('نسخة ${date.day}/${date.month}/${date.year}'),
                    subtitle: Text(
                      'شهداء: ${stats['martyrs_count'] ?? 0} | '
                      'جرحى: ${stats['injured_count'] ?? 0} | '
                      'أسرى: ${stats['prisoners_count'] ?? 0}'
                    ),
                    leading: const Icon(Icons.backup, color: AppColors.info),
                    onTap: () => Navigator.pop(context, backup['id']),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );

        if (selectedBackup != null) {
          final confirmed = await CustomDialogs.showConfirmationDialog(
            context: context,
            title: 'استعادة النسخة الاحتياطية',
            content: 'هل تريد استعادة البيانات من النسخة الاحتياطية؟\n\nتحذير: سيتم استبدال البيانات الحالية!',
            confirmText: 'استعادة',
            cancelText: 'إلغاء',
            isDestructive: true,
          );

          if (confirmed == true) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryGreen),
                    const SizedBox(height: 16),
                    const Text('جاري استعادة البيانات...'),
                  ],
                ),
              ),
            );

            try {
              await _backupService.restoreBackup(selectedBackup);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم استعادة البيانات بنجاح'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ في استعادة البيانات: $e'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'إعادة تعيين الإعدادات',
      content: 'هل تريد إعادة تعيين جميع الإعدادات إلى القيم الافتراضية؟',
      confirmText: 'إعادة تعيين',
      cancelText: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      // حذف جميع الإعدادات
      await prefs.remove('notifications_enabled');
      await prefs.remove('daily_notifications');
      await prefs.remove('weekly_notifications');
      await prefs.remove('security_notifications');
      await prefs.remove('auto_backup');
      await prefs.remove('backup_frequency');
      await prefs.remove('biometric_auth');
      await prefs.remove('app_lock');
      await prefs.remove('app_theme');
      await prefs.remove('language');

      // إعادة تحميل الإعدادات
      _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تعيين الإعدادات بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعدادات التطبيق',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        actions: [
          IconButton(
            onPressed: _resetSettings,
            icon: const Icon(Icons.restore),
            tooltip: 'إعادة تعيين الإعدادات',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الإشعارات
          _buildSectionCard(
            title: 'الإشعارات',
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                subtitle: const Text('تفعيل/إلغاء جميع الإشعارات'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications_enabled', value);
                },
                activeColor: AppColors.primaryGreen,
              ),
              if (_notificationsEnabled) ...[
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('الإشعارات اليومية'),
                  subtitle: const Text('تذكير يومي بالتطبيق'),
                  value: _dailyNotifications,
                  onChanged: (value) {
                    setState(() => _dailyNotifications = value);
                    _saveSetting('daily_notifications', value);
                  },
                  activeColor: AppColors.primaryGreen,
                ),
                SwitchListTile(
                  title: const Text('الإشعارات الأسبوعية'),
                  subtitle: const Text('ملخص أسبوعي للأنشطة'),
                  value: _weeklyNotifications,
                  onChanged: (value) {
                    setState(() => _weeklyNotifications = value);
                    _saveSetting('weekly_notifications', value);
                  },
                  activeColor: AppColors.primaryGreen,
                ),
                SwitchListTile(
                  title: const Text('إشعارات الأمان'),
                  subtitle: const Text('تنبيهات عند تسجيل الدخول'),
                  value: _securityNotifications,
                  onChanged: (value) {
                    setState(() => _securityNotifications = value);
                    _saveSetting('security_notifications', value);
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // قسم النسخ الاحتياطي
          _buildSectionCard(
            title: 'النسخ الاحتياطي',
            icon: Icons.backup,
            children: [
              SwitchListTile(
                title: const Text('النسخ الاحتياطي التلقائي'),
                subtitle: const Text('إنشاء نسخ احتياطية تلقائياً'),
                value: _autoBackup,
                onChanged: (value) {
                  setState(() => _autoBackup = value);
                  _saveSetting('auto_backup', value);
                },
                activeColor: AppColors.primaryGreen,
              ),
              if (_autoBackup) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('تكرار النسخ الاحتياطي'),
                  subtitle: Text(_backupFrequency),
                  trailing: DropdownButton<String>(
                    value: _backupFrequency,
                    onChanged: (value) {
                      setState(() => _backupFrequency = value!);
                      _saveSetting('backup_frequency', value);
                    },
                    items: ['يومياً', 'أسبوعياً', 'شهرياً']
                        .map((freq) => DropdownMenuItem(
                              value: freq,
                              child: Text(freq),
                            ))
                        .toList(),
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                title: const Text('إنشاء نسخة احتياطية الآن'),
                subtitle: const Text('حفظ نسخة من البيانات الحالية'),
                leading: const Icon(Icons.cloud_upload, color: AppColors.info),
                onTap: _createBackup,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('استعادة من النسخة الاحتياطية'),
                subtitle: const Text('استعادة البيانات المحفوظة'),
                leading: const Icon(Icons.cloud_download, color: AppColors.warning),
                onTap: _restoreBackup,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم الأمان
          _buildSectionCard(
            title: 'الأمان',
            icon: Icons.security,
            children: [
              SwitchListTile(
                title: const Text('المصادقة البيومترية'),
                subtitle: const Text('البصمة أو التعرف على الوجه'),
                value: _biometricAuth,
                onChanged: (value) {
                  setState(() => _biometricAuth = value);
                  _saveSetting('biometric_auth', value);
                },
                activeColor: AppColors.primaryGreen,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('قفل التطبيق'),
                subtitle: const Text('طلب كلمة مرور عند فتح التطبيق'),
                value: _appLock,
                onChanged: (value) {
                  setState(() => _appLock = value);
                  _saveSetting('app_lock', value);
                },
                activeColor: AppColors.primaryGreen,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('تغيير كلمة المرور'),
                subtitle: const Text('تحديث كلمة مرور الحساب'),
                leading: const Icon(Icons.lock_reset, color: AppColors.warning),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('هذه الميزة ستكون متاحة قريباً'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // قسم المظهر واللغة
          _buildSectionCard(
            title: 'المظهر واللغة',
            icon: Icons.palette,
            children: [
              ListTile(
                title: const Text('سمة التطبيق'),
                subtitle: Text(_appTheme),
                trailing: DropdownButton<String>(
                  value: _appTheme,
                  onChanged: (value) async {
                    setState(() => _appTheme = value!);
                    await _saveSetting('app_theme', value);
                    // تحديث المظهر فوراً
                    await _themeService.saveThemeMode(value!);
                  },
                  items: ['فاتح', 'داكن', 'النظام']
                      .map((theme) => DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          ))
                      .toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('لغة التطبيق'),
                subtitle: Text(_language),
                trailing: DropdownButton<String>(
                  value: _language,
                  onChanged: (value) async {
                    setState(() => _language = value!);
                    await _saveSetting('language', value);
                    // تحديث اللغة فوراً
                    await _themeService.saveLanguage(value!);
                  },
                  items: ['العربية', 'English']
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // معلومات التطبيق
          _buildSectionCard(
            title: 'معلومات التطبيق',
            icon: Icons.info,
            children: [
              const InfoCard(title: 'اسم التطبيق', value: 'توثيق الشهداء والجرحى والأسرى'),
              const InfoCard(title: 'الإصدار', value: '1.0.0'),
              const InfoCard(title: 'آخر تحديث', value: '2025/10/20'),
              ListTile(
                title: const Text('الترخيص والخصوصية'),
                subtitle: const Text('اطلع على سياسة الخصوصية'),
                leading: const Icon(Icons.privacy_tip, color: AppColors.info),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ستفتح صفحة سياسة الخصوصية'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
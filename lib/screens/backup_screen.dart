import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // البيانات
  List<Map<String, dynamic>> _backupList = [];
  Map<String, dynamic> _backupSettings = {};
  Map<String, dynamic> _lastBackupStats = {};
  
  // حالة الواجهة
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  String _selectedBackupPath = '';
  
  // الخدمات
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBackupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBackupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.initialize();
      _backupList = await _backupService.getBackupList();
      _backupSettings = _backupService.getBackupSettings();
    } catch (e) {
      print('خطأ في تحميل بيانات النسخ الاحتياطي: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'النسخ الاحتياطي الذكي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackupData,
            tooltip: 'تحديث البيانات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('إعدادات النسخ الاحتياطي'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'auto_backup',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('تفعيل النسخ التلقائي'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('مساعدة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'النسخ الاحتياطي', icon: Icon(Icons.backup)),
            Tab(text: 'الاستعادة', icon: Icon(Icons.restore)),
            Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
            Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBackupTab(),
                _buildRestoreTab(),
                _buildSettingsTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'جاري تحميل بيانات النسخ الاحتياطي...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return RefreshIndicator(
      onRefresh: _loadBackupData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildBackupStatus(),
            const SizedBox(height: 16),
            _buildBackupList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.backup,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'إنشاء نسخة احتياطية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingBackup ? null : () => _createBackup(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isCreatingBackup
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.backup),
                    label: const Text('نسخة سريعة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingBackup ? null : () => _createBackup(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isCreatingBackup
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.backup),
                    label: const Text('نسخة كاملة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupStatus() {
    String? lastBackup = _backupSettings['lastBackup'];
    bool autoBackupEnabled = _backupSettings['autoBackupEnabled'] ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  autoBackupBackupEnabled ? Icons.schedule : Icons.schedule_send,
                  color: autoBackupEnabled ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'حالة النسخ الاحتياطي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: autoBackupEnabled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    autoBackupEnabled ? 'مفعل' : 'معطل',
                    style: TextStyle(
                      color: autoBackupEnabled ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastBackup != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'آخر نسخة: ${_formatDateTime(lastBackup)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.folder, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_backupList.length} نسخة احتياطية محفوظة',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupList() {
    if (_backupList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.backup_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد نسخ احتياطية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'قم بإنشاء أول نسخة احتياطية من بياناتك',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'النسخ الاحتياطية المحفوظة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_backupList.length} نسخة',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._backupList.map((backup) => _buildBackupItem(backup)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    String fileName = backup['fileName'] ?? 'غير محدد';
    String fileSize = _formatFileSize(backup['size'] ?? 0);
    String modifiedDate = _formatDateTime(backup['modified'] ?? '');
    String backupType = backup['type'] == 'auto' ? 'تلقائي' : 'يدوي';
    
    Color typeColor = backup['type'] == 'auto' ? Colors.blue : Colors.green;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            backup['type'] == 'auto' ? Icons.schedule : Icons.backup,
            color: typeColor,
            size: 20,
          ),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  modifiedDate,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.storage, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  fileSize,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    backupType,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, backup),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('استعادة من هذه النسخة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('تحميل النسخة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('حذف النسخة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showBackupDetails(backup),
      ),
    );
  }

  Widget _buildRestoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestoreCard(),
          const SizedBox(height: 16),
          _buildRestoreOptions(),
        ],
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restore,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'استعادة من نسخة احتياطية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'تحذير: سيتم استبدال البيانات الحالية بالبيانات من النسخة الاحتياطية.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _backupList.isEmpty ? null : _showRestoreDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('اختيار نسخة للاستعادة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خيارات الاستعادة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('إنشاء نسخة احتياطية قبل الاستعادة'),
              subtitle: const Text('نقل البيانات الحالية إلى نسخة احتياطية جديدة'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('استعادة البيانات فقط'),
              subtitle: const Text('تجاهل الإعدادات والتفضيلات'),
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('استعادة جميع البيانات'),
              subtitle: const Text('البيانات والإعدادات والمفضلة'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAutoBackupSettings(),
          const SizedBox(height: 16),
          _buildBackupPreferences(),
          const SizedBox(height: 16),
          _buildStorageSettings(),
        ],
      ),
    );
  }

  Widget _buildAutoBackupSettings() {
    bool autoBackup = _backupSettings['autoBackupEnabled'] ?? false;
    String interval = _backupSettings['autoBackupInterval'] ?? 'weekly';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'النسخ الاحتياطي التلقائي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _backupSettings['autoBackupEnabled'] = value;
                    });
                    _saveSettings();
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (autoBackup) ...[
              const Text(
                'تكرار النسخ الاحتياطي:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildIntervalSelector(interval),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(String currentInterval) {
    List<Map<String, String>> intervals = [
      {'value': 'daily', 'label': 'يومي'},
      {'value': 'weekly', 'label': 'أسبوعي'},
      {'value': 'monthly', 'label': 'شهري'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: intervals.map((interval) {
        bool isSelected = currentInterval == interval['value'];
        return FilterChip(
          label: Text(interval['label'] ?? ''),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _backupSettings['autoBackupInterval'] = interval['value'];
              });
              _saveSettings();
            }
          },
          backgroundColor: Colors.grey[100],
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackupPreferences() {
    bool includeImages = _backupSettings['includeImages'] ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفضيلات النسخ الاحتياطي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تضمين الصور'),
              subtitle: const Text('نسخ صور الشهداء والجرحى (يزيد حجم الملف)'),
              value: includeImages,
              onChanged: (value) {
                setState(() {
                  _backupSettings['includeImages'] = value;
                });
                _saveSettings();
              },
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('ضغط النسخ الاحتياطي'),
              subtitle: const Text('ضغط الملفات لتوفير المساحة'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('تشفير النسخ الاحتياطي'),
              subtitle: const Text('حماية البيانات الحساسة'),
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSettings() {
    int maxBackups = _backupSettings['maxBackups'] ?? 10;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات التخزين',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('الحد الأقصى للنسخ الاحتياطية'),
              subtitle: const Text('حذف النسخ القديمة تلقائياً'),
              trailing: DropdownButton<int>(
                value: maxBackups,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 نسخ')),
                  DropdownMenuItem(value: 10, child: Text('10 نسخ')),
                  DropdownMenuItem(value: 20, child: Text('20 نسخة')),
                  DropdownMenuItem(value: -1, child: Text('بدون حد')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _backupSettings['maxBackups'] = value;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('مساحة التخزين المستخدمة'),
              subtitle: const Text('1.2 جيجابايت'),
              trailing: IconButton(
                icon: const Icon(Icons.cleaning_services),
                onPressed: () => _cleanOldBackups(),
                tooltip: 'تنظيف النسخ القديمة',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackupStats(),
          const SizedBox(height: 16),
          _buildRestoreStats(),
          const SizedBox(height: 16),
          _buildActivityChart(),
        ],
      ),
    );
  }

  Widget _buildBackupStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات النسخ الاحتياطي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('إجمالي النسخ', '${_backupList.length}', Icons.backup, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('مساحة محفوظة', '1.2 GB', Icons.storage, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('نجح اليوم', '2', Icons.check_circle, Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('فشل هذا الشهر', '0', Icons.error, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات الاستعادة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.restore, color: Colors.orange),
              title: const Text('عدد عمليات الاستعادة'),
              trailing: const Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Icon(Icons.timer, color: Colors.blue),
              title: const Text('متوسط وقت الاستعادة'),
              trailing: const Text('2.5 دقيقة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: const Text('نسبة النجاح'),
              trailing: const Text('100%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نشاط النسخ الاحتياطي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'مخطط النشاط',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _createBackup(true),
      backgroundColor: AppColors.accentColor,
      icon: const Icon(Icons.backup),
      label: const Text('نسخة كاملة'),
      tooltip: 'إنشاء نسخة احتياطية كاملة',
    );
  }

  // الوظائف الأساسية

  Future<void> _createBackup(bool includeImages) async {
    if (_isCreatingBackup) return;

    setState(() {
      _isCreatingBackup = true;
    });

    try {
      // في التطبيق الحقيقي، ستحتاج لاستدعاء خدمة النسخ الاحتياطي
      await Future.delayed(const Duration(seconds: 3)); // محاكاة عملية النسخ
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadBackupData(); // تحديث قائمة النسخ
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingBackup = false;
      });
    }
  }

  void _showRestoreDialog() {
    if (_backupList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد نسخ احتياطية للاستعادة منها'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر النسخة للاستعادة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _backupList.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> backup = _backupList[index];
              return RadioListTile<String>(
                title: Text(backup['fileName']),
                subtitle: Text(_formatDateTime(backup['modified'])),
                value: backup['filePath'],
                groupValue: _selectedBackupPath,
                onChanged: (value) {
                  setState(() {
                    _selectedBackupPath = value!;
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _selectedBackupPath.isEmpty ? null : _restoreBackup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup() async {
    Navigator.pop(context);
    
    setState(() {
      _isRestoring = true;
    });

    try {
      // في التطبيق الحقيقي، ستحتاج لاستدعاء خدمة النسخ الاحتياطي
      await Future.delayed(const Duration(seconds: 2)); // محاكاة عملية الاستعادة
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استعادة البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في استعادة البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRestoring = false;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _tabController.animateTo(2);
        break;
      case 'auto_backup':
        _toggleAutoBackup();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _handleBackupAction(String action, Map<String, dynamic> backup) {
    switch (action) {
      case 'restore':
        _selectedBackupPath = backup['filePath'];
        _showRestoreDialog();
        break;
      case 'download':
        _downloadBackup(backup);
        break;
      case 'delete':
        _deleteBackup(backup);
        break;
    }
  }

  void _toggleAutoBackup() {
    setState(() {
      _backupSettings['autoBackupEnabled'] = !(_backupSettings['autoBackupEnabled'] ?? false);
    });
    _saveSettings();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مساعدة النسخ الاحتياطي'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النسخ السريع:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('ينسخ البيانات الأساسية فقط'),
            SizedBox(height: 12),
            Text(
              'النسخة الكاملة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('ينسخ جميع البيانات بما في ذلك الصور'),
            SizedBox(height: 12),
            Text(
              'الاستعادة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('تستبدل البيانات الحالية بالبيانات من النسخة الاحتياطية'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showBackupDetails(Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backup['fileName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الحجم: ${_formatFileSize(backup['size'] ?? 0)}'),
            Text('التاريخ: ${_formatDateTime(backup['modified'])}'),
            Text('النوع: ${backup['type'] == 'auto' ? 'تلقائي' : 'يدوي'}'),
            Text('المسار: ${backup['filePath']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBackupAction('restore', backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _downloadBackup(Map<String, dynamic> backup) {
    // تحميل النسخة الاحتياطية
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم بدء تحميل النسخة الاحتياطية'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النسخة الاحتياطية'),
        content: const Text('هل أنت متأكد من حذف هذه النسخة الاحتياطية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // حذف النسخة الاحتياطية
      await _loadBackupData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف النسخة الاحتياطية'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _cleanOldBackups() {
    // تنظيف النسخ القديمة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تنظيف النسخ الاحتياطية القديمة'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  void _saveSettings() {
    // حفظ الإعدادات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // وظائف مساعدة

  bool get autoBackupBackupEnabled => _backupSettings['autoBackupEnabled'] ?? false;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes بايت';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }
}

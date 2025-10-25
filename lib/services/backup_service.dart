import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firestore_service.dart';
import 'auth_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء نسخة احتياطية كاملة
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw Exception('لم يتم تسجيل الدخول');

      // جلب جميع البيانات
      final martyrs = await _firestoreService.getAllMartyrs();
      final injured = await _firestoreService.getAllInjured();
      final prisoners = await _firestoreService.getAllPrisoners();
      
      // تحويل البيانات إلى JSON
      final backup = {
        'version': '1.0.0',
        'created_at': DateTime.now().toIso8601String(),
        'created_by': user.uid,
        'martyrs': martyrs.map((m) => m.toMap()).toList(),
        'injured': injured.map((i) => i.toMap()).toList(),
        'prisoners': prisoners.map((p) => p.toMap()).toList(),
        'statistics': {
          'martyrs_count': martyrs.length,
          'injured_count': injured.length,
          'prisoners_count': prisoners.length,
        },
      };

      // حفظ النسخة الاحتياطية في Firestore
      await _firestore.collection('backups').add({
        ...backup,
        'user_id': user.uid,
      });

      // حفظ تاريخ آخر نسخة احتياطية محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_date', DateTime.now().toIso8601String());

      return backup;
    } catch (e) {
      throw Exception('فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  /// الحصول على جميع النسخ الاحتياطية للمستخدم الحالي
  Future<List<Map<String, dynamic>>> getBackupsList() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw Exception('لم يتم تسجيل الدخول');

      final querySnapshot = await _firestore
          .collection('backups')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب قائمة النسخ الاحتياطية: $e');
    }
  }

  /// استعادة البيانات من نسخة احتياطية
  Future<void> restoreBackup(String backupId) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw Exception('لم يتم تسجيل الدخول');

      // جلب النسخة الاحتياطية
      final backupDoc = await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
        throw Exception('النسخة الاحتياطية غير موجودة');
      }

      final backupData = backupDoc.data();
      if (backupData == null) {
        throw Exception('بيانات النسخة الاحتياطية تالفة');
      }

      // التحقق من أن النسخة الاحتياطية تخص المستخدم الحالي
      if (backupData['user_id'] != user.uid) {
        throw Exception('هذه النسخة الاحتياطية لا تخصك');
      }

      // استعادة البيانات (ملاحظة: هذه عملية خطرة، يجب عمل نسخة احتياطية أولاً)
      // في التطبيق الحقيقي، يُفضل عرض البيانات وطلب تأكيد من المستخدم
      
      // هنا يمكن إضافة منطق لحذف البيانات الحالية وإضافة البيانات المستعادة
      // لكن هذا يتطلب حذراً شديداً

      // حفظ تاريخ آخر استعادة محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_restore_date', DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('فشل استعادة النسخة الاحتياطية: $e');
    }
  }

  /// الحصول على تاريخ آخر نسخة احتياطية
  Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString('last_backup_date');
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تفعيل/إلغاء النسخ الاحتياطي التلقائي
  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup', enabled);
  }

  /// التحقق من حالة النسخ الاحتياطي التلقائي
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_backup') ?? false;
  }

  /// تهيئة الخدمة
  Future<void> initialize() async {
    await SharedPreferences.getInstance();
  }

  /// الحصول على قائمة النسخ الاحتياطية
  Future<List<Map<String, dynamic>>> getBackupList() async {
    final user = await _authService.getCurrentUser();
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('backups')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>
    }).toList();
  }

  /// الحصول على إعدادات النسخ الاحتياطي
  Map<String, dynamic> getBackupSettings() {
    return {
      'auto_backup': false,
      'backup_frequency': 'weekly',
      'backup_time': '02:00',
      'backup_location': 'cloud',
      'max_backups': 10,
    };
  }
}

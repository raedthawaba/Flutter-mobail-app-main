import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user.dart' as app_user;

class FirebaseTestService {
  static bool _isFirebaseInitialized = false;

  /// اختبار أساسي لاتصال Firebase
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    Map<String, dynamic> results = {
      'firebase_initialized': false,
      'auth_working': false,
      'firestore_working': false,
      'test_data_written': false,
      'test_data_read': false,
      'errors': <String>[],
      'warnings': <String>[],
      'recommendations': <String>[],
    };

    try {
      // 1. فحص Firebase initialization
      if (!Firebase.apps.isNotEmpty) {
        results['errors'].add('Firebase لم يتم تهيئته. تأكد من إضافة google-services.json');
        return results;
      }
      results['firebase_initialized'] = true;

      // 2. اختبار Authentication
      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          results['auth_working'] = true;
          print('✅ المستخدم مسجل الدخول: ${user.email}');
        } else {
          results['auth_working'] = true;
          print('✅ Authentication يعمل (لا يوجد مستخدم مسجل)');
        }
      } catch (e) {
        results['errors'].add('خطأ في Authentication: $e');
      }

      // 3. اختبار Firestore
      try {
        final DocumentReference testDoc = FirebaseFirestore.instance
            .collection('test_collection')
            .doc('connectivity_test_${DateTime.now().millisecondsSinceEpoch}');

        // اختبار كتابة البيانات
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': 'connection_test',
          'flutter_version': '1.0.0',
        });
        results['test_data_written'] = true;

        // اختبار قراءة البيانات
        final DocumentSnapshot snapshot = await testDoc.get();
        if (snapshot.exists) {
          results['test_data_read'] = true;
          print('✅ Firestore يعمل: ${snapshot.data()}');
        }

        // حذف اختبار البيانات
        await testDoc.delete();
        results['firestore_working'] = true;

      } catch (e) {
        results['errors'].add('خطأ في Firestore: $e');
      }

    } catch (e) {
      results['errors'].add('خطأ عام: $e');
    }

    // 4. تقديم التوصيات
    if (!results['errors'].isEmpty) {
      results['recommendations'].add('راجع Firebase Setup Guide للخطوات المفقودة');
    }

    return results;
  }

  /// اختبار حساب المستخدم (Admin/Moderator)
  static Future<Map<String, dynamic>> testUserRole() async {
    Map<String, dynamic> results = {
      'user_logged_in': false,
      'user_role': 'unknown',
      'has_admin_permission': false,
      'has_moderator_permission': false,
      'errors': <String>[],
    };

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        results['errors'].add('لا يوجد مستخدم مسجل الدخول');
        return results;
      }

      results['user_logged_in'] = true;

      // قراءة بيانات المستخدم من Firestore
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'user';
        results['user_role'] = role;

        results['has_admin_permission'] = role == 'admin';
        results['has_moderator_permission'] = role == 'admin' || role == 'moderator';

        print('📋 دور المستخدم: $role');
        print('🔐 صلاحيات Admin: ${results['has_admin_permission']}');
        print('🔐 صلاحيات Moderator: ${results['has_moderator_permission']}');
      } else {
        results['warnings'].add('لم يتم العثور على بيانات المستخدم في Firestore');
      }

    } catch (e) {
      results['errors'].add('خطأ في اختبار دور المستخدم: $e');
    }

    return results;
  }

  /// اختبار CRUD operations
  static Future<Map<String, dynamic>> testCRUDOperations() async {
    Map<String, dynamic> results = {
      'test_results': <String>[],
      'errors': <String>[],
    };

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        results['errors'].add('يجب تسجيل الدخول أولاً');
        return results;
      }

      final String testId = 'test_crud_${DateTime.now().millisecondsSinceEpoch}';

      // 1. CREATE - إنشاء Martyr تجريبي
      try {
        await FirebaseFirestore.instance
            .collection('martyrs')
            .doc(testId)
            .set({
          'full_name': 'Test Martyr',
          'death_date': Timestamp.now(),
          'age': 25,
          'governorate': 'Gaza',
          'test_record': true,
          'created_by': user.uid,
        });
        results['test_results'].add('✅ CREATE: تم إنشاء martyr تجريبي بنجاح');
      } catch (e) {
        results['errors'].add('❌ CREATE: فشل في إنشاء martyr - $e');
      }

      // 2. READ - قراءة البيانات
      try {
        final DocumentSnapshot martyr = await FirebaseFirestore.instance
            .collection('martyrs')
            .doc(testId)
            .get();
        
        if (martyr.exists) {
          results['test_results'].add('✅ READ: تم قراءة martyr بنجاح');
        }
      } catch (e) {
        results['errors'].add('❌ READ: فشل في قراءة martyr - $e');
      }

      // 3. UPDATE - تحديث البيانات
      try {
        await FirebaseFirestore.instance
            .collection('martyrs')
            .doc(testId)
            .update({
          'age': 30,
          'updated_at': FieldValue.serverTimestamp(),
        });
        results['test_results'].add('✅ UPDATE: تم تحديث martyr بنجاح');
      } catch (e) {
        results['errors'].add('❌ UPDATE: فشل في تحديث martyr - $e');
      }

      // 4. DELETE - حذف البيانات التجريبية
      try {
        await FirebaseFirestore.instance
            .collection('martyrs')
            .doc(testId)
            .delete();
        results['test_results'].add('✅ DELETE: تم حذف martyr التجريبي بنجاح');
      } catch (e) {
        results['errors'].add('❌ DELETE: فشل في حذف martyr - $e');
      }

    } catch (e) {
      results['errors'].add('خطأ عام في CRUD tests: $e');
    }

    return results;
  }

  /// اختبار Security Rules
  static Future<Map<String, dynamic>> testSecurityRules() async {
    Map<String, dynamic> results = {
      'unauthenticated_read': false,
      'authenticated_read': false,
      'admin_write': false,
      'errors': <String>[],
    };

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final bool isAuthenticated = user != null;

      // 1. اختبار قراءة بدون authentication
      try {
        // تسجيل خروج مؤقت لاختبار القواعد
        if (isAuthenticated) {
          await FirebaseAuth.instance.signOut();
        }

        final QuerySnapshot martyrs = await FirebaseFirestore.instance
            .collection('martyrs')
            .limit(1)
            .get();

        if (!martyrs.empty) {
          results['unauthenticated_read'] = true;
          print('✅ Security Rule: القراءة بدون authentication مسموحة');
        }
      } catch (e) {
        print('❌ Security Rule: القراءة بدون authentication محظورة - $e');
      }

      // 2. اختبار قراءة مع authentication
      if (!isAuthenticated) {
        // تسجيل دخول تجريبي
        await FirebaseAuth.instance.signInAnonymously();
      }

      final QuerySnapshot authenticatedMartyrs = await FirebaseFirestore.instance
          .collection('martyrs')
          .limit(1)
          .get();

      if (!authenticatedMartyrs.empty) {
        results['authenticated_read'] = true;
        print('✅ Security Rule: القراءة مع authentication مسموحة');
      }

      // 3. اختبار كتابة للـ admin (يتطلب admin user)
      final testUser = FirebaseAuth.instance.currentUser;
      if (testUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('martyrs')
              .doc('security_test_${DateTime.now().millisecondsSinceEpoch}')
              .set({
            'full_name': 'Security Test',
            'death_date': Timestamp.now(),
            'age': 30,
            'governorate': 'Test',
          });

          results['admin_write'] = true;
          print('✅ Security Rule: الكتابة admin مسموحة');
        } catch (e) {
          print('❌ Security Rule: الكتابة admin محظورة - $e');
        }
      }

    } catch (e) {
      results['errors'].add('خطأ في اختبار Security Rules: $e');
    }

    return results;
  }

  /// اختبار شامل لـ Firebase
  static Future<Map<String, dynamic>> fullFirebaseTest() async {
    print('🚀 بدء اختبار Firebase الشامل...\n');

    Map<String, dynamic> allResults = {};

    // 1. اختبار الاتصال الأساسي
    print('🔗 اختبار الاتصال الأساسي...');
    allResults['connection_test'] = await testFirebaseConnection();

    // 2. اختبار دور المستخدم
    print('👤 اختبار دور المستخدم...');
    allResults['role_test'] = await testUserRole();

    // 3. اختبار CRUD operations
    print('💾 اختبار CRUD operations...');
    allResults['crud_test'] = await testCRUDOperations();

    // 4. اختبار Security Rules
    print('🔒 اختبار Security Rules...');
    allResults['security_test'] = await testSecurityRules();

    // 5. ملخص النتائج
    print('📊 ملخص النتائج:');
    print('=' * 50);

    allResults['summary'] = {
      'connection_working': allResults['connection_test']['firebase_initialized'] &&
                           allResults['connection_test']['firestore_working'],
      'auth_working': allResults['connection_test']['auth_working'],
      'security_working': allResults['security_test']['unauthenticated_read'] &&
                         allResults['security_test']['authenticated_read'],
      'total_errors': (allResults['connection_test']['errors'].length ?? 0) +
                     (allResults['crud_test']['errors'].length ?? 0) +
                     (allResults['security_test']['errors'].length ?? 0),
    };

    if (allResults['summary']['connection_working']) {
      print('✅ Firebase يعمل بشكل صحيح');
    } else {
      print('❌ هناك مشاكل في Firebase');
    }

    if (allResults['summary']['total_errors'] == 0) {
      print('🎉 جميع الاختبارات نجحت!');
    } else {
      print('⚠️ يوجد ${allResults['summary']['total_errors']} أخطاء تحتاج مراجعة');
    }

    return allResults;
  }
}
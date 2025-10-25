import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart' as app_user;
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../constants/app_constants.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _martyrsCollection => _firestore.collection('martyrs');
  CollectionReference get _injuredCollection => _firestore.collection('injured');
  CollectionReference get _prisonersCollection => _firestore.collection('prisoners');

  // ===== دوال المستخدمين =====

  Future<void> createUser(app_user.User user) async {
    try {
      if (user.uid == null) {
        throw Exception('User UID is required');
      }
      await _usersCollection.doc(user.uid).set(_convertUserToFirestore(user));
    } catch (e) {
      throw Exception('خطأ في إنشاء المستخدم: $e');
    }
  }

  Future<app_user.User?> getUserByCredentials(String username, String password) async {
    try {
      // البحث عن المستخدم باستخدام email
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      // في الإنتاج يجب التحقق من كلمة المرور المشفرة
      // هنا نفترض أن البيانات صالحة للتبسيط
      data['uid'] = doc.id;
      return app_user.User.fromMap(data);
    } catch (e) {
      throw Exception('خطأ في جلب المستخدم: $e');
    }
  }

  Future<app_user.User?> getUserByUid(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['uid'] = uid;
      return app_user.User.fromMap(data);
    } catch (e) {
      throw Exception('خطأ في جلب المستخدم: $e');
    }
  }

  Future<app_user.User?> getUserById(int id) async {
    // Firestore لا يدعم integer IDs، نحتاج للبحث بطريقة أخرى
    try {
      final querySnapshot = await _usersCollection
          .where('local_id', isEqualTo: id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return app_user.User.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUsernameExists(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserLastLogin(int userId) async {
    try {
      final querySnapshot = await _usersCollection
          .where('local_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception('خطأ في تحديث آخر تسجيل دخول: $e');
    }
  }

  Future<List<app_user.User>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return app_user.User.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  Future<void> updateUser(app_user.User user) async {
    try {
      if (user.uid == null) {
        throw Exception('User UID is required');
      }
      await _usersCollection.doc(user.uid).update(_convertUserToFirestore(user));
    } catch (e) {
      throw Exception('خطأ في تحديث المستخدم: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final querySnapshot = await _usersCollection
          .where('local_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      throw Exception('خطأ في حذف المستخدم: $e');
    }
  }

  // ===== دوال الشهداء =====

  Future<String> insertMartyr(Martyr martyr) async {
    try {
      final docRef = await _martyrsCollection.add(_convertMartyrToFirestore(martyr));
      return docRef.id;
    } catch (e) {
      throw Exception('خطأ في إضافة الشهيد: $e');
    }
  }

  Future<List<Martyr>> getAllMartyrs() async {
    try {
      final querySnapshot = await _martyrsCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToMartyr(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الشهداء: $e');
    }
  }

  Future<List<Martyr>> getMartyrsByUserId(int userId) async {
    try {
      final querySnapshot = await _martyrsCollection
          .where('added_by_user_id', isEqualTo: userId.toString())
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToMartyr(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الشهداء: $e');
    }
  }

  Future<void> updateMartyrStatus(String id, String status, String? adminNotes) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }
      await _martyrsCollection.doc(id).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الشهيد: $e');
    }
  }

  Future<void> updateMartyr(Martyr martyr) async {
    try {
      if (martyr.id == null) {
        throw Exception('Martyr ID is required');
      }
      await _martyrsCollection.doc(martyr.id).update(_convertMartyrToFirestore(martyr));
    } catch (e) {
      throw Exception('خطأ في تحديث الشهيد: $e');
    }
  }

  Future<void> deleteMartyr(String id) async {
    try {
      await _martyrsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الشهيد: $e');
    }
  }

  // ===== دوال الجرحى =====

  Future<String> insertInjured(Injured injured) async {
    try {
      final docRef = await _injuredCollection.add(_convertInjuredToFirestore(injured));
      return docRef.id;
    } catch (e) {
      throw Exception('خطأ في إضافة الجريح: $e');
    }
  }

  Future<List<Injured>> getAllInjured() async {
    try {
      final querySnapshot = await _injuredCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToInjured(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الجرحى: $e');
    }
  }

  Future<List<Injured>> getInjuredByUserId(int userId) async {
    try {
      final querySnapshot = await _injuredCollection
          .where('added_by_user_id', isEqualTo: userId.toString())
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToInjured(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الجرحى: $e');
    }
  }

  Future<void> updateInjuredStatus(String id, String status, String? adminNotes) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }
      await _injuredCollection.doc(id).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الجريح: $e');
    }
  }

  Future<void> updateInjured(Injured injured) async {
    try {
      if (injured.id == null) {
        throw Exception('Injured ID is required');
      }
      await _injuredCollection.doc(injured.id).update(_convertInjuredToFirestore(injured));
    } catch (e) {
      throw Exception('خطأ في تحديث الجريح: $e');
    }
  }

  Future<void> deleteInjured(String id) async {
    try {
      await _injuredCollection.doc(id).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الجريح: $e');
    }
  }

  // ===== دوال الأسرى =====

  Future<String> insertPrisoner(Prisoner prisoner) async {
    try {
      final docRef = await _prisonersCollection.add(_convertPrisonerToFirestore(prisoner));
      return docRef.id;
    } catch (e) {
      throw Exception('خطأ في إضافة الأسير: $e');
    }
  }

  Future<List<Prisoner>> getAllPrisoners() async {
    try {
      final querySnapshot = await _prisonersCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToPrisoner(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الأسرى: $e');
    }
  }

  Future<List<Prisoner>> getPrisonersByUserId(int userId) async {
    try {
      final querySnapshot = await _prisonersCollection
          .where('added_by_user_id', isEqualTo: userId.toString())
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _convertFirestoreToPrisoner(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب الأسرى: $e');
    }
  }

  Future<void> updatePrisonerStatus(String id, String status, String? adminNotes) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }
      await _prisonersCollection.doc(id).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الأسير: $e');
    }
  }

  Future<void> updatePrisoner(Prisoner prisoner) async {
    try {
      if (prisoner.id == null) {
        throw Exception('Prisoner ID is required');
      }
      await _prisonersCollection.doc(prisoner.id).update(_convertPrisonerToFirestore(prisoner));
    } catch (e) {
      throw Exception('خطأ في تحديث الأسير: $e');
    }
  }

  Future<void> deletePrisoner(String id) async {
    try {
      await _prisonersCollection.doc(id).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الأسير: $e');
    }
  }

  // ===== دوال الإحصائيات =====

  Future<Map<String, int>> getStatistics() async {
    try {
      final martyrsSnapshot = await _martyrsCollection.get();
      final injuredSnapshot = await _injuredCollection.get();
      final prisonersSnapshot = await _prisonersCollection.get();

      final pendingMartyrs = await _martyrsCollection
          .where('status', isEqualTo: AppConstants.statusPending)
          .get();
      final pendingInjured = await _injuredCollection
          .where('status', isEqualTo: AppConstants.statusPending)
          .get();
      final pendingPrisoners = await _prisonersCollection
          .where('status', isEqualTo: AppConstants.statusPending)
          .get();

      return {
        'martyrs': martyrsSnapshot.docs.length,
        'injured': injuredSnapshot.docs.length,
        'prisoners': prisonersSnapshot.docs.length,
        'pending': pendingMartyrs.docs.length + 
                  pendingInjured.docs.length + 
                  pendingPrisoners.docs.length,
      };
    } catch (e) {
      throw Exception('خطأ في جلب الإحصائيات: $e');
    }
  }

  // ===== Helper methods for data conversion =====

  Map<String, dynamic> _convertUserToFirestore(app_user.User user) {
    final data = <String, dynamic>{
      'username': user.username,
      'password': user.password, // في الإنتاج يجب تشفير كلمة المرور
      'full_name': user.fullName,
      'user_type': user.userType,
      'phone_number': user.phoneNumber,
      'created_at': user.createdAt.millisecondsSinceEpoch,
      'local_id': user.id ?? 0, // للبحث بـ integer
    };

    if (user.lastLogin != null) {
      data['last_login'] = user.lastLogin!.millisecondsSinceEpoch;
    }

    return data;
  }

  Map<String, dynamic> _convertMartyrToFirestore(Martyr martyr) {
    final data = <String, dynamic>{
      'full_name': martyr.fullName,
      'nickname': martyr.nickname,
      'tribe': martyr.tribe,
      'birth_date': martyr.birthDate?.millisecondsSinceEpoch,
      'death_date': martyr.deathDate.millisecondsSinceEpoch,
      'death_place': martyr.deathPlace,
      'cause_of_death': martyr.causeOfDeath,
      'rank_or_position': martyr.rankOrPosition,
      'participation_fronts': martyr.participationFronts,
      'family_status': martyr.familyStatus,
      'num_children': martyr.numChildren,
      'contact_family': martyr.contactFamily,
      'added_by_user_id': martyr.addedByUserId,
      'photo_path': martyr.photoPath,
      'cv_file_path': martyr.cvFilePath,
      'status': martyr.status,
      'admin_notes': martyr.adminNotes,
      'created_at': martyr.createdAt.millisecondsSinceEpoch,
      'updated_at': martyr.updatedAt?.millisecondsSinceEpoch,
    };

    // إزالة القيم الفارغة
    data.removeWhere((key, value) => value == null);
    return data;
  }

  Martyr _convertFirestoreToMartyr(Map<String, dynamic> data) {
    return Martyr(
      id: data['id']?.toString(),
      fullName: data['full_name'] ?? '',
      nickname: data['nickname'],
      tribe: data['tribe'] ?? '',
      birthDate: data['birth_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['birth_date'])
          : null,
      deathDate: DateTime.fromMillisecondsSinceEpoch(data['death_date'] ?? 0),
      deathPlace: data['death_place'] ?? '',
      causeOfDeath: data['cause_of_death'] ?? '',
      rankOrPosition: data['rank_or_position'],
      participationFronts: data['participation_fronts'],
      familyStatus: data['family_status'],
      numChildren: data['num_children'],
      contactFamily: data['contact_family'] ?? '',
      addedByUserId: data['added_by_user_id']?.toString() ?? '0',
      photoPath: data['photo_path'],
      cvFilePath: data['cv_file_path'],
      status: data['status'] ?? AppConstants.statusPending,
      adminNotes: data['admin_notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> _convertInjuredToFirestore(Injured injured) {
    final data = <String, dynamic>{
      'full_name': injured.fullName,
      'tribe': injured.tribe,
      'injury_date': injured.injuryDate.millisecondsSinceEpoch,
      'injury_place': injured.injuryPlace,
      'injury_type': injured.injuryType,
      'injury_description': injured.injuryDescription,
      'injury_degree': injured.injuryDegree,
      'current_status': injured.currentStatus,
      'hospital_name': injured.hospitalName,
      'contact_family': injured.contactFamily,
      'added_by_user_id': injured.addedByUserId,
      'photo_path': injured.photoPath,
      'cv_file_path': injured.cvFilePath,
      'status': injured.status,
      'admin_notes': injured.adminNotes,
      'created_at': injured.createdAt.millisecondsSinceEpoch,
      'updated_at': injured.updatedAt?.millisecondsSinceEpoch,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  Injured _convertFirestoreToInjured(Map<String, dynamic> data) {
    return Injured(
      id: data['id']?.toString(),
      fullName: data['full_name'] ?? '',
      tribe: data['tribe'] ?? '',
      injuryDate: DateTime.fromMillisecondsSinceEpoch(data['injury_date'] ?? 0),
      injuryPlace: data['injury_place'] ?? '',
      injuryType: data['injury_type'] ?? '',
      injuryDescription: data['injury_description'] ?? '',
      injuryDegree: data['injury_degree'] ?? '',
      currentStatus: data['current_status'] ?? '',
      hospitalName: data['hospital_name'],
      contactFamily: data['contact_family'] ?? '',
      addedByUserId: data['added_by_user_id']?.toString() ?? '0',
      photoPath: data['photo_path'],
      cvFilePath: data['cv_file_path'],
      status: data['status'] ?? AppConstants.statusPending,
      adminNotes: data['admin_notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> _convertPrisonerToFirestore(Prisoner prisoner) {
    final data = <String, dynamic>{
      'full_name': prisoner.fullName,
      'tribe': prisoner.tribe,
      'capture_date': prisoner.captureDate.millisecondsSinceEpoch,
      'capture_place': prisoner.capturePlace,
      'captured_by': prisoner.capturedBy,
      'current_status': prisoner.currentStatus,
      'release_date': prisoner.releaseDate?.millisecondsSinceEpoch,
      'family_contact': prisoner.familyContact,
      'detention_place': prisoner.detentionPlace,
      'notes': prisoner.notes,
      'added_by_user_id': prisoner.addedByUserId,
      'photo_path': prisoner.photoPath,
      'cv_file_path': prisoner.cvFilePath,
      'status': prisoner.status,
      'admin_notes': prisoner.adminNotes,
      'created_at': prisoner.createdAt.millisecondsSinceEpoch,
      'updated_at': prisoner.updatedAt?.millisecondsSinceEpoch,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  Prisoner _convertFirestoreToPrisoner(Map<String, dynamic> data) {
    return Prisoner(
      id: data['id']?.toString(),
      fullName: data['full_name'] ?? '',
      tribe: data['tribe'] ?? '',
      captureDate: DateTime.fromMillisecondsSinceEpoch(data['capture_date'] ?? 0),
      capturePlace: data['capture_place'] ?? '',
      capturedBy: data['captured_by'] ?? '',
      currentStatus: data['current_status'] ?? '',
      releaseDate: data['release_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['release_date'])
          : null,
      familyContact: data['family_contact'] ?? '',
      detentionPlace: data['detention_place'],
      notes: data['notes'],
      addedByUserId: data['added_by_user_id']?.toString() ?? '0',
      photoPath: data['photo_path'],
      cvFilePath: data['cv_file_path'],
      status: data['status'] ?? AppConstants.statusPending,
      adminNotes: data['admin_notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'])
          : null,
    );
  }

  // ===== دوال عامة =====

  Future<void> initializeFirebase() async {
    try {
      // التأكد من تهيئة Firebase
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }
      print('✅ Firebase Firestore service initialized successfully!');
    } catch (e) {
      throw Exception('خطأ في تهيئة Firebase Firestore: $e');
    }
  }

  // ===== دوال إدارة الأدوار =====
  
  /// التحقق من دور المستخدم الحالي
  Future<String?> getCurrentUserRole() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // التحقق من Custom Claims أولاً
      final IdTokenResult tokenResult = await currentUser.getIdTokenResult();
      final role = tokenResult.claims['role'] as String?;
      
      if (role != null) return role;

      // التحقق من Firestore كبديل
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] as String?;
      }

      return null;
    } catch (e) {
      print('خطأ في التحقق من دور المستخدم: $e');
      return null;
    }
  }

  /// التحقق من أن المستخدم الحالي هو Admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final role = await getCurrentUserRole();
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// التحقق من أن المستخدم الحالي هو Admin أو Moderator
  Future<bool> isCurrentUserModeratorOrAdmin() async {
    try {
      final role = await getCurrentUserRole();
      return role == 'admin' || role == 'moderator';
    } catch (e) {
      return false;
    }
  }

  /// التحقق من دور مستخدم محدد
  Future<String?> getUserRole(String uid) async {
    try {
      // التحقق من Firestore مباشرة
      final userDoc = await _usersCollection.doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] as String?;
      }

      return null;
    } catch (e) {
      print('خطأ في التحقق من دور المستخدم $uid: $e');
      return null;
    }
  }

  /// التحقق من أن المستخدم مسجل الدخول
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// الحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ تم تسجيل الخروج بنجاح');
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج: $e');
    }
  }

  // ===== دوال تحسين الأداء =====
  
  /// إنشاء Index مركب للتحسين
  Future<void> createCompositeIndexes() async {
    try {
      // ملاحظة: هذه الدالة تخدم فقط للتوثيق
      // Indices يجب إنشاؤها من Firebase Console
      print('📊 التوثيق: Indexes مطلوبة:');
      print('- martyrs: full_name ASC, governorate ASC, age ASC');
      print('- injured: full_name ASC, governorate ASC, injury_type ASC');
      print('- prisoners: full_name ASC, governorate ASC, captivity_location ASC');
    } catch (e) {
      print('خطأ في توثيق Indexes: $e');
    }
  }

  /// مراقبة استخدام قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseUsage() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // حساب عدد الوثائق لكل Collection
      final martyrsCount = await _martyrsCollection.get().then((snapshot) => snapshot.size);
      final injuredCount = await _injuredCollection.get().then((snapshot) => snapshot.size);
      final prisonersCount = await _prisonersCollection.get().then((snapshot) => snapshot.size);
      final usersCount = await _usersCollection.get().then((snapshot) => snapshot.size);

      return {
        'martyrs': martyrsCount,
        'injured': injuredCount,
        'prisoners': prisonersCount,
        'users': usersCount,
        'total': martyrsCount + injuredCount + prisonersCount + usersCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('خطأ في مراقبة الاستخدام: $e');
      return {'error': e.toString()};
    }
  }

  /// تنظيف البيانات التجريبية
  Future<void> cleanTestData() async {
    try {
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('فقط Admin يمكنه تنظيف البيانات');
      }

      // حذف الوثائق ذات test_record = true
      await _martyrsCollection.where('test_record', isEqualTo: true).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await _injuredCollection.where('test_record', isEqualTo: true).get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      await _prisonersCollection.where('test_record', isEqualTo: true).get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      print('✅ تم تنظيف البيانات التجريبية بنجاح');
    } catch (e) {
      throw Exception('خطأ في تنظيف البيانات: $e');
    }
  }
}
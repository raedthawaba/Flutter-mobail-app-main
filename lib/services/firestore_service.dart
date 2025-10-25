import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _martyrsCollection => _firestore.collection('martyrs');
  CollectionReference get _injuredCollection => _firestore.collection('injured');
  CollectionReference get _prisonersCollection => _firestore.collection('prisoners');

  // ===== دوال المستخدمين =====

  Future<void> createUser(User user) async {
    try {
      if (user.uid == null) {
        throw Exception('User UID is required');
      }
      await _usersCollection.doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('خطأ في إنشاء المستخدم: $e');
    }
  }

  Future<User?> getUserByUid(String uid) async {
    try {
      print('DEBUG: Getting user by UID: $uid');
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        print('DEBUG: User document does not exist for UID: $uid');
        return null;
      }
      
      if (doc.data() == null) {
        print('DEBUG: User document data is null for UID: $uid');
        return null;
      }
      
      final rawData = doc.data() as Map<String, dynamic>;
      print('DEBUG: Raw Firestore data: $rawData');
      
      final data = Map<String, dynamic>.from(rawData);
      data['uid'] = uid;
      
      print('DEBUG: Processed data with uid: $data');
      
      final user = User.fromMap(data);
      print('DEBUG: User created successfully. Email: ${user.email}, UserType: ${user.userType}');
      
      return user;
    } catch (e, stackTrace) {
      print('=== ERROR in getUserByUid ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return User.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب المستخدم: $e');
    }
  }

  Future<bool> isEmailExists(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('خطأ في تحديث آخر تسجيل دخول: $e');
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      if (user.uid == null) {
        throw Exception('User UID is required');
      }
      await _usersCollection.doc(user.uid).update(user.toFirestore());
    } catch (e) {
      throw Exception('خطأ في تحديث المستخدم: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
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

  Future<List<Martyr>> getMartyrsByUserId(String userId) async {
    try {
      final querySnapshot = await _martyrsCollection
          .where('added_by_user_id', isEqualTo: userId)
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

  Future<List<Injured>> getInjuredByUserId(String userId) async {
    try {
      final querySnapshot = await _injuredCollection
          .where('added_by_user_id', isEqualTo: userId)
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

  Future<List<Prisoner>> getPrisonersByUserId(String userId) async {
    try {
      final querySnapshot = await _prisonersCollection
          .where('added_by_user_id', isEqualTo: userId)
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

  Map<String, dynamic> _convertMartyrToFirestore(Martyr martyr) {
    final data = <String, dynamic>{
      'full_name': martyr.fullName,
      'tribe': martyr.tribe,
      'death_date': martyr.deathDate.millisecondsSinceEpoch,
      'death_place': martyr.deathPlace,
      'cause_of_death': martyr.causeOfDeath,
      'contact_family': martyr.contactFamily,
      'added_by_user_id': martyr.addedByUserId,
      'status': martyr.status,
      'created_at': martyr.createdAt.millisecondsSinceEpoch,
    };

    if (martyr.nickname != null) data['nickname'] = martyr.nickname;
    if (martyr.birthDate != null) data['birth_date'] = martyr.birthDate!.millisecondsSinceEpoch;
    if (martyr.rankOrPosition != null) data['rank_or_position'] = martyr.rankOrPosition;
    if (martyr.participationFronts != null) data['participation_fronts'] = martyr.participationFronts;
    if (martyr.familyStatus != null) data['family_status'] = martyr.familyStatus;
    if (martyr.numChildren != null) data['num_children'] = martyr.numChildren;
    if (martyr.photoPath != null) data['photo_path'] = martyr.photoPath;
    if (martyr.cvFilePath != null) data['cv_file_path'] = martyr.cvFilePath;
    if (martyr.adminNotes != null) data['admin_notes'] = martyr.adminNotes;
    if (martyr.updatedAt != null) data['updated_at'] = martyr.updatedAt!.millisecondsSinceEpoch;

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
      'contact_family': injured.contactFamily,
      'added_by_user_id': injured.addedByUserId,
      'status': injured.status,
      'created_at': injured.createdAt.millisecondsSinceEpoch,
    };

    if (injured.hospitalName != null) data['hospital_name'] = injured.hospitalName;
    if (injured.photoPath != null) data['photo_path'] = injured.photoPath;
    if (injured.cvFilePath != null) data['cv_file_path'] = injured.cvFilePath;
    if (injured.adminNotes != null) data['admin_notes'] = injured.adminNotes;
    if (injured.updatedAt != null) data['updated_at'] = injured.updatedAt!.millisecondsSinceEpoch;

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
      'family_contact': prisoner.familyContact,
      'added_by_user_id': prisoner.addedByUserId,
      'status': prisoner.status,
      'created_at': prisoner.createdAt.millisecondsSinceEpoch,
    };

    if (prisoner.releaseDate != null) data['release_date'] = prisoner.releaseDate!.millisecondsSinceEpoch;
    if (prisoner.detentionPlace != null) data['detention_place'] = prisoner.detentionPlace;
    if (prisoner.notes != null) data['notes'] = prisoner.notes;
    if (prisoner.photoPath != null) data['photo_path'] = prisoner.photoPath;
    if (prisoner.cvFilePath != null) data['cv_file_path'] = prisoner.cvFilePath;
    if (prisoner.adminNotes != null) data['admin_notes'] = prisoner.adminNotes;
    if (prisoner.updatedAt != null) data['updated_at'] = prisoner.updatedAt!.millisecondsSinceEpoch;

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
}

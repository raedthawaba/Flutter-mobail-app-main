/**
 * Cloud Functions for Firebase
 * 
 * هذا الملف يحتوي على Functions لإدارة أدوار المستخدمين:
 * - setUserRole: تعيين دور للمستخدم
 * - createAdminUser: إنشاء مستخدم admin
 * - verifyUserRole: التحقق من دور المستخدم
 * - autoCreateUserProfile: إنشاء ملف شخصي تلقائياً عند التسجيل
 */

// استيراد المكتبات المطلوبة
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// ================================
// Function 1: تعيين دور للمستخدم
// ================================
exports.setUserRole = functions.https.onCall(async (data, context) => {
  // التحقق من أن المستخدم مسجل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  // التحقق من أن المستخدم الحالي هو admin
  const currentUser = await admin.auth().getUser(context.auth.uid);
  const currentUserDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  const userRole = currentUserDoc.data()?.role || 'user';
  if (userRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'فقط المشرفون يمكنهم تعيين الأدوار');
  }

  // التحقق من البيانات المرسلة
  const { uid, role } = data;
  if (!uid || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'يجب توفير uid و role');
  }

  // التحقق من صحة الدور
  const validRoles = ['user', 'admin', 'moderator'];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'دور غير صحيح. الأدوار الصحيحة: user, admin, moderator');
  }

  try {
    // تعيين Custom Claims
    await admin.auth().setCustomUserClaims(uid, { role: role });

    // تحديث بيانات المستخدم في Firestore
    await admin.firestore()
      .collection('users')
      .doc(uid)
      .update({
        role: role,
        role_updated_by: context.auth.uid,
        role_updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

    // تسجيل العملية في activity_logs
    await admin.firestore()
      .collection('activity_logs')
      .add({
        user_id: context.auth.uid,
        action: 'set_user_role',
        target_user_id: uid,
        new_role: role,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: `تم تعيين دور ${role} للمستخدم ${uid}`,
      });

    console.log(`تم تعيين دور ${role} للمستخدم ${uid} بواسطة ${context.auth.uid}`);

    return { 
      success: true, 
      message: `تم تعيين دور ${role} بنجاح`,
      role: role,
      uid: uid,
    };

  } catch (error) {
    console.error('خطأ في تعيين الدور:', error);
    throw new functions.https.HttpsError('internal', 'حدث خطأ في تعيين الدور');
  }
});

// ================================
// Function 2: إنشاء مستخدم Admin
// ================================
exports.createAdminUser = functions.https.onCall(async (data, context) => {
  // التحقق من أن المستخدم الحالي هو admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const currentUserDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  const userRole = currentUserDoc.data()?.role || 'user';
  if (userRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'فقط المشرفون يمكنهم إنشاء مستخدمين admin');
  }

  const { email, password, displayName } = data;

  if (!email || !password || !displayName) {
    throw new functions.https.HttpsError('invalid-argument', 'يجب توفير email, password, displayName');
  }

  if (password.length < 6) {
    throw new functions.https.HttpsError('invalid-argument', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
  }

  try {
    // إنشاء المستخدم في Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName,
      emailVerified: false,
    });

    // إنشاء ملف شخصي في Firestore
    await admin.firestore()
      .collection('users')
      .doc(userRecord.uid)
      .set({
        uid: userRecord.uid,
        email: email,
        displayName: displayName,
        role: 'admin',
        isEmailVerified: false,
        createdBy: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active',
      });

    // تعيين Custom Claims
    await admin.auth().setCustomUserClaims(userRecord.uid, { 
      role: 'admin',
      admin: true,
    });

    // إرسال email للتحقق (اختياري)
    try {
      await admin.auth().generateEmailVerificationLink(email);
    } catch (emailError) {
      console.warn('خطأ في إرسال email التحقق:', emailError);
    }

    // تسجيل العملية
    await admin.firestore()
      .collection('activity_logs')
      .add({
        user_id: context.auth.uid,
        action: 'create_admin_user',
        target_user_id: userRecord.uid,
        new_role: 'admin',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: `تم إنشاء مستخدم admin جديد: ${email}`,
      });

    console.log(`تم إنشاء مستخدم admin: ${email} (${userRecord.uid})`);

    return {
      success: true,
      message: 'تم إنشاء مستخدم admin بنجاح',
      uid: userRecord.uid,
      email: email,
    };

  } catch (error) {
    console.error('خطأ في إنشاء مستخدم admin:', error);
    
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError('already-exists', 'هذا البريد الإلكتروني مستخدم بالفعل');
    }
    
    throw new functions.https.HttpsError('internal', 'حدث خطأ في إنشاء المستخدم');
  }
});

// ================================
// Function 3: التحقق من دور المستخدم
// ================================
exports.verifyUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const { targetUid } = data;
  const uid = targetUid || context.auth.uid;

  try {
    const userRecord = await admin.auth().getUser(uid);
    const claims = userRecord.customClaims || {};
    
    // قراءة بيانات المستخدم من Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();

    const userData = userDoc.exists ? userDoc.data() : {};

    return {
      success: true,
      uid: uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      customClaims: claims,
      firestoreRole: userData.role || 'user',
      role: claims.role || userData.role || 'user',
      isAdmin: claims.role === 'admin' || userData.role === 'admin',
      isModerator: claims.role === 'moderator' || userData.role === 'moderator',
      emailVerified: userRecord.emailVerified,
      createdAt: userRecord.metadata.creationTime,
    };

  } catch (error) {
    console.error('خطأ في التحقق من دور المستخدم:', error);
    throw new functions.https.HttpsError('not-found', 'لم يتم العثور على المستخدم');
  }
});

// ================================
// Function 4: إنشاء ملف شخصي تلقائياً عند التسجيل
// ================================
exports.autoCreateUserProfile = functions.auth.user().onCreate(async (user) => {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(user.uid)
      .get();

    // التحقق من عدم وجود ملف شخصي بالفعل
    if (!userDoc.exists) {
      await admin.firestore()
        .collection('users')
        .doc(user.uid)
        .set({
          uid: user.uid,
          email: user.email || '',
          displayName: user.displayName || 'مستخدم جديد',
          role: 'user',
          isEmailVerified: user.emailVerified || false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastLogin: admin.firestore.FieldValue.serverTimestamp(),
          status: 'active',
          // إعدادات المستخدم
          preferences: {
            language: 'ar',
            theme: 'system',
            notifications: true,
          },
          // إحصائيات المستخدم
          stats: {
            totalLogins: 1,
            totalSearches: 0,
            lastActivity: admin.firestore.FieldValue.serverTimestamp(),
          },
        });

      // تعيين Custom Claims الافتراضية
      await admin.auth().setCustomUserClaims(user.uid, { role: 'user' });

      console.log(`تم إنشاء ملف شخصي تلقائي للمستخدم: ${user.uid}`);
    }

    // تحديث آخر تسجيل دخول
    await admin.firestore()
      .collection('users')
      .doc(user.uid)
      .update({
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        'stats.totalLogins': admin.firestore.FieldValue.increment(1),
        'stats.lastActivity': admin.firestore.FieldValue.serverTimestamp(),
      });

  } catch (error) {
    console.error('خطأ في إنشاء الملف الشخصي التلقائي:', error);
  }
});

// ================================
// Function 5: تحديث Custom Claims عند تغيير الدور
// ================================
exports.updateUserClaims = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // التحقق من تغيير الدور
    if (beforeData.role !== afterData.role) {
      const { userId } = context.params;
      
      try {
        // تحديث Custom Claims
        await admin.auth().setCustomUserClaims(userId, { 
          role: afterData.role,
          admin: afterData.role === 'admin',
          moderator: afterData.role === 'moderator',
        });

        // تسجيل التغيير
        await admin.firestore()
          .collection('activity_logs')
          .add({
            user_id: userId,
            action: 'role_claim_updated',
            old_role: beforeData.role,
            new_role: afterData.role,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: `تم تحديث Custom Claims للدور ${afterData.role}`,
          });

        console.log(`تم تحديث Custom Claims للمستخدم ${userId}: ${afterData.role}`);

      } catch (error) {
        console.error('خطأ في تحديث Custom Claims:', error);
      }
    }
  });

// ================================
// Function 6: تنظيف البيانات عند حذف المستخدم
// ================================
exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;

  try {
    // حذف بيانات المستخدم
    await admin.firestore()
      .collection('users')
      .doc(uid)
      .delete();

    // حذف بيانات البحث
    const searchQueries = await admin.firestore()
      .collection('search_queries')
      .where('user_id', '==', uid)
      .get();

    const batch = admin.firestore().batch();
    searchQueries.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // حذف سجلات النشاط
    const activityLogs = await admin.firestore()
      .collection('activity_logs')
      .where('user_id', '==', uid)
      .limit(100)
      .get();

    const batch2 = admin.firestore().batch();
    activityLogs.docs.forEach(doc => {
      batch2.delete(doc.ref);
    });
    await batch2.commit();

    console.log(`تم تنظيف بيانات المستخدم ${uid}`);

  } catch (error) {
    console.error('خطأ في تنظيف بيانات المستخدم:', error);
  }
});

/**
 * كيفية استخدام هذه Functions في Flutter:
 * 
 * 1. تعيين دور مستخدم:
 * 
 * final callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
 * final result = await callable({
 *   'uid': 'user_id_here',
 *   'role': 'admin', // أو 'moderator' أو 'user'
 * });
 * 
 * 2. إنشاء مستخدم admin:
 * 
 * final callable = FirebaseFunctions.instance.httpsCallable('createAdminUser');
 * final result = await callable({
 *   'email': 'admin@example.com',
 *   'password': 'password123',
 *   'displayName': 'Admin User',
 * });
 * 
 * 3. التحقق من دور المستخدم:
 * 
 * final callable = FirebaseFunctions.instance.httpsCallable('verifyUserRole');
 * final result = await callable({
 *   'targetUid': 'user_id_here', // اختياري
 * });
 */
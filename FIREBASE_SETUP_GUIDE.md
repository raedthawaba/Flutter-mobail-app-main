# دليل إعداد Firebase Project - شهداء فلسطين

## الخطوة 1: إنشاء Firebase Project

### 1.1 إنشاء المشروع
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "Add Project"
3. أدخل اسم المشروع: `palestine-martyrs-db`
4. أكمل عملية إنشاء المشروع

### 1.2 تفعيل Firestore Database
1. في Firebase Console، انقر على "Firestore Database"
2. انقر على "Create database"
3. اختر "Start in **production mode**" (الأمان أولاً!)
4. اختر مكان الخادم الأقرب (أفترح Frankfurt - `europe-west3`)
5. انقر على "Done"

### 1.3 إضافة Android App
1. انقر على أيقونة Android
2. أدخل البيانات:
   - **Android package name**: `com.palestine.martyrs`
   - **App nickname**: `شهداء فلسطين`
   - **Debug signing SHA-1** (اختياري للاختبار)
3. تحميل `google-services.json`

### 1.4 إضافة iOS App (اختياري)
1. انقر على أيقونة iOS
2. أدخل البيانات:
   - **iOS bundle ID**: `com.palestine.martyrs`
   - **App nickname**: `شهداء فلسطين`
3. تحميل `GoogleService-Info.plist`

## الخطوة 2: إعداد Firebase في Flutter

### 2.1 تحديث google-services.json
```bash
# انسخ ملف google-services.json إلى:
android/app/google-services.json
```

### 2.2 إضافة Firebase إلى Android App
في ملف `android/app/build.gradle`:

```gradle
// في نهاية الملف
apply plugin: 'com.google.gms.google-services'
```

في ملف `android/build.gradle`:

```gradle
// في dependencies
classpath 'com.google.gms:google-services:4.4.0'
```

### 2.3 إضافة Firebase إلى iOS App
1. ضع `GoogleService-Info.plist` في مجلد `ios/Runner/`
2. في Xcode، إضافته إلى المشروع

### 2.4 تحديث إعدادات iOS
في ملف `ios/Runner/Info.plist`:

```xml
<key>REVERSED_CLIENT_ID</key>
<string>YOUR_REVERSED_CLIENT_ID_FROM_GOOGLE_SERVICE_INFO</string>
```

## الخطوة 3: إعداد Security Rules

### 3.1 Firestore Security Rules الأساسية
في Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // قاعدة عامة: السماح بالقراءة للجميع، الكتابة للمصادقين
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // قواعد خاصة للمستخدمين
    match /users/{userId} {
      allow read: if true; // للجميع
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // قواعد خاصة للشهداء
    match /martyrs/{martyrId} {
      allow read: if true; // للجميع
      allow write: if request.auth != null && 
                   (request.auth.token.admin == true || 
                    request.auth.token.moderator == true);
    }
    
    // قواعد خاصة للجرحى
    match /injured/{injuredId} {
      allow read: if true; // للجميع
      allow write: if request.auth != null && 
                   (request.auth.token.admin == true || 
                    request.auth.token.moderator == true);
    }
    
    // قواعد خاصة للأسرى
    match /prisoners/{prisonerId} {
      allow read: if true; // للجميع
      allow write: if request.auth != null && 
                   (request.auth.token.admin == true || 
                    request.auth.token.moderator == true);
    }
    
    // حماية خاصة للإعدادات
    match /app_config/{configId} {
      allow read: if true; // للجميع
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

### 3.2 Security Rules متقدمة (اختيارية)

#### قاعدة مصادقة أمتن:
```javascript
// تتحقق من صحة البيانات قبل الحفظ
match /martyrs/{martyrId} {
  allow create: if request.auth != null && 
                 validateMartyrData(request.resource.data);
  allow update: if request.auth != null && 
                 request.auth.token.admin == true &&
                 validateMartyrData(request.resource.data);
  
  function validateMartyrData(data) {
    return data.full_name is string &&
           data.full_name.size() > 0 &&
           data.full_name.size() <= 100 &&
           data.death_date is timestamp &&
           data.age is int &&
           data.age >= 0 &&
           data.age <= 150;
  }
}
```

#### قاعدة الحد من العمليات:
```javascript
// تحديد معدل العمليات
service cloud.firestore {
  match /databases/{database}/documents {
    match /martyrs/{document=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                   get(/databases/$(database)/documents/user_quota/$(request.auth.uid)).data.writesRemaining > 0;
    }
  }
}
```

## الخطوة 4: إعداد Authentication

### 4.1 تفعيل Authentication
1. في Firebase Console → Authentication
2. انقر على "Get started"
3. اختر "Email/Password" و "Google"
4. تفعيل Google Sign-in

### 4.2 إعداد Admin Claims
لجعل بعض المستخدمين "Admin" أو "Moderator":

```dart
// في FirebaseConsole → Functions (ستحتاج لإضافة Cloud Functions)
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.setUserRole = functions.https.onCall(async (data, context) => {
  // تحقق من admin
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can set roles');
  }
  
  const { uid, role } = data;
  await admin.auth().setCustomUserClaims(uid, { role: role });
  return { message: 'Role updated successfully' };
});
```

## الخطوة 5: إنشاء Collections الأساسية

### 5.1 إضافة البيانات الأولية
في Firebase Console → Firestore Database:

```javascript
// إنشاء collection للمستخدمين
Collection: users
  Doc: (user_id)
    uid: string
    email: string
    displayName: string
    role: "user" | "admin" | "moderator"
    createdAt: timestamp

// إنشاء collections للبيانات الأساسية
Collection: martyrs
Collection: injured  
Collection: prisoners
```

### 5.2 إعداد Indexes
أنشئ المركبة (Composite) Indexes للبحث المتقدم:

```javascript
// Indexes مطلوبة:
// 1. martyrs: full_name ASC, governorate ASC, age ASC
// 2. injured: full_name ASC, governorate ASC, injury_type ASC
// 3. prisoners: full_name ASC, governorate ASC, captivity_location ASC
```

## الخطوة 6: اختبار الاتصال

### 6.1 اختبار Firebase Connection
```dart
// في main.dart - تأكد من Firebase initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 6.2 اختبار Authentication
```dart
// اختبار تسجيل الدخول
FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);
```

### 6.3 اختبار Firestore
```dart
// اختبار قراءة البيانات
FirebaseFirestore.instance.collection('martyrs').get().then((snapshot) {
  print('Martyrs count: ${snapshot.docs.length}');
});
```

## الخطوة 7: Security Best Practices

### 7.1 Environment Variables
```dart
// استخدم Firebase config بدلاً من hard-coding
final FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  projectId: 'palestine-martyrs-db',
);
```

### 7.2 Data Validation
```dart
// تحقق من البيانات قبل الحفظ
class MartyrValidator {
  static bool validateMartyr(Map<String, dynamic> data) {
    if (data['full_name'] == null || data['full_name'].isEmpty) {
      return false;
    }
    if (data['death_date'] == null) {
      return false;
    }
    return true;
  }
}
```

### 7.3 Error Handling
```dart
// معالجة أخطاء Firebase
try {
  await FirebaseFirestore.instance.collection('martyrs').add(martyrData);
} on FirebaseException catch (e) {
  print('Firebase Error: ${e.code} - ${e.message}');
} catch (e) {
  print('General Error: $e');
}
```

## الخطوة 8: المراقبة والتسجيل

### 8.1 إعداد Firebase Crashlytics
```dart
// في main.dart
await Firebase.initializeApp();
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
```

### 8.2 مراقبة Firestore Usage
- راقب Usage في Firebase Console
- اضبط تنبيهات الميزانية
- راقب Performance

## نصائح مهمة:
1. **ابدأ بمشروع Firebase منفصل للاختبار**
2. **استخدم `testApp()` للتطوير والإنتاج**
3. **احفظ نسخة احتياطية من قاعدة البيانات دورياً**
4. **راجع Security Rules بانتظام**
5. **اختبر التطبيق على أجهزة متعددة**

---

**الخطوات التالية:**
1. إنشاء Firebase Project
2. تطبيق Security Rules
3. اختبار الاتصال
4. نشر التطبيق

**رقم الكوميت الحالي:** 60a1778
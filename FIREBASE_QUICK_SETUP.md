# دليل سريع - إعداد Firebase في 15 دقيقة

## 🚀 الخطوات السريعة

### الخطوة 1: إنشاء Firebase Project (3 دقائق)
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر "Add Project"
3. اسم المشروع: `palestine-martyrs-db`
4. اختياري: Google Analytics
5. انقر "Create project"

### الخطوة 2: تفعيل Firestore (2 دقيقة)
1. في Console، انقر "Firestore Database"
2. انقر "Create database"
3. اختر "Start in production mode" ⚠️
4. اختر منطقة الخادم: Frankfurt (`europe-west3`)
5. انقر "Done"

### الخطوة 3: إضافة Android App (3 دقائق)
1. انقر أيقونة Android "Add app"
2. Android package name: `com.palestine.martyrs`
3. App nickname: `شهداء فلسطين`
4. Debug signing SHA-1: `تختار Skip للحظة`
5. تحميل `google-services.json`

### الخطوة 4: إضافة google-services.json (1 دقيقة)
```bash
# ضع الملف في:
android/app/google-services.json
```

### الخطوة 5: تطبيق Security Rules (3 دقائق)
1. في Console → Firestore Database → Rules
2. انسخ Rules من `firestore_security_rules.txt`
3. انقر "Publish"

### الخطوة 6: تفعيل Authentication (2 دقائق)
1. في Console → Authentication → Get started
2. اختر "Email/Password"
3. انقر "Enable"
4. (اختياري) اختر "Google" واخطط تفعيل

### الخطوة 7: رفع البيانات التجريبية (1 دقيقة)
1. في Console → Firestore Database → Start collection
2. إنشاء:
   - Collection: `users`
   - Collection: `martyrs` 
   - Collection: `injured`
   - Collection: `prisoners`

---

## 🔧 إعداد Flutter

### 1. تحديث pubspec.yaml (مكتمل في المشروع)
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
```

### 2. تحديث android/build.gradle
```gradle
// في dependencies:
classpath 'com.google.gms:google-services:4.4.0'
```

### 3. تحديث android/app/build.gradle
```gradle
// في نهاية الملف:
apply plugin: 'com.google.gms.google-services'
```

### 4. تحديث main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

---

## 🧪 اختبار Firebase

### تشغيل اختبار شامل:
```dart
// أضف FirebaseTestScreen إلى routes:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => FirebaseTestScreen()),
);
```

### اختبار سريع:
```dart
FirebaseDatabaseService service = FirebaseDatabaseService();

// اختبار الاتصال
await service.initializeFirebase();

// اختبار المستخدم
final role = await service.getCurrentUserRole();
print('دور المستخدم: $role');

// اختبار قاعدة البيانات
final usage = await service.getDatabaseUsage();
print('عدد الوثائق: ${usage['total']}');
```

---

## 👑 إنشاء أول Admin

### الطريقة الأولى: عبر Firebase Console
1. Authentication → Users → Add user
2. Email: `admin@palestine.com`
3. Password: `admin123456`
4. إنشاء document في `users` collection:
   ```json
   {
     "uid": "USER_UID_HERE",
     "email": "admin@palestine.com",
     "displayName": "مدير النظام",
     "role": "admin",
     "createdAt": "2025-10-25T06:58:00Z"
   }
   ```

### الطريقة الثانية: عبر Cloud Functions
```javascript
// استخدم function createAdminUser
```

---

## ⚠️ نقاط مهمة

### ⚠️ أمان البيانات:
- **ابدأ بمشروع منفصل للاختبار**
- **استخدم Production mode من البداية**
- **لا تشارك Keys**

### ⚠️ النشر:
- **ضيف google-services.json للمشروع**
- **راجع Security Rules جيداً**
- **اختبر جميع العمليات قبل النشر**

### ⚠️ Cloud Functions:
- **تفعيل Authentication أولاً**
- **نشر Functions باستخدام Firebase CLI**
- **اختبر Functions محلياً قبل النشر**

---

## 🏃‍♂️ تشغيل سريع

```bash
# 1. تشغيل التطبيق
flutter run

# 2. فتح Firebase Test Screen
# (متوفر في التطبيق)

# 3. إنشاء بيانات تجريبية
FirebaseDatabaseService service = FirebaseDatabaseService();

// إنشاء martyr تجريبي
final martyr = Martyr(
  fullName: 'Test Martyr',
  deathDate: DateTime.now(),
  age: 25,
  governorate: 'Gaza',
);

await service.createMartyr(martyr);
```

---

## 📞 المساعدة

### المشاكل الشائعة:

#### "Firebase not initialized"
```dart
// تأكد من:
await Firebase.initializeApp();
```

#### "google-services.json not found"
```bash
# تأكد من وجود الملف في:
android/app/google-services.json
```

#### "Permission denied"
- تحقق من Security Rules
- تحقق من Authentication
- تحقق من role المستخدم

#### "Firestore connection timeout"
- تحقق من الإنترنت
- راجع Network settings
- جرب من جهاز آخر

---

## ✅ تحقق من اكتمال الإعداد

```dart
// اختبار شامل في Console
FirebaseTestService testService = FirebaseTestService();
final results = await testService.fullFirebaseTest();

print('الاتصال: ${results['summary']['connection_working']}');
print('Authentication: ${results['summary']['auth_working']}');
print('الأمان: ${results['summary']['security_working']}');
```

---

**🎉 إذا نجحت جميع الاختبارات، فأنت جاهز للاستخدام!**

*تم إنشاء هذا الدليل بواسطة MiniMax Agent*  
*رقم الكوميت: 60a1778*  
*التاريخ: 2025-10-25*
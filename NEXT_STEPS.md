# الخطوات التالية - اختبار التطبيق مع Firebase

## ✅ ما تم إنجازه حتى الآن:

### 1. **إعداد Firebase**
- ✅ تم إنشاء المشروع على Firebase Console
- ✅ تم إنشاء قاعدة بيانات Firestore
- ✅ تم إنشاء Collections: `martyrs`, `prisoners`, `injured`, `users`
- ✅ تم إعداد Firebase Authentication
- ✅ تم إنشاء مستخدم Admin:
  - البريد الإلكتروني: `admin@palestine.com`
  - كلمة المرور: `Admin@123456`
  - UID: `G0stgSLGjIW37u353YZLWR0qCVH3`

### 2. **تحديث الكود**
- ✅ تم تحديث `lib/models/user.dart` لدعم Firebase
- ✅ تم إنشاء `lib/services/firestore_service.dart`
- ✅ تم تحديث `lib/services/auth_service.dart` لاستخدام Firebase Auth
- ✅ تم تحديث `lib/screens/login_screen.dart` لاستخدام البريد الإلكتروني
- ✅ تم تحديث `lib/screens/register_screen.dart` لاستخدام البريد الإلكتروني

---

## 🚀 الخطوات التالية:

### الخطوة 1: تشغيل التطبيق

```bash
flutter clean
flutter pub get
flutter run
```

### الخطوة 2: اختبار تسجيل الدخول

**استخدم بيانات المسؤول:**
- **البريد الإلكتروني:** `admin@palestine.com`
- **كلمة المرور:** `Admin@123456`

يجب أن يتم تسجيل الدخول بنجاح وتوجيهك إلى لوحة تحكم المسؤول.

### الخطوة 3: اختبار إنشاء حساب جديد

1. اضغط على **"إنشاء حساب جديد"** في شاشة تسجيل الدخول
2. أدخل البيانات التالية:
   - الاسم الكامل: أي اسم تريده
   - البريد الإلكتروني: أي بريد صالح (مثل: `test@example.com`)
   - رقم الهاتف: (اختياري)
   - كلمة المرور: على الأقل 6 أحرف
   - تأكيد كلمة المرور
3. اضغط على **"إنشاء الحساب"**
4. يجب أن يتم إنشاء الحساب بنجاح

---

## 🐛 استكشاف الأخطاء المحتملة:

### **مشكلة 1: خطأ في الاتصال بـ Firebase**

**الحل:**
- تأكد من أن ملفات Firebase موجودة:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- تأكد من إضافة SHA-1 fingerprint في Firebase Console (للأندرويد)

```bash
# للحصول على SHA-1
cd android
./gradlew signingReport
```

### **مشكلة 2: "User not found" عند تسجيل الدخول**

**الحل:**
- تأكد من أن المستخدم موجود في Firebase Authentication
- تأكد من أن بيانات المستخدم موجودة في Firestore collection `users`

### **مشكلة 3: خطأ في إنشاء حساب جديد**

**الحل:**
- تأكد من تفعيل **Email/Password Authentication** في Firebase Console
- تأكد من صحة قواعد Firestore Security Rules

---

## 📝 قواعد Firestore Security Rules المقترحة:

في Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // السماح للمستخدمين المسجلين بالقراءة
    match /{document=**} {
      allow read: if request.auth != null;
    }
    
    // السماح بإنشاء مستخدم جديد عند التسجيل
    match /users/{userId} {
      allow create: if request.auth != null && request.auth.uid == userId;
      allow read, update: if request.auth != null && request.auth.uid == userId;
    }
    
    // السماح للمسؤولين فقط بالكتابة في باقي المجموعات
    match /martyrs/{martyrId} {
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /prisoners/{prisonerId} {
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /injured/{injuredId} {
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

**ملاحظة:** ابدأ بقواعد بسيطة للاختبار:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## ✨ ميزات إضافية يمكن إضافتها لاحقاً:

1. **نسيت كلمة المرور:**
   - استخدام دالة `sendPasswordResetEmail` الموجودة في `AuthService`

2. **التحقق من البريد الإلكتروني:**
   - استخدام `sendEmailVerification()` من Firebase Auth

3. **تحديث الملف الشخصي:**
   - إضافة شاشة لتحديث الاسم والصورة الشخصية

4. **الإشعارات:**
   - استخدام Firebase Cloud Messaging للإشعارات

---

## 📞 الدعم:

إذا واجهت أي مشكلة:
1. تحقق من ملف `FIREBASE_MIGRATION_GUIDE.md`
2. راجع ملف `FIREBASE_STATUS.md`
3. تحقق من سجل الأخطاء في Android Studio أو VS Code

---

**بالتوفيق في اختبار التطبيق! 🎉**

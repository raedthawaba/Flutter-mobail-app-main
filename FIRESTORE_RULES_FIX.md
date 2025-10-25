# 🔥 حل مشكلة Firestore Security Rules

## ❌ **المشكلة:**
التطبيق يتعطل فوراً عند التشغيل بسبب قواعد أمان Firestore صارمة جداً.

## ✅ **الحل:**

### الخطوة 1️⃣: افتح Firebase Console

1. افتح المتصفح واذهب إلى:
   ```
   https://console.firebase.google.com
   ```

2. اختر مشروعك: **flutter-mobail-app**

### الخطوة 2️⃣: افتح Firestore Rules

1. من القائمة الجانبية، اختر **Firestore Database**
2. اضغط على تبويب **Rules** (القواعد)

### الخطوة 3️⃣: استبدل القواعد الحالية

احذف **جميع** القواعد الموجودة، واستبدلها بهذه القواعد:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // قواعد collection المستخدمين
    match /users/{userId} {
      // السماح بالقراءة لأي مستخدم مسجل
      allow read: if request.auth != null;
      
      // السماح بالكتابة للمستخدم نفسه أو للـ admin
      allow write: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
    }
    
    // قواعد collection الشهداء
    match /martyrs/{martyrId} {
      // السماح بالقراءة لأي مستخدم مسجل
      allow read: if request.auth != null;
      
      // السماح بالكتابة للمستخدم الذي أضاف البيانات أو للـ admin
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.added_by_user_id == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
    }
    
    // قواعد collection الجرحى
    match /injured/{injuredId} {
      // السماح بالقراءة لأي مستخدم مسجل
      allow read: if request.auth != null;
      
      // السماح بالكتابة للمستخدم الذي أضاف البيانات أو للـ admin
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.added_by_user_id == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
    }
    
    // قواعد collection الأسرى
    match /prisoners/{prisonerId} {
      // السماح بالقراءة لأي مستخدم مسجل
      allow read: if request.auth != null;
      
      // السماح بالكتابة للمستخدم الذي أضاف البيانات أو للـ admin
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.added_by_user_id == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
    }
  }
}
```

### الخطوة 4️⃣: احفظ التغييرات

1. اضغط زر **Publish** (نشر)
2. انتظر رسالة "Rules published successfully"

---

## 🔴 **إذا لم يحل المشكلة - قواعد مؤقتة للاختبار:**

إذا استمرت المشكلة، استخدم هذه القواعد **المؤقتة** للاختبار فقط:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // ⚠️ للاختبار فقط!
    }
  }
}
```

⚠️ **تحذير:** هذه القواعد غير آمنة! استخدمها فقط للاختبار، ثم استبدلها بالقواعد الآمنة أعلاه.

---

## 🔍 **كيف أتحقق من القواعد الحالية؟**

1. اذهب إلى Firebase Console
2. Firestore Database → Rules
3. إذا كانت القواعد مثل:
   ```
   allow read, write: if false;
   ```
   فهذا هو السبب! جميع العمليات ممنوعة.

---

## ✅ **بعد تطبيق القواعد:**

1. احذف التطبيق من جهازك
2. Build جديد من Codemagic
3. ثبّت التطبيق
4. افتح التطبيق

الآن يجب أن يعمل! 🎉

---

## 📸 **أرسل لي Screenshot:**

بعد فتح Firebase Console → Firestore Database → Rules، أرسل لي screenshot للقواعد الحالية لأتأكد من المشكلة.
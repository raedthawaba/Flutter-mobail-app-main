# 🏗️ Codemagic Build Setup Guide
## دليل إعداد البناء في Codemagic لتطبيق Palestine Martyrs

---

## 🚨 **حل مشكلة الفرع الرئيسي (main vs master)**

### المشكلة:
- أحد المستودعات يستخدم `main`
- الآخر يستخدم `master`
- هذا يسبب مشاكل في Codemagic

### الحل المطبق:
```yaml
# في codemagic.yaml
triggering:
  branch_patterns:
    - pattern: 'main'      # يدعم الفرع الجديد
      include: true
      source: true
    - pattern: 'master'    # يدعم الفرع القديم
      include: true
      source: true
```

### ✅ النتيجة:
- Codemagic سيبني تلقائياً من **كلا الفروع**
- لا حاجة لتغيير الفرع في المستودعات
- مرونة في التطوير

---

## 📱 **إعدادات البناء المتاحة**

### 1. **Android Release Build** (افتراضي)
```bash
# يُبنى تلقائياً عند push إلى main أو master
workflow: android-release
الملفات: APK + App Bundle (.aab)
```

### 2. **Android Debug Build**
```bash
# للاختبار السريع
workflow: android-debug
الملفات: APK فقط
```

### 3. **iOS Build** (يحتاج Mac)
```bash
workflow: ios-app
الملفات: .ipa
```

### 4. **Web Build**
```bash
workflow: web-build
الملفات: ملفات الويب
```

### 5. **Test & Analysis**
```bash
workflow: test-workflow
الوظيفة: فحص الكود واختبارات
```

---

## 🔧 **خطوات الإعداد في Codemagic**

### الخطوة 1: ربط المستودع
1. ادخل إلى [codemagic.io](https://codemagic.io)
2. انقر "Add application"
3. اختر GitHub
4. اختر المستودع: `raedthawaba/Flutter-mobail-app-main`
5. **أو** المستودع: `Tawsil/Flutter-mobail-app`

### الخطوة 2: اختيار الـ Workflow
```yaml
# مثال على الإعداد
Application name: Palestine Martyrs App
Repository: raedthawaba/Flutter-mobail-app-main
Branch: main  # أو master - كلاهما مدعوم
Workflow: android-release
```

### الخطوة 3: إعدادات Firebase (اختياري)
إذا كنت تريد Firebase:
```bash
# أضف متغيرات البيئة في Codemagic:
GOOGLE_SERVICES_JSON: (محتوى google-services.json)
```

### الخطوة 4: بدء البناء
```bash
# انقر "Start build"
# سيبنى تلقائياً من الفرع المحدد
```

---

## 🚀 **أوامر البناء اليدوية**

### بناء Android:
```bash
# APK Release
flutter build apk --release --split-per-abi

# App Bundle
flutter build appbundle --release

# Debug APK
flutter build apk --debug
```

### بناء iOS (Mac فقط):
```bash
flutter build ipa --release
```

### بناء Web:
```bash
flutter build web --release
```

---

## 📊 **إدارة البناء المتقدمة**

### إعداد GitHub Actions المتوازي:
```yaml
# .github/workflows/codemagic.yml
name: Trigger Codemagic
on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  trigger-build:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Codemagic
        uses: codemagic-ci-cd/codemagic-sample-project@v1
```

### إعدادات Android Keystore:
```bash
# في Codemagic Dashboard:
1. Android Signing > Add keystore
2. Upload keystore file
3. Fill keystore password, key alias, key password
4. Save
```

---

## 🔍 **استكشاف الأخطاء**

### مشكلة: "Branch not found"
```bash
# الحل: تأكد من وجود الفرع
git branch -a
git checkout main  # أو master
```

### مشكلة: "Firebase config not found"
```bash
# الحل: أضف ملف google-services.json
# أو تجاهل Firebase في البناء:
--dart-define=FIREBASE_COLLECTION_ENABLED=false
```

### مشكلة: "Build failed"
```bash
# الحل: تحقق من الـ logs في Codemagic
# شائع: dependencies أو Android SDK issues
```

---

## 📈 **مراقبة البناء**

### لوحة تحكم Codemagic:
```bash
# في Dashboard:
- Build history
- Build status
- Download artifacts
- Build logs
```

### إشعارات البناء:
```yaml
# في codemagic.yaml
publishing:
  email:
    recipients:
      - your-email@example.com
  slack:
    webhook_url: $SLACK_WEBHOOK
```

---

## 🎯 **أفضل الممارسات**

### 1. **الفرع الرئيسي**:
```bash
# استخدم main للتطوير الجديد
git checkout -b feature/new-feature
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
# ثم merge إلى main أو master
```

### 2. **البناء التلقائي**:
```bash
# عند push إلى main/master:
- Android Release: تلقائي
- Test & Analysis: اختياري
- Web Build: اختياري
```

### 3. **إدارة الإصدارات**:
```bash
# تحديث رقم الإصدار في pubspec.yaml:
version: 1.0.0+1  # 1.0.0 = versionName, 1 = versionCode
```

---

## 🆘 **الدعم والمساعدة**

### روابط مهمة:
- [وثائق Codemagic](https://docs.codemagic.io/)
- [دليل Flutter](https://flutter.dev/docs)
- [Flutter Firebase](https://firebase.flutter.dev/)

### مشاكل شائعة:
1. **Branch conflicts**: ✅ تم الحل بدعم main & master
2. **Firebase setup**: 📋 اختياري، يمكن التجاهل
3. **Build timeouts**: 🔧 قلل من dependencies
4. **iOS signing**: 🍎 يحتاج Mac & certificates

---

## ✅ **ملخص الحل**

المشكلة: اختلاف الفروع (main vs master)
الحل: ✅ دعم كلا الفرعين في codemagic.yaml
النتيجة: 🔄 بناء تلقائي من أي فرع

**جاهز للاستخدام في Codemagic!** 🚀

---

*تم إنشاء هذا الدليل بواسطة MiniMax Agent*
*Last updated: 2025-10-26*
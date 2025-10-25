# 🚀 دليل النشر - Palestine Martyrs System

## 📋 نظرة عامة

هذا الدليل يوضح كيفية نشر نظام توثيق الشهداء والجرحى والأسرى على خدمات الاستضافة المختلفة.

## 🖥️ نشر الخادم (Backend)

### 🚄 Railway (مجاني ومُوصى به)

1. **إنشاء حساب على Railway**
   - اذهب إلى [railway.app](https://railway.app)
   - سجل دخول باستخدام GitHub

2. **إنشاء مشروع جديد**
   ```bash
   # في مجلد backend
   railway login
   railway init
   railway link [project-id]
   ```

3. **إضافة PostgreSQL Database**
   ```bash
   railway add postgresql
   ```

4. **إعداد متغيرات البيئة**
   ```bash
   railway variables set ENVIRONMENT=production
   railway variables set DEBUG=False
   railway variables set JWT_SECRET_KEY=your-super-secret-production-key
   railway variables set EMAIL_HOST=smtp.gmail.com
   railway variables set EMAIL_PORT=587
   railway variables set EMAIL_USER=your-email@gmail.com
   railway variables set EMAIL_PASSWORD=your-app-password
   railway variables set ADMIN_EMAIL=admin@palestinemartyrs.org
   ```

5. **النشر**
   ```bash
   railway up
   ```

6. **الحصول على URL**
   ```bash
   railway domain
   # سيعطيك URL مثل: https://palestine-martyrs-production.up.railway.app
   ```

### 🔵 DigitalOcean App Platform

1. **إنشاء App جديد**
2. **ربط المستودع**
3. **تحديد مجلد backend**
4. **إعداد Build Command:**
   ```bash
   pip install -r requirements.txt
   ```
5. **إعداد Run Command:**
   ```bash
   uvicorn main:app --host 0.0.0.0 --port $PORT
   ```

### 🟣 Heroku

1. **تنصيب Heroku CLI**
2. **إنشاء التطبيق**
   ```bash
   cd backend
   heroku create palestine-martyrs-api
   heroku addons:create heroku-postgresql:hobby-dev
   ```

3. **إعداد متغيرات البيئة**
   ```bash
   heroku config:set ENVIRONMENT=production
   heroku config:set DEBUG=False
   heroku config:set JWT_SECRET_KEY=your-secret-key
   ```

4. **إنشاء Procfile**
   ```bash
   echo "web: uvicorn main:app --host 0.0.0.0 --port \$PORT" > Procfile
   ```

5. **النشر**
   ```bash
   git add .
   git commit -m "Deploy to Heroku"
   git push heroku main
   ```

## 📱 إعداد التطبيق للإنتاج

### 1. تحديث API URL

في `lib/services/api_service.dart`:
```dart
class ApiService {
  // استبدل بـ URL الخادم الخاص بك
  static const String baseUrl = 'https://your-backend-url.railway.app';
  // static const String baseUrl = 'https://palestine-martyrs-api.herokuapp.com';
```

### 2. تحديث إعدادات الأمان

في `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- إضافة صلاحيات الإنترنت -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- للإنتاج: منع HTTP غير المشفر -->
<application
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">
```

إنشاء `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">your-backend-domain.com</domain>
    </domain-config>
</network-security-config>
```

### 3. بناء APK للإنتاج

```bash
# تنظيف المشروع
flutter clean
flutter pub get

# بناء APK
flutter build apk --release

# أو بناء App Bundle (مُوصى به للـ Play Store)
flutter build appbundle --release
```

## 🔐 إعدادات الأمان للإنتاج

### 1. تأمين متغيرات البيئة

**للخادم:**
```bash
# استخدم مفاتيح قوية وعشوائية
JWT_SECRET_KEY=$(openssl rand -base64 32)
DATABASE_URL=postgresql://secure_user:complex_password@host:port/db

# إعدادات الإيميل الآمنة
EMAIL_PASSWORD=app-specific-password  # ليس كلمة المرور العادية
```

### 2. إعدادات قاعدة البيانات

```sql
-- إنشاء مستخدم محدود الصلاحيات
CREATE USER palestine_app WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE palestine_martyrs TO palestine_app;
GRANT USAGE ON SCHEMA public TO palestine_app;
GRANT CREATE ON SCHEMA public TO palestine_app;
```

### 3. إعدادات الجدار الناري

```bash
# السماح فقط بالمنافذ المطلوبة
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 22/tcp    # SSH (للإدارة فقط)
```

## 📊 مراقبة وصيانة النظام

### 1. تسجيل الأخطاء (Logging)

إضافة Sentry للمراقبة:
```python
# في backend/main.py
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[FastApiIntegration()],
    traces_sample_rate=1.0,
)
```

### 2. نسخ احتياطية تلقائية

```bash
# سكريبت النسخ الاحتياطي اليومي
#!/bin/bash
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql
# رفع النسخة للتخزين السحابي
```

### 3. فحص صحة النظام

```bash
# فحص حالة الخادم
curl -f https://your-backend-url.railway.app/health

# فحص قاعدة البيانات
psql $DATABASE_URL -c "SELECT 1;"
```

## 🔄 التحديثات والصيانة

### 1. تحديث الخادم

```bash
# سحب آخر التحديثات
git pull origin main

# تحديث Dependencies
pip install -r requirements.txt

# تشغيل migrations (إذا وجدت)
alembic upgrade head

# إعادة تشغيل الخدمة
railway up  # أو حسب منصة الاستضافة
```

### 2. تحديث التطبيق

```bash
# تحديث الكود
git pull origin main

# تحديث packages
flutter pub upgrade

# إعادة البناء
flutter build apk --release
```

## 🎯 نصائح للأداء

### 1. تحسين قاعدة البيانات

```sql
-- إضافة indexes للبحث السريع
CREATE INDEX idx_martyrs_status ON martyrs(status);
CREATE INDEX idx_martyrs_created_at ON martyrs(created_at);
CREATE INDEX idx_users_username ON users(username);
```

### 2. تحسين الخادم

```python
# في main.py - إضافة caching
from functools import lru_cache

@lru_cache(maxsize=100)
def get_cached_stats():
    # cache statistics for 5 minutes
    pass
```

### 3. تحسين التطبيق

```dart
// استخدام pagination للقوائم الطويلة
Future<List<Martyr>> getMartyrs({
  int page = 1,
  int limit = 20,
}) async {
  return await apiService.getMartyrs(
    skip: (page - 1) * limit,
    limit: limit,
  );
}
```

## 🚨 استكشاف الأخطاء

### أخطاء شائعة وحلولها:

1. **خطأ الاتصال بقاعدة البيانات**
   ```
   الحل: تحقق من DATABASE_URL ومتغيرات البيئة
   ```

2. **خطأ CORS**
   ```python
   # إضافة domains المسموحة في main.py
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["https://your-frontend-domain.com"],
   )
   ```

3. **خطأ JWT Token**
   ```
   الحل: تحقق من JWT_SECRET_KEY وصحة الـ token
   ```

4. **خطأ رفع الملفات**
   ```
   الحل: تحقق من صلاحيات مجلد uploads وحجم الملف
   ```

## 📞 الدعم والمساعدة

للحصول على مساعدة إضافية:

1. **مراجعة logs الخادم**
2. **فتح issue في المستودع**
3. **التواصل مع فريق التطوير**

---

**نجح النشر؟ 🎉**

يمكنك الآن الوصول لـ:
- **API Documentation**: `https://your-backend-url/docs`
- **Admin Panel**: `https://your-backend-url/admin`
- **Health Check**: `https://your-backend-url/health`
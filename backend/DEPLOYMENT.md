# دليل نشر النظام على Railway

## متطلبات النشر

### 1. إنشاء مشروع جديد على Railway
1. اذهب إلى [railway.app](https://railway.app)
2. قم بالتسجيل/تسجيل الدخول باستخدام GitHub
3. انقر على "New Project"
4. اختر "Deploy from GitHub repo"
5. اختر مستودع `Flutter-mobail-app`

### 2. إعداد متغيرات البيئة
في لوحة التحكم في Railway، أضف المتغيرات التالية:

```
DATABASE_URL=postgresql://username:password@hostname:port/database_name
JWT_SECRET_KEY=your-super-secret-jwt-key-change-in-production-2024
DEBUG=False
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

### 3. إعداد قاعدة البيانات PostgreSQL
1. في Railway، انقر على "Add Plugin"
2. اختر "PostgreSQL"
3. سيتم إنشاء قاعدة بيانات تلقائياً
4. انسخ `DATABASE_URL` من تفاصيل PostgreSQL
5. أضفها إلى متغيرات البيئة

### 4. إعدادات النشر
Railway سيتعرف تلقائياً على:
- `Dockerfile` للبناء
- `railway.toml` للإعدادات
- `requirements.txt` للتبعيات

### 5. تحديث إعدادات Flutter
بعد النشر، احصل على URL الخاص بالخادم من Railway وحدث الملف:

```dart
// في lib/services/api_service.dart
static const String baseUrl = 'https://your-railway-app-url.railway.app';
```

## اختبار النظام

### 1. اختبار API
```bash
curl https://your-railway-app-url.railway.app/health
```

### 2. إنشاء حساب مدير
```bash
curl -X POST https://your-railway-app-url.railway.app/admin/register \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "email": "admin@example.com", "password": "secure123"}'
```

### 3. الوصول للوحة الإدارة
اذهب إلى: `https://your-railway-app-url.railway.app/admin`

## الميزات المتاحة

### API Endpoints:
- `GET /health` - فحص حالة الخادم
- `POST /auth/login` - تسجيل الدخول
- `POST /admin/register` - تسجيل مدير جديد
- `GET /martyrs` - قائمة الشهداء
- `POST /martyrs` - إضافة شهيد جديد
- `GET /injured` - قائمة الجرحى
- `POST /injured` - إضافة جريح جديد
- `GET /prisoners` - قائمة الأسرى
- `POST /prisoners` - إضافة أسير جديد

### لوحة الإدارة:
- عرض جميع البيانات
- فلترة وبحث
- إحصائيات مفصلة
- إدارة البيانات

## الأمان
- JWT authentication
- Password hashing with bcrypt
- CORS configured
- Input validation with Pydantic

## المراقبة
- Health check endpoint
- Logging configured
- Error handling
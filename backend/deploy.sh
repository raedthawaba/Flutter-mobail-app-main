#!/bin/bash

# سكريبت نشر سريع لـ Railway

echo "🚀 بدء عملية النشر على Railway..."

# التحقق من وجود railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI غير مثبت. قم بتثبيته من: https://docs.railway.app/develop/cli"
    exit 1
fi

# تسجيل الدخول
echo "📝 تسجيل الدخول في Railway..."
railway login

# إنشاء مشروع جديد
echo "🔧 إنشاء مشروع جديد..."
railway init

# إضافة PostgreSQL
echo "🗄️ إضافة قاعدة بيانات PostgreSQL..."
railway add postgresql

# تعيين متغيرات البيئة
echo "⚙️ تعيين متغيرات البيئة..."
railway variables set JWT_SECRET_KEY="your-super-secret-jwt-key-change-in-production-2024"
railway variables set DEBUG="False"
railway variables set EMAIL_HOST="smtp.gmail.com"
railway variables set EMAIL_PORT="587"

# نشر التطبيق
echo "🚀 نشر التطبيق..."
railway up

echo "✅ تم النشر بنجاح!"
echo "🌐 للحصول على URL الخاص بالتطبيق، استخدم: railway status"
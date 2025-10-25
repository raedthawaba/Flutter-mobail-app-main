#!/bin/bash

# =====================================================
# PALESTINE MARTYRS PROJECT - GITHUB UPLOAD SCRIPT
# =====================================================
# هذا السكريبت يرفع المشروع إلى GitHub الجديد

echo "🇵🇸 Palestine Martyrs Documentation System - GitHub Upload"
echo "====================================================="
echo "المستودع: https://github.com/raedthawaba/Flutter-mobail-app-main"
echo "====================================================="
echo ""

# التحقق من وجود git
if ! command -v git &> /dev/null; then
    echo "❌ Git غير مثبت. يرجى تثبيت Git أولاً."
    echo "رابط التحميل: https://git-scm.com/downloads"
    exit 1
fi

echo "✅ Git متوفر"
echo ""

# إضافة المستودع البعيد (إذا لم يكن مضافاً)
echo "🔗 إضافة المستودع البعيد..."
git remote add origin https://github.com/raedthawaba/Flutter-mobail-app-main.git 2>/dev/null || echo "⚠️  المستودع البعيد موجود مسبقاً"

echo "✅ تم إضافة المستودع البعيد"
echo ""

# عرض حالة المشروع
echo "📊 فحص حالة المشروع..."
git status

echo ""
echo "🔍 الملفات التي ستُرفع:"
echo "├── Flutter Application (lib/, android/, ios/, web/)"
echo "├── Firebase Documentation (7 ملفات)"
echo "├── Backend Service (backend/)"
echo "├── Documentation (README.md, guides)"
echo "└── Configuration (.gitignore, pubspec.yaml)"
echo ""

# طلب تأكيد من المستخدم
read -p "هل تريد المتابعة ورفع المشروع؟ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ تم إلغاء العملية"
    exit 1
fi

echo ""
echo "📁 إضافة الملفات..."
git add .

echo "📝 إنشاء commit..."
git commit -m "🎉 Initial commit: Palestine Martyrs Documentation System

✨ Features:
- Complete Firebase Firestore integration
- User authentication with roles (Admin/Moderator/User)
- Real-time data synchronization
- Comprehensive testing tools
- Arabic RTL support
- Admin dashboard ready

📊 Data Types:
- Martyrs documentation with photos
- Injured persons tracking
- Prisoners status monitoring
- User management system

🔐 Security:
- Firestore security rules
- Role-based access control
- JWT authentication
- Cloud Functions ready

📱 Tech Stack:
- Flutter 3.0+
- Firebase Firestore & Authentication
- FastAPI Backend
- Railway deployment ready
- Cloud Functions for admin roles

🌍 Multilingual:
- Arabic RTL interface
- English support
- Localized content

🚀 Ready for:
- Team collaboration
- GitHub Actions CI/CD
- Production deployment
- Large-scale usage"

echo ""
echo "🚀 رفع المشروع إلى GitHub..."
git push -u origin main

echo ""
echo "🎉 تم رفع المشروع بنجاح!"
echo ""
echo "📋 الخطوات التالية:"
echo "1. اذهب إلى: https://github.com/raedthawaba/Flutter-mobail-app-main"
echo "2. تحقق من رفع الملفات"
echo "3. استخدم FIREBASE_SETUP_GUIDE.md لإعداد Firebase"
echo "4. قم بتشغيل Firebase test screen للاختبار"
echo ""
echo "🇵🇸 كل التقدير لك! المشروع جاهز للعمل"
echo "====================================================="
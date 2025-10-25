#!/bin/bash

# سكريبت لتحديث URL الخادم في تطبيق Flutter

if [ -z "$1" ]; then
    echo "الاستخدام: $0 <railway-app-url>"
    echo "مثال: $0 https://my-app-production.railway.app"
    exit 1
fi

URL=$1

echo "🔄 تحديث URL الخادم في التطبيق..."

# تحديث api_service.dart
sed -i "s|static const String baseUrl = '.*';|static const String baseUrl = '$URL';|g" ../lib/services/api_service.dart

echo "✅ تم تحديث URL الخادم إلى: $URL"
echo "📱 يمكنك الآن بناء التطبيق مع الإعدادات الجديدة"
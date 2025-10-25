#!/usr/bin/env python3
"""
سكريبت تهيئة قاعدة البيانات الأولي
"""

import asyncio
import sys
from pathlib import Path

# إضافة مجلد backend إلى المسار
sys.path.insert(0, str(Path(__file__).parent))

from database import engine, get_db
from models import Base, Admin
from schemas import AdminCreate
import bcrypt

async def init_database():
    """تهيئة قاعدة البيانات وإنشاء المدير الأول"""
    
    print("🔧 إنشاء جداول قاعدة البيانات...")
    
    # إنشاء الجداول
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    print("✅ تم إنشاء الجداول بنجاح")
    
    # إنشاء مدير أولي
    async with get_db() as db:
        # التحقق من وجود مدير
        from sqlalchemy import select
        result = await db.execute(select(Admin))
        existing_admin = result.first()
        
        if not existing_admin:
            print("👤 إنشاء حساب المدير الأولي...")
            
            # كلمة مرور مشفرة
            hashed_password = bcrypt.hashpw("admin123".encode('utf-8'), bcrypt.gensalt())
            
            # إنشاء المدير
            admin = Admin(
                username="admin",
                email="admin@palestine-martyrs.org",
                password_hash=hashed_password.decode('utf-8'),
                is_active=True
            )
            
            db.add(admin)
            await db.commit()
            
            print("✅ تم إنشاء حساب المدير:")
            print("   👤 اسم المستخدم: admin")
            print("   🔑 كلمة المرور: admin123")
            print("   📧 البريد الإلكتروني: admin@palestine-martyrs.org")
        else:
            print("ℹ️ يوجد حساب مدير مسبقاً")

if __name__ == "__main__":
    print("🚀 بدء تهيئة قاعدة البيانات...")
    asyncio.run(init_database())
    print("🎉 تمت التهيئة بنجاح!")
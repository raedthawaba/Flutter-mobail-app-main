"""
Palestine Martyrs Backend API
FastAPI server for managing martyrs, injured, and prisoners data
"""

from fastapi import FastAPI, HTTPException, Depends, status, UploadFile, File
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import create_database, text
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import jwt
import bcrypt
import os
from typing import List, Optional
import asyncio
import json

from database import engine, SessionLocal, init_db
from models import User, Martyr, Injured, Prisoner
from schemas import (
    UserCreate, UserLogin, UserResponse, 
    MartyrCreate, MartyrResponse, MartyrUpdate,
    InjuredCreate, InjuredResponse, InjuredUpdate,
    PrisonerCreate, PrisonerResponse, PrisonerUpdate,
    StatusUpdate, StatsResponse
)
from config import get_settings

# Initialize FastAPI app
app = FastAPI(
    title="Palestine Martyrs API",
    description="Backend API for Palestine Martyrs Mobile Application",
    version="1.0.0"
)

# Settings
settings = get_settings()

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # في الإنتاج، حدد النطاقات المسموحة
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Mount static files for admin panel
app.mount("/static", StaticFiles(directory="templates"), name="static")

# Admin panel route
@app.get("/admin", response_class=HTMLResponse)
async def admin_panel():
    """Admin panel web interface"""
    try:
        with open("templates/admin.html", "r", encoding="utf-8") as f:
            content = f.read()
        return HTMLResponse(content=content)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Admin panel not found")

@app.get("/admin.js")
async def admin_js():
    """Admin panel JavaScript"""
    return FileResponse("templates/admin.js", media_type="application/javascript")

# Initialize database
@app.on_event("startup")
async def startup_event():
    init_db()

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# JWT token functions
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=24)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.jwt_secret, algorithm="HS256")

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, settings.jwt_secret, algorithms=["HS256"])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(db: Session = Depends(get_db), user_id: int = Depends(verify_token)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

def admin_required(current_user: User = Depends(get_current_user)):
    if current_user.user_type != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

# ====== AUTH ENDPOINTS ======

@app.post("/auth/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """تسجيل مستخدم جديد"""
    
    # Check if username exists
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Hash password
    hashed_password = bcrypt.hashpw(user_data.password.encode('utf-8'), bcrypt.gensalt())
    
    # Create user
    db_user = User(
        username=user_data.username,
        password=hashed_password.decode('utf-8'),
        full_name=user_data.full_name,
        user_type=user_data.user_type,
        phone_number=user_data.phone_number,
        created_at=datetime.utcnow()
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return UserResponse.from_orm(db_user)

@app.post("/auth/login")
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """تسجيل دخول المستخدم"""
    
    # Find user
    user = db.query(User).filter(User.username == user_data.username).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Verify password
    if not bcrypt.checkpw(user_data.password.encode('utf-8'), user.password.encode('utf-8')):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Create token
    token = create_access_token({"user_id": user.id, "username": user.username})
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": UserResponse.from_orm(user)
    }

@app.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """معلومات المستخدم الحالي"""
    return UserResponse.from_orm(current_user)

# ====== MARTYRS ENDPOINTS ======

@app.post("/martyrs", response_model=MartyrResponse)
async def create_martyr(
    martyr_data: MartyrCreate, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """إضافة شهيد جديد"""
    
    db_martyr = Martyr(
        **martyr_data.dict(),
        added_by_user_id=current_user.id,
        status="pending",
        created_at=datetime.utcnow()
    )
    
    db.add(db_martyr)
    db.commit()
    db.refresh(db_martyr)
    
    return MartyrResponse.from_orm(db_martyr)

@app.get("/martyrs", response_model=List[MartyrResponse])
async def get_martyrs(
    skip: int = 0, 
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """قائمة الشهداء"""
    
    query = db.query(Martyr)
    
    # للمستخدم العادي: عرض بياناته فقط
    if current_user.user_type != "admin":
        query = query.filter(Martyr.added_by_user_id == current_user.id)
    
    # فلترة حسب الحالة
    if status:
        query = query.filter(Martyr.status == status)
    
    martyrs = query.offset(skip).limit(limit).all()
    return [MartyrResponse.from_orm(martyr) for martyr in martyrs]

@app.put("/martyrs/{martyr_id}/status", response_model=MartyrResponse)
async def update_martyr_status(
    martyr_id: int,
    status_data: StatusUpdate,
    db: Session = Depends(get_db),
    admin_user: User = Depends(admin_required)
):
    """تحديث حالة الشهيد (مسؤول فقط)"""
    
    martyr = db.query(Martyr).filter(Martyr.id == martyr_id).first()
    if not martyr:
        raise HTTPException(status_code=404, detail="Martyr not found")
    
    martyr.status = status_data.status
    martyr.admin_notes = status_data.admin_notes
    martyr.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(martyr)
    
    return MartyrResponse.from_orm(martyr)

# ====== INJURED ENDPOINTS ======

@app.post("/injured", response_model=InjuredResponse)
async def create_injured(
    injured_data: InjuredCreate, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """إضافة جريح جديد"""
    
    db_injured = Injured(
        **injured_data.dict(),
        added_by_user_id=current_user.id,
        status="pending",
        created_at=datetime.utcnow()
    )
    
    db.add(db_injured)
    db.commit()
    db.refresh(db_injured)
    
    return InjuredResponse.from_orm(db_injured)

@app.get("/injured", response_model=List[InjuredResponse])
async def get_injured(
    skip: int = 0, 
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """قائمة الجرحى"""
    
    query = db.query(Injured)
    
    if current_user.user_type != "admin":
        query = query.filter(Injured.added_by_user_id == current_user.id)
    
    if status:
        query = query.filter(Injured.status == status)
    
    injured = query.offset(skip).limit(limit).all()
    return [InjuredResponse.from_orm(injured_person) for injured_person in injured]

@app.put("/injured/{injured_id}/status", response_model=InjuredResponse)
async def update_injured_status(
    injured_id: int,
    status_data: StatusUpdate,
    db: Session = Depends(get_db),
    admin_user: User = Depends(admin_required)
):
    """تحديث حالة الجريح (مسؤول فقط)"""
    
    injured = db.query(Injured).filter(Injured.id == injured_id).first()
    if not injured:
        raise HTTPException(status_code=404, detail="Injured person not found")
    
    injured.status = status_data.status
    injured.admin_notes = status_data.admin_notes
    injured.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(injured)
    
    return InjuredResponse.from_orm(injured)

# ====== PRISONERS ENDPOINTS ======

@app.post("/prisoners", response_model=PrisonerResponse)
async def create_prisoner(
    prisoner_data: PrisonerCreate, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """إضافة أسير جديد"""
    
    db_prisoner = Prisoner(
        **prisoner_data.dict(),
        added_by_user_id=current_user.id,
        status="pending",
        created_at=datetime.utcnow()
    )
    
    db.add(db_prisoner)
    db.commit()
    db.refresh(db_prisoner)
    
    return PrisonerResponse.from_orm(db_prisoner)

@app.get("/prisoners", response_model=List[PrisonerResponse])
async def get_prisoners(
    skip: int = 0, 
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """قائمة الأسرى"""
    
    query = db.query(Prisoner)
    
    if current_user.user_type != "admin":
        query = query.filter(Prisoner.added_by_user_id == current_user.id)
    
    if status:
        query = query.filter(Prisoner.status == status)
    
    prisoners = query.offset(skip).limit(limit).all()
    return [PrisonerResponse.from_orm(prisoner) for prisoner in prisoners]

@app.put("/prisoners/{prisoner_id}/status", response_model=PrisonerResponse)
async def update_prisoner_status(
    prisoner_id: int,
    status_data: StatusUpdate,
    db: Session = Depends(get_db),
    admin_user: User = Depends(admin_required)
):
    """تحديث حالة الأسير (مسؤول فقط)"""
    
    prisoner = db.query(Prisoner).filter(Prisoner.id == prisoner_id).first()
    if not prisoner:
        raise HTTPException(status_code=404, detail="Prisoner not found")
    
    prisoner.status = status_data.status
    prisoner.admin_notes = status_data.admin_notes
    prisoner.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(prisoner)
    
    return PrisonerResponse.from_orm(prisoner)

# ====== ADMIN ENDPOINTS ======

@app.get("/admin/stats", response_model=StatsResponse)
async def get_statistics(
    db: Session = Depends(get_db),
    admin_user: User = Depends(admin_required)
):
    """إحصائيات عامة (مسؤول فقط)"""
    
    martyrs_count = db.query(Martyr).count()
    injured_count = db.query(Injured).count()
    prisoners_count = db.query(Prisoner).count()
    
    pending_martyrs = db.query(Martyr).filter(Martyr.status == "pending").count()
    pending_injured = db.query(Injured).filter(Injured.status == "pending").count()
    pending_prisoners = db.query(Prisoner).filter(Prisoner.status == "pending").count()
    
    users_count = db.query(User).count()
    
    return StatsResponse(
        total_martyrs=martyrs_count,
        total_injured=injured_count,
        total_prisoners=prisoners_count,
        pending_martyrs=pending_martyrs,
        pending_injured=pending_injured,
        pending_prisoners=pending_prisoners,
        total_users=users_count
    )

@app.get("/admin/users", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin_user: User = Depends(admin_required)
):
    """قائمة المستخدمين (مسؤول فقط)"""
    
    users = db.query(User).offset(skip).limit(limit).all()
    return [UserResponse.from_orm(user) for user in users]

# ====== FILE UPLOAD ENDPOINTS ======

@app.post("/upload/photo")
async def upload_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """رفع صورة"""
    
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # إنشاء مجلد الصور إذا لم يكن موجوداً
    os.makedirs("uploads/photos", exist_ok=True)
    
    # إنشاء اسم ملف فريد
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{current_user.id}_{file.filename}"
    file_path = f"uploads/photos/{filename}"
    
    # حفظ الملف
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    return {"file_path": file_path, "filename": filename}

@app.post("/upload/document")
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """رفع وثيقة"""
    
    allowed_types = ["application/pdf", "application/msword", 
                     "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
    
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="File must be PDF or Word document")
    
    os.makedirs("uploads/documents", exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{current_user.id}_{file.filename}"
    file_path = f"uploads/documents/{filename}"
    
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    return {"file_path": file_path, "filename": filename}

# ====== HEALTH CHECK ======

@app.get("/health")
async def health_check():
    """فحص صحة الخادم"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0"
    }

# Database initialization endpoint
@app.post("/init-db")
async def initialize_database():
    """تهيئة قاعدة البيانات الأولية"""
    try:
        await init_db()
        return {
            "message": "Database initialized successfully",
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database initialization failed: {str(e)}"
        )

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Palestine Martyrs API",
        "version": "1.0.0",
        "docs": "/docs",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "admin": "/admin",
            "init_db": "/init-db"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
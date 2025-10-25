"""
Database configuration for Palestine Martyrs API
SQLAlchemy database setup and connection
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
from config import get_settings

settings = get_settings()

# Database URL
# For development: SQLite
# For production: PostgreSQL
if settings.environment == "development":
    SQLALCHEMY_DATABASE_URL = "sqlite:///./palestine_martyrs.db"
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, 
        connect_args={"check_same_thread": False}
    )
else:
    # Production PostgreSQL
    SQLALCHEMY_DATABASE_URL = settings.database_url
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def init_db():
    """Initialize database tables"""
    from models import User, Martyr, Injured, Prisoner
    Base.metadata.create_all(bind=engine)
    
    # Create default admin user if not exists
    from sqlalchemy.orm import Session
    import bcrypt
    from datetime import datetime
    
    db = SessionLocal()
    try:
        admin_user = db.query(User).filter(User.username == "admin").first()
        if not admin_user:
            hashed_password = bcrypt.hashpw("admin123".encode('utf-8'), bcrypt.gensalt())
            admin_user = User(
                username="admin",
                password=hashed_password.decode('utf-8'),
                full_name="المسؤول العام",
                user_type="admin",
                created_at=datetime.utcnow()
            )
            db.add(admin_user)
            db.commit()
            print("✅ Default admin user created: username=admin, password=admin123")
    finally:
        db.close()

def get_db():
    """Database dependency for FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
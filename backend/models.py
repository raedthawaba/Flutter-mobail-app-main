"""
Database Models for Palestine Martyrs API
SQLAlchemy ORM models
"""

from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    user_type = Column(String(20), nullable=False)  # 'admin' or 'regular'
    phone_number = Column(String(20), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    martyrs = relationship("Martyr", back_populates="added_by_user")
    injured = relationship("Injured", back_populates="added_by_user")
    prisoners = relationship("Prisoner", back_populates="added_by_user")

class Martyr(Base):
    __tablename__ = "martyrs"
    
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    nickname = Column(String(50), nullable=True)
    tribe = Column(String(100), nullable=False)
    birth_date = Column(DateTime, nullable=True)
    death_date = Column(DateTime, nullable=False)
    death_place = Column(String(100), nullable=False)
    cause_of_death = Column(String(200), nullable=False)
    rank_or_position = Column(String(100), nullable=True)
    participation_fronts = Column(Text, nullable=True)
    family_status = Column(String(50), nullable=True)
    num_children = Column(Integer, nullable=True)
    contact_family = Column(String(100), nullable=False)
    photo_path = Column(String(255), nullable=True)
    cv_file_path = Column(String(255), nullable=True)
    status = Column(String(20), default="pending")  # 'pending', 'approved', 'rejected'
    admin_notes = Column(Text, nullable=True)
    added_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True)
    
    # Relationships
    added_by_user = relationship("User", back_populates="martyrs")

class Injured(Base):
    __tablename__ = "injured"
    
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    tribe = Column(String(100), nullable=False)
    injury_date = Column(DateTime, nullable=False)
    injury_place = Column(String(100), nullable=False)
    injury_type = Column(String(100), nullable=False)
    injury_description = Column(Text, nullable=False)
    injury_degree = Column(String(50), nullable=False)
    current_status = Column(String(100), nullable=False)
    hospital_name = Column(String(100), nullable=True)
    contact_family = Column(String(100), nullable=False)
    photo_path = Column(String(255), nullable=True)
    cv_file_path = Column(String(255), nullable=True)
    status = Column(String(20), default="pending")  # 'pending', 'approved', 'rejected'
    admin_notes = Column(Text, nullable=True)
    added_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True)
    
    # Relationships
    added_by_user = relationship("User", back_populates="injured")

class Prisoner(Base):
    __tablename__ = "prisoners"
    
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    tribe = Column(String(100), nullable=False)
    capture_date = Column(DateTime, nullable=False)
    capture_place = Column(String(100), nullable=False)
    captured_by = Column(String(100), nullable=False)
    current_status = Column(String(100), nullable=False)
    release_date = Column(DateTime, nullable=True)
    family_contact = Column(String(100), nullable=False)
    detention_place = Column(String(100), nullable=True)
    notes = Column(Text, nullable=True)
    photo_path = Column(String(255), nullable=True)
    cv_file_path = Column(String(255), nullable=True)
    status = Column(String(20), default="pending")  # 'pending', 'approved', 'rejected'
    admin_notes = Column(Text, nullable=True)
    added_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True)
    
    # Relationships
    added_by_user = relationship("User", back_populates="prisoners")
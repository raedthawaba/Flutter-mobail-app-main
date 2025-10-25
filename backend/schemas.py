"""
Pydantic Schemas for Palestine Martyrs API
Data validation and serialization schemas
"""

from pydantic import BaseModel, EmailStr, validator
from datetime import datetime
from typing import Optional, List

# ===== USER SCHEMAS =====

class UserBase(BaseModel):
    username: str
    full_name: str
    user_type: str
    phone_number: Optional[str] = None

class UserCreate(UserBase):
    password: str
    
    @validator('user_type')
    def validate_user_type(cls, v):
        if v not in ['admin', 'regular']:
            raise ValueError('user_type must be either admin or regular')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('password must be at least 6 characters')
        return v

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(UserBase):
    id: int
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ===== MARTYR SCHEMAS =====

class MartyrBase(BaseModel):
    full_name: str
    nickname: Optional[str] = None
    tribe: str
    birth_date: Optional[datetime] = None
    death_date: datetime
    death_place: str
    cause_of_death: str
    rank_or_position: Optional[str] = None
    participation_fronts: Optional[str] = None
    family_status: Optional[str] = None
    num_children: Optional[int] = None
    contact_family: str
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class MartyrCreate(MartyrBase):
    pass

class MartyrUpdate(BaseModel):
    full_name: Optional[str] = None
    nickname: Optional[str] = None
    tribe: Optional[str] = None
    birth_date: Optional[datetime] = None
    death_date: Optional[datetime] = None
    death_place: Optional[str] = None
    cause_of_death: Optional[str] = None
    rank_or_position: Optional[str] = None
    participation_fronts: Optional[str] = None
    family_status: Optional[str] = None
    num_children: Optional[int] = None
    contact_family: Optional[str] = None
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class MartyrResponse(MartyrBase):
    id: int
    status: str
    admin_notes: Optional[str] = None
    added_by_user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ===== INJURED SCHEMAS =====

class InjuredBase(BaseModel):
    full_name: str
    tribe: str
    injury_date: datetime
    injury_place: str
    injury_type: str
    injury_description: str
    injury_degree: str
    current_status: str
    hospital_name: Optional[str] = None
    contact_family: str
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class InjuredCreate(InjuredBase):
    pass

class InjuredUpdate(BaseModel):
    full_name: Optional[str] = None
    tribe: Optional[str] = None
    injury_date: Optional[datetime] = None
    injury_place: Optional[str] = None
    injury_type: Optional[str] = None
    injury_description: Optional[str] = None
    injury_degree: Optional[str] = None
    current_status: Optional[str] = None
    hospital_name: Optional[str] = None
    contact_family: Optional[str] = None
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class InjuredResponse(InjuredBase):
    id: int
    status: str
    admin_notes: Optional[str] = None
    added_by_user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ===== PRISONER SCHEMAS =====

class PrisonerBase(BaseModel):
    full_name: str
    tribe: str
    capture_date: datetime
    capture_place: str
    captured_by: str
    current_status: str
    release_date: Optional[datetime] = None
    family_contact: str
    detention_place: Optional[str] = None
    notes: Optional[str] = None
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class PrisonerCreate(PrisonerBase):
    pass

class PrisonerUpdate(BaseModel):
    full_name: Optional[str] = None
    tribe: Optional[str] = None
    capture_date: Optional[datetime] = None
    capture_place: Optional[str] = None
    captured_by: Optional[str] = None
    current_status: Optional[str] = None
    release_date: Optional[datetime] = None
    family_contact: Optional[str] = None
    detention_place: Optional[str] = None
    notes: Optional[str] = None
    photo_path: Optional[str] = None
    cv_file_path: Optional[str] = None

class PrisonerResponse(PrisonerBase):
    id: int
    status: str
    admin_notes: Optional[str] = None
    added_by_user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ===== COMMON SCHEMAS =====

class StatusUpdate(BaseModel):
    status: str
    admin_notes: Optional[str] = None
    
    @validator('status')
    def validate_status(cls, v):
        if v not in ['pending', 'approved', 'rejected']:
            raise ValueError('status must be pending, approved, or rejected')
        return v

class StatsResponse(BaseModel):
    total_martyrs: int
    total_injured: int
    total_prisoners: int
    pending_martyrs: int
    pending_injured: int
    pending_prisoners: int
    total_users: int

# ===== FILE UPLOAD SCHEMAS =====

class FileUploadResponse(BaseModel):
    file_path: str
    filename: str
    upload_time: datetime

class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None
    timestamp: datetime
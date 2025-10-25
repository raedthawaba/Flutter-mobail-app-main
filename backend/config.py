"""
Configuration settings for Palestine Martyrs API
Environment variables and app settings
"""

from pydantic import BaseSettings, Field
from typing import Optional
import os

class Settings(BaseSettings):
    # App Settings
    app_name: str = "Palestine Martyrs API"
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=True, env="DEBUG")
    
    # Security
    jwt_secret: str = Field(default="your-super-secret-jwt-key-change-in-production-2024", env="JWT_SECRET_KEY")
    jwt_algorithm: str = "HS256"
    access_token_expire_hours: int = 24
    
    # Database
    database_url: str = Field(default="sqlite:///./palestine_martyrs.db", env="DATABASE_URL")
    
    # File Upload Settings
    max_file_size: int = 10 * 1024 * 1024  # 10MB
    upload_path: str = "./uploads"
    allowed_image_types: list = ["image/jpeg", "image/png", "image/gif"]
    allowed_document_types: list = [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ]
    
    # Email Settings (for notifications)
    email_host: str = Field(default="smtp.gmail.com", env="EMAIL_HOST")
    email_port: int = Field(default=587, env="EMAIL_PORT")
    email_user: str = Field(default="", env="EMAIL_USER")
    email_password: str = Field(default="", env="EMAIL_PASSWORD")
    email_from: str = Field(default="noreply@palestinemartyrs.org", env="EMAIL_FROM")
    
    # Admin Settings
    admin_email: str = Field(default="admin@palestinemartyrs.org", env="ADMIN_EMAIL")
    
    # API Settings
    api_v1_prefix: str = "/api/v1"
    docs_url: str = "/docs"
    redoc_url: str = "/redoc"
    
    # CORS Settings
    allowed_origins: list = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://palestine-martyrs.vercel.app"
    ]
    
    # Production specific settings
    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"
    
    @property
    def is_development(self) -> bool:
        return self.environment.lower() == "development"
    
    class Config:
        env_file = ".env"
        case_sensitive = False

def get_settings() -> Settings:
    return Settings()

# Create uploads directory
settings = get_settings()
os.makedirs(f"{settings.upload_path}/photos", exist_ok=True)
os.makedirs(f"{settings.upload_path}/documents", exist_ok=True)
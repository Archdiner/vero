from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, time

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    fullname: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr

    class Config:
        orm_mode = True

class UserProfileUpdate(BaseModel):
    fullname: Optional[str] = None
    email: Optional[EmailStr] = None
    old_password: Optional[str] = None
    new_password: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class FavoriteToggleRequest(BaseModel):
    chain_id: int

class FavoriteToggleResponse(BaseModel):
    chain_id: int
    current_state: bool

class HomePageCustomization(BaseModel):
    profile_picture: Optional[str] = None
    university: str

class UserOnboarding(BaseModel):
    instagram: Optional[str] = None
    profile_picture: Optional[str] = None
    age: Optional[int] = None 
    gender: Optional[str] = None 
    university: Optional[str] = None 
    major: Optional[str] = None
    year_of_study: Optional[int] = None 
    budget_range: Optional[int] = None 
    move_in_date: Optional[datetime] = None
    smoking_preference: Optional[bool] = None
    drinking_preference: Optional[bool] = None
    pet_preference: Optional[bool] = None
    music_preference: Optional[bool] = None
    cleanliness_level: Optional[int] = None
    meal_schedule: Optional[str] = None
    social_preference: Optional[str] = None
    snapchat: Optional[str] = None
    phone_number: Optional[str] = None
    bio: Optional[str] = None
    sleep_time: Optional[str] = None
    wake_time: Optional[str] = None
    guest_policy: Optional[str] = None
    room_type_preference: Optional[str] = None
    religious_preference: Optional[str] = None
    dietary_restrictions: Optional[str] = None
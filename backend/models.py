from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Time, func, Index, Enum, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.schema import ForeignKey
from sqlalchemy.orm import declarative_base
import enum

### POINT OF ALL THIS: Much cleaner than doing SQL inquiries every time ###


#defining a db using python classes
Base = declarative_base()

class Gender(enum.Enum):
    male = "male"
    female = "female"
    other = "other"

class SocialPreference(enum.Enum):
    introvert = "introvert"
    extrovert = "extrovert"
    ambivert = "ambivert"

class MatchStatus(enum.Enum):
    pending = "pending"  # Initial state when one user likes another
    matched = "matched"  # When both users have liked each other
    rejected = "rejected"  # When one user rejects the other
    blocked = "blocked"  # When one user blocks the other

class UserPreferences(Base):
    __tablename__ = "user_preferences"
    
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    
    # Attribute importance (0.0 to 1.0, where 1.0 is extremely important)
    cleanliness_importance = Column(Float, default=0.8)  # Default high as per your requirements
    sleep_schedule_importance = Column(Float, default=0.7)
    guest_policy_importance = Column(Float, default=0.6)
    room_type_importance = Column(Float, default=0.5)
    religious_importance = Column(Float, default=0.5)
    dietary_importance = Column(Float, default=0.5)
    
    # Preferred values (updated based on swiped profiles)
    preferred_cleanliness = Column(Float, default=5.0)  # 1-10 scale
    
    # Guest policy preference weights stored as JSON
    # Example: {"frequent": 0.8, "occasional": 0.5, "rare": 0.2, "none": 0.0}
    guest_policy_weights = Column(JSON, default=dict)
    
    # Room type preference weights stored as JSON
    # Example: {"2-person": 0.7, "3-person": 0.5, "4-person": 0.3, "5-person": 0.1}
    room_type_weights = Column(JSON, default=dict)
    
    # Religious preference weights stored as JSON
    religious_weights = Column(JSON, default=dict)
    
    # Dietary restriction weights stored as JSON
    dietary_weights = Column(JSON, default=dict)
    
    # Rejection cooldown period in days (how long before showing rejected profiles again)
    rejection_cooldown = Column(Integer, default=30)
    
    # Last updated timestamp
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationship
    user = relationship("User", backref="preferences")

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    fullname = Column(String, nullable=True) 
    instagram = Column(String, nullable=True)  # now nullable
    profile_picture = Column(String, nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(Enum(Gender), nullable=True, index=True)
    university = Column(String, nullable=True, index=True)
    major = Column(String, nullable=True)
    year_of_study = Column(Integer, nullable=True)
    budget_range = Column(Integer, nullable=True, index=True)
    move_in_date = Column(DateTime, nullable=True)  # now nullable
    smoking_preference = Column(Boolean, nullable=True, index=True)
    drinking_preference = Column(Boolean, nullable=True, index=True)
    pet_preference = Column(Boolean, nullable=True, index=True)
    cleanliness_level = Column(Integer, nullable=True, index=True)
    social_preference = Column(Enum(SocialPreference), nullable=True, index=True)
    snapchat = Column(String, nullable=True)
    sleep_time = Column(Time, nullable=True)  # This field was renamed from bedtime in the database
    wake_time = Column(Time, nullable=True)   # Added for compatibility matching
    phone_number = Column(String, nullable=True)
    bio = Column(String, unique=False, nullable=True)
    music_preference = Column(Boolean, nullable=True, index=True)
    
    # New fields for enhanced matching
    guest_policy = Column(String, nullable=True)
    room_type_preference = Column(String, nullable=True)
    religious_preference = Column(String, nullable=True)
    dietary_restrictions = Column(String, nullable=True)
    
    # Add composite indexes for common query patterns
    __table_args__ = (
    Index('idx_user_preferences', 'university', 'budget_range', 'smoking_preference', 'drinking_preference', 'pet_preference'),
    Index('idx_user_compatibility', 'cleanliness_level', 'social_preference', 'sleep_time'),  # Updated from bedtime to sleep_time
    Index('idx_user_enhanced_matching', 'gender', 'cleanliness_level'),
)

    # Relationships
    sent_matches = relationship("RoommateMatch", foreign_keys="RoommateMatch.user1_id", back_populates="user1")
    received_matches = relationship("RoommateMatch", foreign_keys="RoommateMatch.user2_id", back_populates="user2")

class RoommateMatch(Base):
    __tablename__ = "roommate_matches"
    
    id = Column(Integer, primary_key=True, index=True)
    user1_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    user2_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    compatibility_score = Column(Float, nullable=False, index=True)
    match_status = Column(Enum(MatchStatus), nullable=False, default=MatchStatus.pending, index=True)
    
    # Track only essential user interactions
    user1_liked = Column(Boolean, default=False)
    user2_liked = Column(Boolean, default=False)
    
    # Track timestamps for match lifecycle
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    rejected_at = Column(DateTime, nullable=True)  # When the match was rejected, for cooldown implementation
    
    # Relationships
    user1 = relationship("User", foreign_keys=[user1_id], back_populates="sent_matches")
    user2 = relationship("User", foreign_keys=[user2_id], back_populates="received_matches")

    # Add composite indexes for common query patterns
    __table_args__ = (
        Index('idx_match_status_score', 'match_status', 'compatibility_score'),
        Index('idx_match_users', 'user1_id', 'user2_id'),
        Index('idx_match_cooldown', 'rejected_at'),
    )

"""
class Favorite(Base):
    __tablename__ = "favorites"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    chain_id = Column(Integer, ForeignKey("restaurants.chain_id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    class Restaurant(Base):
    __tablename__ = "restaurants"

    chain_id = Column(Integer, primary_key=True, index=True)  # ✅ Matches your actual DB schema
    name = Column(String, nullable=False)
    cuisine1 = Column(String, nullable=False)
    cuisine2 = Column(String, nullable=True)
    instagram = Column(String, nullable=True)
    website = Column(String, nullable=True)
    veg_vegan = Column(Boolean, nullable=True)
    avg_rating = Column(Float, nullable=True)

    favorited_by = relationship("User", secondary="favorites", back_populates="favorites")

class Location(Base):
    __tablename__ = "locations"

    location_id = Column(Integer, primary_key=True, index=True)
    chain_id = Column(Integer, ForeignKey("restaurants.chain_id"))  # ✅ Links to restaurants table
    location = Column(String, nullable=False)
    google_maps = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    delivery = Column(Boolean, nullable=True)
    rating = Column(Float, nullable=True)

"""
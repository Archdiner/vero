from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Time, func, Index, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.schema import ForeignKey
from sqlalchemy.orm import declarative_base
import enum

### POINT OF ALL THIS: Much cleaner than doing SQL inquiries every time ###


#defining a db using python classes
Base = declarative_base()

class Gender(enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"

class SocialPreference(enum.Enum):
    INTROVERT = "introvert"
    EXTROVERT = "extrovert"
    AMBIVERT = "ambivert"

class MatchStatus(enum.Enum):
    PENDING = "pending"  # Initial state when one user likes another
    MATCHED = "matched"  # When both users have liked each other
    REJECTED = "rejected"  # When one user rejects the other
    BLOCKED = "blocked"  # When one user blocks the other

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    fullname = Column(String, nullable=True) 
    username = Column(String, unique=True, nullable=True, index=True) 
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
    bedtime = Column(Time, nullable=True)
    phone_number = Column(String, nullable=True)
    bio = Column(String, unique=False, nullable=False)

    # Add composite indexes for common query patterns
    __table_args__ = (
        Index('idx_user_preferences', 'university', 'budget_range', 'smoking_preference', 'drinking_preference', 'pet_preference'),
        Index('idx_user_compatibility', 'cleanliness_level', 'social_preference', 'bedtime'),
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
    match_status = Column(Enum(MatchStatus), nullable=False, default=MatchStatus.PENDING, index=True)
    
    # Track only essential user interactions
    user1_liked = Column(Boolean, default=False)
    user2_liked = Column(Boolean, default=False)
    
    # Track only when the match was created
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    
    # Relationships
    user1 = relationship("User", foreign_keys=[user1_id], back_populates="sent_matches")
    user2 = relationship("User", foreign_keys=[user2_id], back_populates="received_matches")

    # Add composite indexes for common query patterns
    __table_args__ = (
        Index('idx_match_status_score', 'match_status', 'compatibility_score'),
        Index('idx_match_users', 'user1_id', 'user2_id'),
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
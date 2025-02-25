from sqlalchemy import Column, Integer, String, Float, Boolean 
from sqlalchemy.orm import relationship
from sqlalchemy.schema import ForeignKey
from sqlalchemy.orm import declarative_base

### POINT OF ALL THIS: Much cleaner than doing SQL inquiries every time ###


#defining a db using python classes
Base = declarative_base()

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

class Location(Base):
    __tablename__ = "locations"

    location_id = Column(Integer, primary_key=True, index=True)
    chain_id = Column(Integer, ForeignKey("restaurants.chain_id"))  # ✅ Links to restaurants table
    location = Column(String, nullable=False)
    google_maps = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    delivery = Column(Boolean, nullable=True)
    rating = Column(Float, nullable=True)

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)

class Favorite(Base):
    __tablename__ = "favorites"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    chain_id = Column(Integer, ForeignKey("restaurants.chain_id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
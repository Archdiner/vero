from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from db import get_db, engine
from models import User, RoommateMatch, MatchStatus, Base, UserPreferences
from schemas import UserCreate, UserLogin, UserResponse, Token, UserOnboarding, UserProfileUpdate, PreferencesUpdate
from utils.auth_utils import hash_password, verify_password, create_access_token, decode_access_token
from utils.match_utils import compute_compatibility_score, update_matches, update_user_preferences
from utils.optimized_queries import get_potential_roommates_optimized, get_matches_optimized, get_user_profile_optimized
import jwt
from datetime import datetime, timedelta

app = FastAPI()

origins = [
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",
    "http://localhost:52425",  # Flutter web frontend
    "http://localhost:52762",  # Add port from error message
    "http://127.0.0.1:52762",  # Also add with IP
    "https://roomio.fly.dev"   # Add production domain
]

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # Use the origins list instead of "*"
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create the tables if they don't exist
Base.metadata.create_all(bind=engine)

@app.get("/")
def home():
    return {"message": "Welcome to Roommate Finder!"}

@app.get("/potential_roommates")
def get_potential_roommates(
    offset: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db),
    Authorization: str = Header(None)
):
    # Validate the token and get the current user's ID
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )
    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        current_user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Use optimized query function
    return get_potential_roommates_optimized(
        current_user_id=current_user_id,
        offset=offset,
        limit=limit,
        db=db
    )


@app.post("/like/{roommate_id}")
def like_roommate(
    roommate_id: int,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Debug log the like action
    print(f"User {user_id} is liking roommate {roommate_id}")

    # Check if roommate exists
    roommate = db.query(User).filter(User.id == roommate_id).first()
    if not roommate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roommate not found"
        )

    # Check if match already exists
    existing_match = db.query(RoommateMatch).filter(
        or_(
            and_(RoommateMatch.user1_id == user_id, RoommateMatch.user2_id == roommate_id),
            and_(RoommateMatch.user1_id == roommate_id, RoommateMatch.user2_id == user_id)
        )
    ).first()

    is_match = False
    if existing_match:
        # Debug log the existing match
        print(f"Found existing match record: user1={existing_match.user1_id}, user2={existing_match.user2_id}, status={existing_match.match_status.value}")
        print(f"Current likes status: user1_liked={existing_match.user1_liked}, user2_liked={existing_match.user2_liked}")
        
        # Update existing match
        if existing_match.user1_id == user_id:
            existing_match.user1_liked = True
            if existing_match.user2_liked:
                existing_match.match_status = MatchStatus.matched
                is_match = True
                print(f"It's a match! Both users liked each other.")
            else:
                print(f"User {user_id} liked user {roommate_id}, waiting for them to like back")
        else:
            existing_match.user2_liked = True
            if existing_match.user1_liked:
                existing_match.match_status = MatchStatus.matched
                is_match = True
                print(f"It's a match! Both users liked each other.")
            else:
                print(f"User {user_id} liked user {roommate_id}, waiting for them to like back")
    else:
        # Create new match
        new_match = RoommateMatch(
            user1_id=user_id,
            user2_id=roommate_id,
            compatibility_score=compute_compatibility_score(
                db.query(User).filter(User.id == user_id).first(),
                roommate
            ),
            match_status=MatchStatus.pending,
            user1_liked=True
        )
        db.add(new_match)
        print(f"Created new match record: user1={user_id}, user2={roommate_id}, status=pending")

    # Update the user preferences based on this like
    update_user_preferences(user_id, roommate_id, liked=True, db=db)

    db.commit()
    return {"message": "Roommate liked successfully", "is_match": is_match}

@app.post("/reject/{roommate_id}")
def reject_roommate(
    roommate_id: int,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Check if roommate exists
    roommate = db.query(User).filter(User.id == roommate_id).first()
    if not roommate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roommate not found"
        )

    # Check if match already exists
    existing_match = db.query(RoommateMatch).filter(
        or_(
            and_(RoommateMatch.user1_id == user_id, RoommateMatch.user2_id == roommate_id),
            and_(RoommateMatch.user1_id == roommate_id, RoommateMatch.user2_id == user_id)
        )
    ).first()

    if existing_match:
        # Update existing match status to rejected
        existing_match.match_status = MatchStatus.rejected
        # Set the rejection timestamp for cooldown period
        existing_match.rejected_at = func.now()
    else:
        # Create new rejected match
        new_match = RoommateMatch(
            user1_id=user_id,
            user2_id=roommate_id,
            compatibility_score=0,
            match_status=MatchStatus.rejected,
            rejected_at=func.now()  # Set the rejection timestamp
        )
        db.add(new_match)

    # Update the user preferences based on this rejection
    update_user_preferences(user_id, roommate_id, liked=False, db=db)

    db.commit()
    return {"message": "Roommate rejected successfully"}

@app.post("/unmatch/{roommate_id}")
def unmatch_roommate(
    roommate_id: int,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Debug log the unmatch action
    print(f"User {user_id} is unmatching from roommate {roommate_id}")

    # Check if match exists
    existing_match = db.query(RoommateMatch).filter(
        or_(
            and_(RoommateMatch.user1_id == user_id, RoommateMatch.user2_id == roommate_id),
            and_(RoommateMatch.user1_id == roommate_id, RoommateMatch.user2_id == user_id)
        )
    ).first()

    if not existing_match:
        print(f"No match record found between users {user_id} and {roommate_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )

    # Log the current state of the match
    print(f"Current match state: status={existing_match.match_status.value}, " +
          f"user1_liked={existing_match.user1_liked}, user2_liked={existing_match.user2_liked}")

    # Check if it's a valid state to unmatch (either pending or matched)
    if existing_match.match_status not in [MatchStatus.pending, MatchStatus.matched]:
        print(f"Cannot unmatch users in current state: {existing_match.match_status.value}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot unmatch from this user in the current state"
        )

    # Update match status to rejected for cooldown
    existing_match.match_status = MatchStatus.rejected
    existing_match.rejected_at = func.now()  # Set rejection timestamp for cooldown

    # Reset the likes to allow potential future matching after cooldown
    if existing_match.user1_id == user_id:
        existing_match.user1_liked = False
        print(f"User {user_id} (user1) is unmatching from user {roommate_id} (user2)")
    else:
        existing_match.user2_liked = False
        print(f"User {user_id} (user2) is unmatching from user {roommate_id} (user1)")

    print(f"Updated match status to rejected, it will re-appear after the cooldown period")

    db.commit()
    return {"message": "Successfully unmatched"}

@app.get("/matches")
def get_matches(
    include_preferences: bool = False,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Use optimized query function
    return get_matches_optimized(
        current_user_id=user_id,
        include_preferences=include_preferences,
        db=db
    )

@app.post("/register", response_model=Token)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
    
    # Create new user
    new_user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        fullname = user_data.fullname
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    user = db.query(User).filter(User.email == user_data.email).first()

    access_token = create_access_token(data={"user_id": user.id})
    print(f"Access Token stored: {access_token}")
    return {
        "access_token": access_token, 
        "token_type": "bearer"
    }

@app.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    # Verify password
    if not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    # Create a single access_token
    access_token = create_access_token(data={"user_id": user.id})
    print(f"Access Token stored: {access_token}")
    return {
        "access_token": access_token, 
        "token_type": "bearer"
    }

@app.get("/profile")
def get_profile(Authorization: str = Header(None), db: Session = Depends(get_db)):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    print(f"Access Token stored: {token}")

    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Return user information
    return user

@app.post("/update_profile")
def update_profile(
    update_data: UserProfileUpdate,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    # Validate the token
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )
    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update profile fields if provided.
    if update_data.fullname is not None:
        user.fullname = update_data.fullname
    if update_data.email is not None:
        user.email = update_data.email
    if update_data.age is not None:
        user.age = update_data.age
    if update_data.year_of_study is not None:
        user.year_of_study = update_data.year_of_study
    if update_data.instagram is not None:
        user.instagram = update_data.instagram
    if update_data.snapchat is not None:
        user.snapchat = update_data.snapchat
    if update_data.phone_number is not None:
        user.phone_number = update_data.phone_number
    if update_data.gender is not None:
        # Optionally, you could enforce lowercase to match your enum values.
        user.gender = update_data.gender.lower()
    
    # Handle password update if new_password is provided.
    if update_data.new_password is not None:
        if not update_data.old_password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Old password is required to update password"
            )
        if not verify_password(update_data.old_password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Old password is incorrect"
            )
        user.hashed_password = hash_password(update_data.new_password)
    
    db.commit()
    db.refresh(user)

    update_matches(user_id, db)
    
    return {"message": "Profile updated successfully"}


@app.post("/update_preferences")
def update_preferences(
    pref_update: PreferencesUpdate,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    # Validate token
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing or invalid token")
    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    # Update preferences if provided
    if pref_update.budget_range is not None:
        user.budget_range = pref_update.budget_range
    if pref_update.move_in_date is not None:
        user.move_in_date = pref_update.move_in_date
    if pref_update.smoking_preference is not None:
        user.smoking_preference = pref_update.smoking_preference
    if pref_update.drinking_preference is not None:
        user.drinking_preference = pref_update.drinking_preference
    if pref_update.pet_preference is not None:
        user.pet_preference = pref_update.pet_preference
    if pref_update.music_preference is not None:
        user.music_preference = pref_update.music_preference
    if pref_update.cleanliness_level is not None:
        user.cleanliness_level = pref_update.cleanliness_level
    if pref_update.social_preference is not None:
        user.social_preference = pref_update.social_preference.lower()
    if pref_update.sleep_time is not None:
        try:
            user.sleep_time = datetime.strptime(pref_update.sleep_time, "%H:%M").time()
        except ValueError:
            # If the input is in HH:MM:SS format, take only the first 5 characters.
            try:
                user.sleep_time = datetime.strptime(pref_update.sleep_time[:5], "%H:%M").time()
            except Exception:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid sleep time format")

    if pref_update.guest_policy is not None:
        user.guest_policy = pref_update.guest_policy
    if pref_update.room_type_preference is not None:
        user.room_type_preference = pref_update.room_type_preference
    if pref_update.religious_preference is not None:
        user.religious_preference = pref_update.religious_preference
    if pref_update.dietary_restrictions is not None:
        user.dietary_restrictions = pref_update.dietary_restrictions

    db.commit()
    db.refresh(user)

    update_matches(user_id, db)
    
    return {"message": "Preferences updated successfully"}


@app.get("/auth/profile")
def get_auth_profile(Authorization: str = Header(None), db: Session = Depends(get_db)):
    # This is a duplicate of the /profile endpoint, but with a different URL path
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]

    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Return expanded user information including profile picture
    return {
        "id": user.id,
        "email": user.email,
        "fullname": user.fullname,
        "profile_picture": user.profile_picture,
        "instagram": user.instagram,
        "university": user.university,
        "age": user.age,
        "gender": user.gender.value if user.gender else None,
        "major": user.major,
        "year_of_study": user.year_of_study,
        "bio": user.bio
    }

@app.get("/verify_token")
def verify_token(Authorization: str = Header(None)):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        return {"valid": True, "user_id": payload.get("user_id")}
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

@app.get("/get_user_name")
def get_user_name(Authorization: str = Header(None), db: Session = Depends(get_db)):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Split the fullname and get the first name
        first_name = user.fullname.split()[0]
        return {"first_name": first_name}

    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
@app.post("/onboarding")
def update_onboarding(
    onboarding_data: UserOnboarding,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    # Validate and decode the access token
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )
    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    # Retrieve the current user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update user with provided onboarding data
    update_data = onboarding_data.dict(exclude_unset=True)
    
    # Debug print for troubleshooting
    print(f"Received update data: {update_data}")
    
    for key, value in update_data.items():
        if key == "gender" or key == "social_preference":
            value = value[0].lower() + value[1::]
        
        # Debug print for each field being processed
        print(f"Setting {key} = {value}")
        
        setattr(user, key, value)

    # Commit changes and refresh the user from the database
    db.commit()
    db.refresh(user)
    
    # Debug print the updated user data
    print(f"Updated user: profile_picture={user.profile_picture}, instagram={user.instagram}")

    update_matches(user_id, db)

    return {"message": "Onboarding data updated successfully"}

@app.post("/auth/update-onboarding")
def update_onboarding_auth(
    onboarding_data: UserOnboarding,
    Authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    # Validate and decode the access token
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )
    token = Authorization.split("Bearer ")[1]
    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    # Retrieve the current user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update user with provided onboarding data
    update_data = onboarding_data.dict(exclude_unset=True)
    
    # Convert field names from frontend naming to backend model naming
    field_mappings = {
        "instagram_username": "instagram",
        "snapchat_username": "snapchat",
        "profile_picture": "profile_picture"  # Add explicit mapping for profile_picture
    }
    
    # Debug print for troubleshooting
    print(f"Received update data: {update_data}")
    
    for key, value in update_data.items():
        # Map frontend field names to backend model field names if needed
        model_key = field_mappings.get(key, key)
        
        # Special handling for enum fields
        if model_key == "gender" or model_key == "social_preference":
            if value:
                value = value[0].lower() + value[1::]
        
        # Debug print for each field being processed
        print(f"Setting {model_key} = {value} (from {key})")
        
        # Only set the attribute if the field exists in the user model
        if hasattr(user, model_key):
            setattr(user, model_key, value)

    # Commit changes and refresh the user from the database
    db.commit()
    db.refresh(user)

    # Debug print the updated user data
    print(f"Updated user: profile_picture={user.profile_picture}, instagram={user.instagram}")

    # Update matches for this user
    update_matches(user_id, db)

    return {"message": "Onboarding data updated successfully"}

@app.get("/profile/{user_id}")
def get_user_profile(
    user_id: int,
    include_preferences: bool = False,
    Authorization: str = Header(None), 
    db: Session = Depends(get_db)
):
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    token = Authorization.split("Bearer ")[1]

    try:
        payload = decode_access_token(token)
        current_user_id = payload.get("user_id")
        if not current_user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Use optimized query function
    user_data = get_user_profile_optimized(
        user_id=user_id,
        current_user_id=current_user_id,
        include_preferences=include_preferences,
        db=db
    )
    
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user_data

@app.get("/user/{user_id}")
def get_user_by_id(
    user_id: int,
    include_preferences: bool = True,  # Default to true for this endpoint
    Authorization: str = Header(None), 
    db: Session = Depends(get_db)
):
    """
    Alias for profile/{user_id} with preferences included by default.
    This endpoint is used by the mobile app for detailed user views.
    """
    return get_user_profile(user_id, include_preferences, Authorization, db)
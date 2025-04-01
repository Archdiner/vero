from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from db import get_db, engine
from models import User, RoommateMatch, MatchStatus, Base, UserPreferences
from schemas import UserCreate, UserLogin, UserResponse, Token, UserOnboarding
from utils.auth_utils import hash_password, verify_password, create_access_token, decode_access_token
from utils.match_utils import compute_compatibility_score, update_matches, update_user_preferences
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
    # "https://your-production-domain.com"
]

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Temporarily allow all origins for testing
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
    # 1. Validate the token and get the current user's ID.
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

    # Get current user
    current_user = db.query(User).filter(User.id == current_user_id).first()
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Ensure the user has preferences initialized
    user_prefs = db.query(UserPreferences).filter(UserPreferences.user_id == current_user_id).first()
    if not user_prefs:
        # Create default preferences if they don't exist
        user_prefs = UserPreferences(user_id=current_user_id)
        db.add(user_prefs)
        db.commit()
    
    # Calculate cooldown date based on user's preferences
    cooldown_days = user_prefs.rejection_cooldown
    cooldown_date = func.now() - timedelta(days=cooldown_days)
    
    # Get rejected user IDs that are still in cooldown period
    rejected_matches = db.query(RoommateMatch).filter(
        or_(
            and_(
                RoommateMatch.user1_id == current_user_id,
                RoommateMatch.match_status == MatchStatus.rejected,
                RoommateMatch.rejected_at > cooldown_date
            ),
            and_(
                RoommateMatch.user2_id == current_user_id,
                RoommateMatch.match_status == MatchStatus.rejected,
                RoommateMatch.rejected_at > cooldown_date
            )
        )
    ).all()
    
    # Extract IDs of users in cooldown period
    rejected_user_ids = []
    for match in rejected_matches:
        if match.user1_id == current_user_id:
            rejected_user_ids.append(match.user2_id)
        else:
            rejected_user_ids.append(match.user1_id)
    
    # Get already matched users
    matched_users = db.query(RoommateMatch).filter(
        or_(
            and_(
                RoommateMatch.user1_id == current_user_id,
                RoommateMatch.match_status == MatchStatus.matched
            ),
            and_(
                RoommateMatch.user2_id == current_user_id,
                RoommateMatch.match_status == MatchStatus.matched
            )
        )
    ).all()
    
    # Extract IDs of already matched users
    matched_user_ids = []
    for match in matched_users:
        if match.user1_id == current_user_id:
            matched_user_ids.append(match.user2_id)
        else:
            matched_user_ids.append(match.user1_id)
    
    # Get users who the current user has already liked but no match yet
    # These are users where current_user is user1 and has liked
    already_liked_users = db.query(RoommateMatch).filter(
        and_(
            RoommateMatch.user1_id == current_user_id,
            RoommateMatch.user1_liked == True,
            RoommateMatch.match_status == MatchStatus.pending
        )
    ).all()
    
    # Also check for cases where current_user is user2 and has liked
    already_liked_users_as_user2 = db.query(RoommateMatch).filter(
        and_(
            RoommateMatch.user2_id == current_user_id,
            RoommateMatch.user2_liked == True,
            RoommateMatch.match_status == MatchStatus.pending
        )
    ).all()
    
    # Extract IDs of users you've already liked
    already_liked_user_ids = []
    for match in already_liked_users:
        already_liked_user_ids.append(match.user2_id)
    
    for match in already_liked_users_as_user2:
        already_liked_user_ids.append(match.user1_id)
    
    # Get users who've liked the current user but current user hasn't responded
    # These should still appear in the swiping queue
    users_who_liked_you = db.query(RoommateMatch).filter(
        and_(
            RoommateMatch.user2_id == current_user_id,
            RoommateMatch.user1_liked == True,
            RoommateMatch.user2_liked == False,  # You haven't responded yet
            RoommateMatch.match_status == MatchStatus.pending
        )
    ).all()
    
    # Also check for cases where current_user is user1
    users_who_liked_you_as_user1 = db.query(RoommateMatch).filter(
        and_(
            RoommateMatch.user1_id == current_user_id,
            RoommateMatch.user2_liked == True,
            RoommateMatch.user1_liked == False,  # You haven't responded yet
            RoommateMatch.match_status == MatchStatus.pending
        )
    ).all()
    
    # Extract IDs of users who've liked you (should still show in queue)
    users_who_liked_you_ids = []
    for match in users_who_liked_you:
        users_who_liked_you_ids.append(match.user1_id)
    
    for match in users_who_liked_you_as_user1:
        users_who_liked_you_ids.append(match.user2_id)
    
    # Combine all IDs of users to exclude (rejected, matched, and already liked)
    # But keep users who've liked you but you haven't responded to
    excluded_user_ids = rejected_user_ids + matched_user_ids + already_liked_user_ids
    
    # Debug logging
    print(f"Excluded users: {len(excluded_user_ids)} total")
    print(f"- Rejected users in cooldown: {len(rejected_user_ids)}")
    print(f"- Already matched users: {len(matched_user_ids)}")
    print(f"- Users you've already liked: {len(already_liked_user_ids)}")
    print(f"- Users who've liked you (still showing): {len(users_who_liked_you_ids)}")
    
    # Query potential matches - exclude rejected, matched, and already liked users
    all_users = db.query(User).filter(
        User.id != current_user_id,
        User.gender == current_user.gender,  # Same gender as per requirement
        ~User.id.in_(excluded_user_ids) if excluded_user_ids else True
    ).all()
    
    print(f"Found {len(all_users)} potential matches after filtering")
    
    # Calculate compatibility scores for all potential matches
    results = []
    for user in all_users:
        if user:
            # Calculate compatibility score
            compatibility_score = compute_compatibility_score(current_user, user)
            
            results.append({
                "id": user.id,
                "fullname": user.fullname,
                "age": user.age,
                "gender": user.gender.value if user.gender else None,
                "university": user.university,
                "major": user.major,
                "year_of_study": user.year_of_study,
                "bio": user.bio,
                "profile_picture": user.profile_picture,
                "compatibility_score": compatibility_score,
                "budget_range": user.budget_range,
                "cleanliness_level": user.cleanliness_level,
                "social_preference": user.social_preference.value if user.social_preference else None,
                "smoking_preference": user.smoking_preference,
                "drinking_preference": user.drinking_preference,
                "pet_preference": user.pet_preference,
                "music_preference": user.music_preference,
                "guest_policy": user.guest_policy,
                "room_type_preference": user.room_type_preference,
                "religious_preference": user.religious_preference,
                "dietary_restrictions": user.dietary_restrictions,
                "sleep_time": user.sleep_time.strftime("%H:%M") if user.sleep_time else None,
                "wake_time": user.wake_time.strftime("%H:%M") if user.wake_time else None
            })
    
    # Sort results by compatibility score (highest first)
    results.sort(key=lambda x: x["compatibility_score"], reverse=True)
    
    # Apply pagination
    paginated_results = results[offset:offset + limit]
    
    return paginated_results


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

    # Get all matches where both users liked each other
    matches = db.query(RoommateMatch).filter(
        and_(
            or_(
                RoommateMatch.user1_id == user_id,
                RoommateMatch.user2_id == user_id
            ),
            RoommateMatch.match_status == MatchStatus.matched
        )
    ).all()

    response = []
    for match in matches:
        # Determine which user is the other person
        other_user_id = match.user2_id if match.user1_id == user_id else match.user1_id
        other_user = db.query(User).filter(User.id == other_user_id).first()
        
        if other_user:
            # Create base response dictionary
            user_data = {
                "id": other_user.id,
                "fullname": other_user.fullname,
                "age": other_user.age,
                "gender": other_user.gender.value if other_user.gender else None,
                "major": other_user.major,
                "year_of_study": other_user.year_of_study,
                "bio": other_user.bio,
                "profile_picture": other_user.profile_picture,
                "compatibility_score": match.compatibility_score,
                "university": other_user.university,
                "instagram": other_user.instagram,
                "created_at": match.created_at.isoformat() if match.created_at else None,
                "match_status": match.match_status.value
            }
            
            # If include_preferences flag is set, add preference data
            if include_preferences:
                preference_data = {
                    "budget_range": other_user.budget_range,
                    "cleanliness_level": other_user.cleanliness_level,
                    "social_preference": other_user.social_preference.value if other_user.social_preference else None,
                    "smoking_preference": other_user.smoking_preference,
                    "drinking_preference": other_user.drinking_preference,
                    "pet_preference": other_user.pet_preference,
                    "music_preference": other_user.music_preference,
                    "guest_policy": other_user.guest_policy,
                    "room_type_preference": other_user.room_type_preference,
                    "religious_preference": other_user.religious_preference,
                    "dietary_restrictions": other_user.dietary_restrictions,
                    "sleep_time": other_user.sleep_time.strftime("%H:%M") if other_user.sleep_time else None,
                    "wake_time": other_user.wake_time.strftime("%H:%M") if other_user.wake_time else None
                }
                # Add preference data to the response
                user_data.update(preference_data)
            
            response.append(user_data)

    return response

@app.post("/register", response_model=Token)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
    
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this username already exists"
        )

    # Create new user
    new_user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        fullname = user_data.fullname,
        username = user_data.username
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

    # Return expanded user information including profile picture
    return {
        "id": user.id,
        "email": user.email,
        "fullname": user.fullname,
        "username": user.username,
        "profile_picture": user.profile_picture,
        "instagram": user.instagram,
        "university": user.university,
        "age": user.age,
        "gender": user.gender.value if user.gender else None,
        "major": user.major,
        "year_of_study": user.year_of_study,
        "bio": user.bio
    }

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
        "username": user.username,
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
        first_name = user.fullname.split()[0] if user.fullname else user.username
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

    # Check if the requested user exists
    requested_user = db.query(User).filter(User.id == user_id).first()
    if not requested_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Create base response with user information
    user_data = {
        "id": requested_user.id,
        "fullname": requested_user.fullname,
        "username": requested_user.username,
        "profile_picture": requested_user.profile_picture,
        "instagram": requested_user.instagram,
        "university": requested_user.university,
        "age": requested_user.age,
        "gender": requested_user.gender.value if requested_user.gender else None,
        "major": requested_user.major,
        "year_of_study": requested_user.year_of_study,
        "bio": requested_user.bio
    }
    
    # Add preference data if requested
    if include_preferences:
        # Calculate compatibility score if this is not the current user
        compatibility_score = None
        if user_id != current_user_id:
            current_user = db.query(User).filter(User.id == current_user_id).first()
            if current_user:
                compatibility_score = compute_compatibility_score(current_user, requested_user)
        
        preference_data = {
            "budget_range": requested_user.budget_range,
            "cleanliness_level": requested_user.cleanliness_level,
            "social_preference": requested_user.social_preference.value if requested_user.social_preference else None,
            "smoking_preference": requested_user.smoking_preference,
            "drinking_preference": requested_user.drinking_preference,
            "pet_preference": requested_user.pet_preference,
            "music_preference": requested_user.music_preference,
            "guest_policy": requested_user.guest_policy,
            "room_type_preference": requested_user.room_type_preference,
            "religious_preference": requested_user.religious_preference,
            "dietary_restrictions": requested_user.dietary_restrictions,
            "sleep_time": requested_user.sleep_time.strftime("%H:%M") if requested_user.sleep_time else None,
            "wake_time": requested_user.wake_time.strftime("%H:%M") if requested_user.wake_time else None
        }
        
        if compatibility_score is not None:
            preference_data["compatibility_score"] = compatibility_score
            
        user_data.update(preference_data)
    
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
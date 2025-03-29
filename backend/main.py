from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from db import get_db, engine
from models import User, RoommateMatch, MatchStatus, Base
from schemas import UserCreate, UserLogin, UserResponse, Token, UserOnboarding
from auth_utils import hash_password, verify_password, create_access_token, decode_access_token
import jwt

origins = [
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",
    "http://localhost:52425",  # Flutter web frontend
    "http://localhost:52762",  # Add port from error message
    "http://127.0.0.1:52762",  # Also add with IP
    # "https://your-production-domain.com"
]

app = FastAPI()

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

from fastapi import FastAPI, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from db import get_db, engine
from models import User, RoommateMatch, MatchStatus, Base
from auth_utils import decode_access_token
import datetime

app = FastAPI()

# Helper function: Compute compatibility score between two users.
def compute_compatibility_score(user1: User, user2: User) -> float:
    score_sum = 0.0
    total_weight = 0.0

    # Helper to add a factor if available.
    def add_factor(condition: bool, weight: float):
        nonlocal score_sum, total_weight
        score_sum += (1.0 if condition else 0.0) * weight
        total_weight += weight

    def add_numeric_factor(val1, val2, max_diff: float, weight: float):
        nonlocal score_sum, total_weight
        if val1 is not None and val2 is not None:
            diff = abs(val1 - val2)
            factor_score = max(0, 1 - diff / max_diff)
            score_sum += factor_score * weight
            total_weight += weight

    def add_time_factor(time1, time2, max_diff_minutes: float, weight: float):
        nonlocal score_sum, total_weight
        if time1 and time2:
            t1 = time1.hour * 60 + time1.minute
            t2 = time2.hour * 60 + time2.minute
            diff = abs(t1 - t2)
            factor_score = max(0, 1 - diff / max_diff_minutes)
            score_sum += factor_score * weight
            total_weight += weight

    def add_date_factor(date1, date2, max_diff_days: float, weight: float):
        nonlocal score_sum, total_weight
        if date1 and date2:
            diff_days = abs((date1 - date2).days)
            factor_score = max(0, 1 - diff_days / max_diff_days)
            score_sum += factor_score * weight
            total_weight += weight

    # Factor 1: Age difference (assume max 10 years difference)
    if user1.age is not None and user2.age is not None:
        add_numeric_factor(user1.age, user2.age, max_diff=10, weight=0.1)

    # Factor 2: Smoking preference (boolean, weight 0.1)
    if user1.smoking_preference is not None and user2.smoking_preference is not None:
        add_factor(user1.smoking_preference == user2.smoking_preference, weight=0.1)

    # Factor 3: Drinking preference (boolean, weight 0.1)
    if user1.drinking_preference is not None and user2.drinking_preference is not None:
        add_factor(user1.drinking_preference == user2.drinking_preference, weight=0.1)

    # Factor 4: Pet preference (boolean, weight 0.1)
    if user1.pet_preference is not None and user2.pet_preference is not None:
        add_factor(user1.pet_preference == user2.pet_preference, weight=0.05)

    if user1.music_preference is not None and user2.music_preference is not None:
        add_factor(user1.music_preference == user2.music_preference, weight=0.05)

    # Factor 5: Cleanliness level (scale 1-10, weight 0.15)
    if user1.cleanliness_level is not None and user2.cleanliness_level is not None:
        add_numeric_factor(user1.cleanliness_level, user2.cleanliness_level, max_diff=9, weight=0.15)

    # Factor 6: Social preference (string, weight 0.1)
    if user1.social_preference and user2.social_preference:
        add_factor(user1.social_preference.lower() == user2.social_preference.lower(), weight=0.1)

    # Factor 7: Bedtime (time, weight 0.15; assume maximum acceptable difference is 120 minutes)
    if user1.bedtime and user2.bedtime:
        add_time_factor(user1.bedtime, user2.bedtime, max_diff_minutes=120, weight=0.15)

    # Factor 8: Budget range (integer, weight 0.1; assume max difference 3000)
    if user1.budget_range is not None and user2.budget_range is not None:
        add_numeric_factor(user1.budget_range, user2.budget_range, max_diff=3000, weight=0.1)

    # Factor 9: Move-in date (optional; weight 0.1; assume max difference 60 days)
    if user1.move_in_date and user2.move_in_date:
        add_date_factor(user1.move_in_date, user2.move_in_date, max_diff_days=60, weight=0.1)

    # Normalize score (if no factors are available, return 0)
    if total_weight > 0:
        return score_sum / total_weight
    else:
        return 0.0

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

    # 2. Get the current user and their university.
    current_user = db.query(User).filter(User.id == current_user_id).first()
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Current user not found"
        )
    current_university = current_user.university

    # 3. Retrieve all other users in the same university.
    potential_users = db.query(User).filter(
        User.id != current_user_id,
        User.university == current_university
    ).all()

    results = []
    # 4. Calculate compatibility score for each potential roommate.
    for other in potential_users:
        score = compute_compatibility_score(current_user, other)

        # 5. Update (or create) a record in RoommateMatch for this pair.
        existing_match = db.query(RoommateMatch).filter(
            or_(
                and_(RoommateMatch.user1_id == current_user_id, RoommateMatch.user2_id == other.id),
                and_(RoommateMatch.user1_id == other.id, RoommateMatch.user2_id == current_user_id)
            )
        ).first()

        if existing_match:
            existing_match.compatibility_score = score
        else:
            new_match = RoommateMatch(
                user1_id=current_user_id,
                user2_id=other.id,
                compatibility_score=score,
                match_status=MatchStatus.PENDING
            )
            db.add(new_match)

        # Collect information to return.
        results.append({
            "id": other.id,
            "fullname": other.fullname,
            "age": other.age,
            "gender": other.gender.value if hasattr(other, "gender") and other.gender else None,
            "major": other.major,
            "year_of_study": other.year_of_study,
            "bio": other.bio,
            "profile_picture": other.profile_picture,
            "compatibility_score": score
        })

    # Commit changes (updates/inserts in RoommateMatch).
    db.commit()

    # 6. Sort the results by compatibility score in descending order,
    # apply offset and limit, then return.
    sorted_results = sorted(results, key=lambda x: x["compatibility_score"], reverse=True)
    return sorted_results[offset:offset + limit]


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
        # Update existing match
        if existing_match.user1_id == user_id:
            existing_match.user1_liked = True
            if existing_match.user2_liked:
                existing_match.match_status = MatchStatus.MATCHED
        else:
            existing_match.user2_liked = True
            if existing_match.user1_liked:
                existing_match.match_status = MatchStatus.MATCHED
    else:
        # Create new match
        new_match = RoommateMatch(
            user1_id=user_id,
            user2_id=roommate_id,
            compatibility_score=0,  # This should be calculated based on preferences
            match_status=MatchStatus.PENDING,
            user1_liked=True
        )
        db.add(new_match)

    db.commit()
    return {"message": "Roommate liked successfully"}

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
        existing_match.match_status = MatchStatus.REJECTED
    else:
        # Create new rejected match
        new_match = RoommateMatch(
            user1_id=user_id,
            user2_id=roommate_id,
            compatibility_score=0,
            match_status=MatchStatus.REJECTED
        )
        db.add(new_match)

    db.commit()
    return {"message": "Roommate rejected successfully"}

@app.get("/matches")
def get_matches(
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
            RoommateMatch.match_status == MatchStatus.MATCHED
        )
    ).all()

    response = []
    for match in matches:
        # Determine which user is the other person
        other_user_id = match.user2_id if match.user1_id == user_id else match.user1_id
        other_user = db.query(User).filter(User.id == other_user_id).first()
        
        if other_user:
            response.append({
                "id": other_user.id,
                "fullname": other_user.fullname,
                "age": other_user.age,
                "gender": other_user.gender.value if other_user.gender else None,
                "major": other_user.major,
                "year_of_study": other_user.year_of_study,
                "bio": other_user.bio,
                "profile_picture": other_user.profile_picture,
                "compatibility_score": match.compatibility_score
            })

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

    return {"id": user.id, "email": user.email, "fullname": user.fullname, "username": user.username}

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
    for key, value in update_data.items():
        if key == "gender" or key == "social_preference":
            value = value[0].lower() + value[1::]
        setattr(user, key, value)

    db.commit()
    db.refresh(user)
    return {"message": "Onboarding data updated successfully"}
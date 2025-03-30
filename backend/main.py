from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from db import get_db, engine
from models import User, RoommateMatch, MatchStatus, Base
from schemas import UserCreate, UserLogin, UserResponse, Token, UserOnboarding
from utils.auth_utils import hash_password, verify_password, create_access_token, decode_access_token
from utils.match_utils import compute_compatibility_score, update_matches
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

app = FastAPI()

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

    # ADD CODE HERE: Query the matches database to get the current user's matches.
    matches = db.query(RoommateMatch).filter(
        or_(
            RoommateMatch.user1_id == current_user_id,
            RoommateMatch.user2_id == current_user_id
        )
    ).all()

    results = []
    for match in matches:
        # Determine the other user in the match.
        other_user_id = match.user2_id if match.user1_id == current_user_id else match.user1_id
        other_user = db.query(User).filter(User.id == other_user_id).first()
        if other_user:
            results.append({
                "id": other_user.id,
                "fullname": other_user.fullname,
                "age": other_user.age,
                "gender": other_user.gender.value if hasattr(other_user, "gender") and other_user.gender else None,
                "major": other_user.major,
                "year_of_study": other_user.year_of_study,
                "bio": other_user.bio,
                "profile_picture": other_user.profile_picture,
                "compatibility_score": match.compatibility_score
            })

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

    update_matches(user_id, db)

    return {"message": "Onboarding data updated successfully"}
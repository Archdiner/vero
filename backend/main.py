from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func
from db import get_db
from models import User, Restaurant
from schemas import UserCreate, UserLogin, UserResponse
from fastapi import FastAPI, Depends, HTTPException, status
from auth_utils import hash_password, verify_password, create_access_token, decode_access_token
import jwt

origins = [
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",
    # "https://your-production-domain.com"
]

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # You can set ["*"] for dev, but limit in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "Welcome to Tinder for Restaurants!"}

@app.get("/restaurants")
def get_restaurants(offset: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    restaurants = db.query(
        Restaurant.chain_id,
        Restaurant.name,
        Restaurant.cuisine1,
        Restaurant.avg_rating
    ).order_by(func.random()).offset(offset).limit(limit).all()
    return [
        {
            "chain_id": r[0],
            "name": r[1],
            "cuisine1": r[2],
            "avg_rating": r[3]
        } for r in restaurants
    ]

@app.post("/register", response_model=UserResponse)
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
        hashed_password=hash_password(user_data.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

@app.post("/login")
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
    # 1) Check if header is present and well-formed
    if not Authorization or not Authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid token"
        )

    # 2) Extract the token
    token = Authorization.split("Bearer ")[1]
    print(f"Access Token stored: {token}")

    # 3) Decode the token
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

    # 4) Retrieve user based on payload
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

    # 5) Return user info
    return {"id": user.id, "email": user.email}

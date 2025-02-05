from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from db import get_db
from models import Restaurant

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Welcome to Tinder for Restaurants!"}

@app.get("/restaurants/")
def get_restaurants(db: Session = Depends(get_db)):
    restaurants = db.query(Restaurant.chain_id, Restaurant.name, Restaurant.cuisine1, Restaurant.avg_rating).limit(10).all()
    print("Fetched Restaurants:", restaurants)  # Add this for debugging

    # Convert list of tuples to list of dictionaries
    return [
        {
            "chain_id": r[0],
            "name": r[1],
            "cuisine1": r[2],
            "avg_rating": r[3]
        } for r in restaurants ]





from fastapi import FastAPI

app = FastAPI()  # Ensure this exists

@app.get("/")
def read_root():
    return {"message": "Hello, world! FastAPI is working!"}

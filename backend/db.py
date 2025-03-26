from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

#database url using my creds
# DATABASE_URL = "postgresql://postgres:sixofwhales1@localhost:5432/tinder_restaurants"

DATABASE_URL = "postgresql://postgres.jxbvzbsakvnscdhllkcq:Rahman_Gamwe11@aws-0-us-west-1.pooler.supabase.com:5432/postgres"




#make SQLAlchemy database engine
engine = create_engine(DATABASE_URL)

#make session factory (used to interact with the DB)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db  # Provide a database session
    finally:
        db.close()  # Ensure the session is closed after the request
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool

#database url using my creds
# DATABASE_URL = "postgresql://postgres:sixofwhales1@localhost:5432/tinder_restaurants"

DATABASE_URL = "postgresql://postgres.jxbvzbsakvnscdhllkcq:Rahman_Gamwe11@aws-0-us-west-1.pooler.supabase.com:5432/postgres?sslmode=require"

#make SQLAlchemy database engine with connection pooling
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,  # Number of connections to maintain in the pool
    max_overflow=20,  # Additional connections that can be created on demand
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600,  # Recycle connections after 1 hour
    echo=False  # Set to True for SQL query logging
)

#make session factory (used to interact with the DB)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db  # Provide a database session
    finally:
        db.close()  # Ensure the session is closed after the request
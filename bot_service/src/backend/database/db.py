from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# PostgreSQL connection parameters
# IMPORTANT: Update these values with your actual PostgreSQL connection details from pgAdmin
DB_CONFIG = {
    'dbname': 'common',            # The database name you want to connect to
    'user': 'root',            # Your PostgreSQL username
    'password': 'root',        # Your PostgreSQL password
    'host': 'localhost',           # The host where PostgreSQL is running
    'port': 5433,                  # PostgreSQL port
}

# Construct the database URL
DATABASE_URL = f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"

# Log the database URL (without password)
safe_url = f"postgresql://{DB_CONFIG['user']}:****@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"
logger.info(f"Connecting to database: {safe_url}")

# Create SQLAlchemy engine - ALWAYS use PostgreSQL
engine = create_engine(DATABASE_URL)
logger.info("Database engine created successfully")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

def get_db():
    """Get a database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    # Import models here to avoid circular imports
    from bills_api.models import Base
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")

from argparse import ArgumentParser
import os
import uvicorn
from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import sqlalchemy as sa
from dotenv import load_dotenv
import logging
from database.db import engine, init_db
# Import our modules
from database.db import engine, init_db
from bills_api import router as bills_router

# Configure basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Parse command line arguments
parser = ArgumentParser(description="Bills Upload Service")
parser.add_argument("-e", "--env", help="Path to .env file", default="./etc/.env")
args = parser.parse_args()
load_dotenv(args.env)

# Create FastAPI app
app = FastAPI(title="Bills Upload Service")
app_router = APIRouter()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app_router.get("/health")
async def health_check():
    try:
        # Check database connection
        with engine.connect() as connection:
            connection.execute(sa.text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"status": "unhealthy", "database": "disconnected", "error": str(e)}
        )

# Include routers
app.include_router(app_router, prefix="/api/v1")
app.include_router(bills_router, prefix="/api/v1/bills")

# Root redirect to docs
@app.get("/")
async def root():
    return {"message": "Welcome to Bills Upload Service API", "docs_url": "/docs"}

if __name__ == "__main__":
    # Initialize database
    init_db()
    
    # Run server
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8081"))
    uvicorn.run("main:app", host=host, port=port, reload=True)

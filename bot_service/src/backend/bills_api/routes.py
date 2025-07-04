from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from typing import List
import os
import logging

from bills_api.models import BillResponse
from bills_api.service import BillService
from database.db import get_db

logger = logging.getLogger(__name__)

# Initialize the router
router = APIRouter()

# Initialize the bill service
bill_service = BillService()

@router.post("/upload", response_model=BillResponse)
async def upload_bill(
    file: UploadFile = File(...),
    force: bool = False,
    db: Session = Depends(get_db)
):
    """
    Upload a PDF bill, process it with LLM, and store the extracted data
    """
    try:
        # Validate file is PDF
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are allowed")
        
        # Create upload directory
        os.makedirs("uploads", exist_ok=True)
        file_path = f"uploads/{file.filename}"
        
        # Save the file
        with open(file_path, "wb") as f:
            f.write(await file.read())
        
        # Process the bill
        bill = await bill_service.upload_bill(db, file_path, force)
        return bill
    except ValueError as e:
        logger.error(f"Value error during bill processing: {str(e)}")
        # Clean up uploaded file on error
        if os.path.exists(file_path):
            os.remove(file_path)
        
        # Check if this is a duplicate bill error
        error_message = str(e)
        if "Duplicate bill detected" in error_message:
            raise HTTPException(status_code=409, detail=error_message)
        else:
            raise HTTPException(status_code=400, detail=f"Error processing bill data: {error_message}")
    except Exception as e:
        logger.error(f"Unexpected error uploading bill: {str(e)}")
        # Clean up uploaded file on error
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Error uploading bill: {str(e)}")

@router.get("/", response_model=List[BillResponse])
def get_bills(
    skip: int = 0, 
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all bills with their transactions
    """
    try:
        bills = bill_service.get_bills(db, skip, limit)
        return bills
    except Exception as e:
        logger.error(f"Error fetching bills: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching bills: {str(e)}")

@router.get("/{bill_id}", response_model=BillResponse)
def get_bill(
    bill_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific bill by ID
    """
    try:
        bill = bill_service.get_bill(db, bill_id)
        if not bill:
            raise HTTPException(status_code=404, detail="Bill not found")
        return bill
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching bill: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching bill: {str(e)}")

@router.delete("/{bill_id}")
def delete_bill(
    bill_id: int,
    db: Session = Depends(get_db)
):
    """
    Delete a bill and its associated file
    """
    try:
        success = bill_service.delete_bill(db, bill_id)
        if not success:
            raise HTTPException(status_code=404, detail="Bill not found")
        return {"message": "Bill deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting bill: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting bill: {str(e)}")

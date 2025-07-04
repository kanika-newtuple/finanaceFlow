from sqlalchemy.orm import Session
from typing import List, Optional
import os
import logging
from datetime import datetime

from bills_api.models import Bill, Transaction, BillCreate
from LLM.pdf_processor import PDFProcessor

logger = logging.getLogger(__name__)

class BillService:
    """Service for handling bill operations"""
    
    def __init__(self, openai_api_key: Optional[str] = None):
        """Initialize the bill service"""
        self.pdf_processor = PDFProcessor(openai_api_key)
    
    async def upload_bill(self, db: Session, file_path: str) -> Bill:
        """Process a PDF bill and save it to the database with enhanced information"""
        try:
            # Process the PDF using LLM
            bill_data = await self.pdf_processor.process_pdf_bill(file_path)
            
            # Log the extracted data for debugging
            logger.info(f"📊 Extracted bill data: {bill_data}")
            
            # Validate essential data
            if not bill_data:
                logger.error("❌ No data extracted from PDF")
                raise ValueError("Failed to extract data from PDF")
            
            if not bill_data.get("vendor"):
                logger.warning("⚠️ No vendor information extracted, using 'Unknown'")
            
            if not bill_data.get("total_amount"):
                logger.warning("⚠️ No total amount extracted, using 0.0")
            
            # Helper function to parse dates
            def parse_date(date_str):
                if not date_str or date_str == "null":
                    return None
                try:
                    return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
                except (ValueError, TypeError):
                    return None
            
            # Helper function to safely convert to float
            def safe_float(value, default=0.0):
                if value is None or value == "null" or value == "":
                    return default
                try:
                    return float(value)
                except (ValueError, TypeError):
                    logger.warning(f"Could not convert '{value}' to float, using default {default}")
                    return default
            
            # Parse all dates
            document_date = parse_date(bill_data.get("document_date")) or datetime.now()
            bill_date = parse_date(bill_data.get("date")) or document_date  # Backward compatibility
            due_date = parse_date(bill_data.get("due_date"))
            period_from = parse_date(bill_data.get("period_from"))
            period_to = parse_date(bill_data.get("period_to"))
            
            # Create the enhanced bill record
            db_bill = Bill(
                # Company Information
                vendor=bill_data.get("vendor", "Unknown"),
                vendor_address=bill_data.get("vendor_address"),
                vendor_contact=bill_data.get("vendor_contact"),
                recipient_name=bill_data.get("recipient_name"),
                recipient_address=bill_data.get("recipient_address"),
                
                # Document Details
                document_date=document_date,
                bill_date=bill_date,  # Keep for backward compatibility
                document_type=bill_data.get("document_type"),
                bill_id=bill_data.get("bill_id", ""),
                due_date=due_date,
                period_from=period_from,
                period_to=period_to,
                
                # Financial Information
                currency=bill_data.get("currency", "USD"),
                total_amount=safe_float(bill_data.get("total_amount"), 0.0),
                payment_terms=bill_data.get("payment_terms"),
                previous_balance=safe_float(bill_data.get("previous_balance"), 0.0),
                
                # File Information
                file_path=file_path
            )
            
            db.add(db_bill)
            db.commit()
            db.refresh(db_bill)
            
            # Create enhanced transaction records
            for transaction_data in bill_data.get("transactions", []):
                transaction_date = parse_date(transaction_data.get("transaction_date"))
                
                db_transaction = Transaction(
                    bill_id=db_bill.id,
                    
                    # Transaction Details
                    transaction_date=transaction_date,
                    description=transaction_data.get("description", ""),
                    category=transaction_data.get("category"),
                    table_section=transaction_data.get("table_section"),
                    
                    # Pricing Information
                    quantity=safe_float(transaction_data.get("quantity")) if transaction_data.get("quantity") is not None else None,
                    unit_price=safe_float(transaction_data.get("unit_price")) if transaction_data.get("unit_price") is not None else None,
                    total_price=safe_float(transaction_data.get("total_price"), 0.0),
                    
                    # Additional Information
                    notes=transaction_data.get("notes")
                )
                db.add(db_transaction)
            
            db.commit()
            db.refresh(db_bill)
            
            # Log the enhanced data extraction
            logger.info(f"✅ Enhanced bill created: {db_bill.vendor} | {len(bill_data.get('transactions', []))} transactions")
            logger.info(f"📄 Document type: {db_bill.document_type} | Recipient: {db_bill.recipient_name}")
            
            return db_bill
        
        except Exception as e:
            db.rollback()
            logger.error(f"Error uploading bill: {str(e)}")
            raise
    
    def get_bills(self, db: Session, skip: int = 0, limit: int = 100) -> List[Bill]:
        """Get all bills"""
        return db.query(Bill).offset(skip).limit(limit).all()
    
    def get_bill(self, db: Session, bill_id: int) -> Optional[Bill]:
        """Get a specific bill by ID"""
        return db.query(Bill).filter(Bill.id == bill_id).first()
    
    def delete_bill(self, db: Session, bill_id: int) -> bool:
        """Delete a bill and its associated file"""
        bill = db.query(Bill).filter(Bill.id == bill_id).first()
        if not bill:
            return False
        
        # Delete the file if it exists
        if bill.file_path and os.path.exists(bill.file_path):
            try:
                os.remove(bill.file_path)
            except Exception as e:
                logger.error(f"Error deleting file {bill.file_path}: {str(e)}")
        
        # Delete the bill from the database (cascade will delete transactions)
        db.delete(bill)
        db.commit()
        return True

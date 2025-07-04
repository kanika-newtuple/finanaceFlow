from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Table, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# SQLAlchemy models
Base = declarative_base()

class Bill(Base):
    """Enhanced SQLAlchemy model for bills with detailed information"""
    __tablename__ = "bills"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Company Information
    vendor = Column(String, index=True)
    vendor_address = Column(Text, nullable=True)
    vendor_contact = Column(String, nullable=True)
    recipient_name = Column(String, index=True, nullable=True)
    recipient_address = Column(Text, nullable=True)
    
    # Document Details
    document_date = Column(DateTime, default=datetime.now)
    bill_date = Column(DateTime, default=datetime.now)  # Keep for backward compatibility
    document_type = Column(String, nullable=True)
    bill_id = Column(String, index=True, nullable=True)
    due_date = Column(DateTime, nullable=True)
    period_from = Column(DateTime, nullable=True)
    period_to = Column(DateTime, nullable=True)
    
    # Financial Information
    currency = Column(String, default="USD")
    total_amount = Column(Float)
    payment_terms = Column(Text, nullable=True)
    previous_balance = Column(Float, default=0.0)
    
    # File Information
    file_path = Column(String)
    
    # Relationships
    transactions = relationship("Transaction", back_populates="bill", cascade="all, delete-orphan")

class Transaction(Base):
    """Enhanced SQLAlchemy model for bill transactions/line items"""
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    bill_id = Column(Integer, ForeignKey("bills.id"))
    
    # Transaction Details
    transaction_date = Column(DateTime, nullable=True)
    description = Column(Text)
    category = Column(String, nullable=True, index=True)
    table_section = Column(String, nullable=True)
    
    # Pricing Information
    quantity = Column(Float, nullable=True)
    unit_price = Column(Float, nullable=True)
    total_price = Column(Float)
    
    # Additional Information
    notes = Column(Text, nullable=True)
    
    # Relationships
    bill = relationship("Bill", back_populates="transactions")

# Enhanced Pydantic models for API
class TransactionCreate(BaseModel):
    """Enhanced Pydantic model for creating transactions"""
    description: str
    category: Optional[str] = None
    table_section: Optional[str] = None
    transaction_date: Optional[datetime] = None
    quantity: Optional[float] = None
    unit_price: Optional[float] = None
    total_price: float
    notes: Optional[str] = None

class TransactionResponse(BaseModel):
    """Enhanced Pydantic model for transaction response"""
    id: int
    description: str
    category: Optional[str] = None
    table_section: Optional[str] = None
    transaction_date: Optional[datetime] = None
    quantity: Optional[float] = None
    unit_price: Optional[float] = None
    total_price: float
    notes: Optional[str] = None
    
    class Config:
        from_attributes = True
        
    @classmethod
    def from_orm(cls, obj):
        """Custom from_orm to handle missing attributes gracefully"""
        data = {}
        for field_name, field_info in cls.__fields__.items():
            value = getattr(obj, field_name, None)
            if value is None and field_info.default is not None:
                value = field_info.default
            data[field_name] = value
        return cls(**data)

class BillCreate(BaseModel):
    """Enhanced Pydantic model for creating bills"""
    vendor: str
    vendor_address: Optional[str] = None
    vendor_contact: Optional[str] = None
    recipient_name: Optional[str] = None
    recipient_address: Optional[str] = None
    document_date: Optional[datetime] = None
    document_type: Optional[str] = None
    bill_id: Optional[str] = None
    due_date: Optional[datetime] = None
    period_from: Optional[datetime] = None
    period_to: Optional[datetime] = None
    currency: Optional[str] = "USD"
    total_amount: float
    payment_terms: Optional[str] = None
    previous_balance: Optional[float] = 0.0
    transactions: List[TransactionCreate]

class BillResponse(BaseModel):
    """Enhanced Pydantic model for bill response"""
    id: int
    vendor: str
    vendor_address: Optional[str] = None
    vendor_contact: Optional[str] = None
    recipient_name: Optional[str] = None
    recipient_address: Optional[str] = None
    document_date: Optional[datetime] = None
    bill_date: datetime  # Keep for backward compatibility
    document_type: Optional[str] = None
    bill_id: Optional[str] = None
    due_date: Optional[datetime] = None
    period_from: Optional[datetime] = None
    period_to: Optional[datetime] = None
    currency: Optional[str] = "USD"
    total_amount: float
    payment_terms: Optional[str] = None
    previous_balance: Optional[float] = 0.0
    file_path: Optional[str] = None
    transactions: List[TransactionResponse]
    
    class Config:
        from_attributes = True

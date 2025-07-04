"""
API Routes for Google Sheets and Excel Integration
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
import os
import logging
from datetime import datetime

from database.db import get_db
from bills_api.service import BillService
from integrations.sheets_service import SheetsIntegrationService
from integrations.simple_integrations import SimpleSpreadsheetService
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter()
sheets_service = SheetsIntegrationService()
simple_service = SimpleSpreadsheetService()
bill_service = BillService()

class GoogleSheetsExportRequest(BaseModel):
    spreadsheet_id: Optional[str] = None
    include_transactions: bool = True
    include_analytics: bool = True

class ExcelExportRequest(BaseModel):
    filename: Optional[str] = None
    include_transactions: bool = True
    include_analytics: bool = True

@router.post("/export/google-sheets")
async def export_to_google_sheets(
    request: GoogleSheetsExportRequest,
    db: Session = Depends(get_db)
):
    """Export bills and transactions to Google Sheets"""
    try:
        # Get all bills from database
        bills = bill_service.get_bills(db, skip=0, limit=1000)
        
        # Convert SQLAlchemy objects to dictionaries
        bills_data = []
        for bill in bills:
            bill_dict = {
                'id': bill.id,
                'vendor': bill.vendor,
                'vendor_address': bill.vendor_address,
                'vendor_contact': bill.vendor_contact,
                'recipient_name': bill.recipient_name,
                'recipient_address': bill.recipient_address,
                'bill_date': bill.bill_date.isoformat() if bill.bill_date else None,
                'document_date': bill.document_date.isoformat() if bill.document_date else None,
                'due_date': bill.due_date.isoformat() if bill.due_date else None,
                'document_type': bill.document_type,
                'bill_id': bill.bill_id,
                'currency': bill.currency,
                'total_amount': bill.total_amount,
                'payment_terms': bill.payment_terms,
                'previous_balance': bill.previous_balance,
                'file_path': bill.file_path,
                'transactions': []
            }
            
            # Add transactions if requested
            if request.include_transactions:
                for transaction in bill.transactions:
                    bill_dict['transactions'].append({
                        'id': transaction.id,
                        'transaction_date': transaction.transaction_date.isoformat() if transaction.transaction_date else None,
                        'description': transaction.description,
                        'category': transaction.category,
                        'table_section': transaction.table_section,
                        'quantity': transaction.quantity,
                        'unit_price': transaction.unit_price,
                        'total_price': transaction.total_price,
                        'notes': transaction.notes
                    })
            
            bills_data.append(bill_dict)
        
        if not bills_data:
            raise HTTPException(status_code=404, detail="No bills found to export")
        
        # Export to Google Sheets
        result = sheets_service.export_to_google_sheets(bills_data, request.spreadsheet_id)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return {
            'success': True,
            'message': 'Successfully exported to Google Sheets',
            'spreadsheet_url': result['spreadsheet_url'],
            'spreadsheet_id': result['spreadsheet_id'],
            'bills_exported': result['bills_count'],
            'transactions_exported': result.get('transactions_count', 0),
            'export_timestamp': datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting to Google Sheets: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")

@router.post("/export/excel")
async def export_to_excel(
    request: ExcelExportRequest,
    db: Session = Depends(get_db)
):
    """Export bills and transactions to Excel file"""
    try:
        # Get all bills from database
        bills = bill_service.get_bills(db, skip=0, limit=1000)
        
        # Convert SQLAlchemy objects to dictionaries (same as above)
        bills_data = []
        for bill in bills:
            bill_dict = {
                'id': bill.id,
                'vendor': bill.vendor,
                'vendor_address': bill.vendor_address,
                'vendor_contact': bill.vendor_contact,
                'recipient_name': bill.recipient_name,
                'recipient_address': bill.recipient_address,
                'bill_date': bill.bill_date.isoformat() if bill.bill_date else None,
                'document_date': bill.document_date.isoformat() if bill.document_date else None,
                'due_date': bill.due_date.isoformat() if bill.due_date else None,
                'document_type': bill.document_type,
                'bill_id': bill.bill_id,
                'currency': bill.currency,
                'total_amount': bill.total_amount,
                'payment_terms': bill.payment_terms,
                'previous_balance': bill.previous_balance,
                'file_path': bill.file_path,
                'transactions': []
            }
            
            if request.include_transactions:
                for transaction in bill.transactions:
                    bill_dict['transactions'].append({
                        'id': transaction.id,
                        'transaction_date': transaction.transaction_date.isoformat() if transaction.transaction_date else None,
                        'description': transaction.description,
                        'category': transaction.category,
                        'table_section': transaction.table_section,
                        'quantity': transaction.quantity,
                        'unit_price': transaction.unit_price,
                        'total_price': transaction.total_price,
                        'notes': transaction.notes
                    })
            
            bills_data.append(bill_dict)
        
        if not bills_data:
            raise HTTPException(status_code=404, detail="No bills found to export")
        
        # Create exports directory
        exports_dir = "exports"
        os.makedirs(exports_dir, exist_ok=True)
        
        # Generate filename if not provided
        if request.filename:
            filename = os.path.join(exports_dir, request.filename)
            if not filename.endswith('.xlsx'):
                filename += '.xlsx'
        else:
            filename = os.path.join(exports_dir, f"FinanceFlow_Export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx")
        
        # Export to Excel
        result = sheets_service.export_to_excel(bills_data, filename)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return {
            'success': True,
            'message': 'Successfully exported to Excel',
            'filename': result['filename'],
            'file_size': result['file_size'],
            'bills_exported': result['bills_count'],
            'transactions_exported': result.get('transactions_count', 0),
            'download_path': f"/integrations/download/{os.path.basename(filename)}",
            'export_timestamp': datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting to Excel: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")

@router.get("/download/{filename}")
async def download_excel_file(filename: str):
    """Download exported Excel file"""
    try:
        from fastapi.responses import FileResponse
        
        file_path = os.path.join("exports", filename)
        
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="File not found")
        
        return FileResponse(
            path=file_path,
            filename=filename,
            media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error downloading file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")

@router.post("/sync/google-sheets/{spreadsheet_id}")
async def sync_with_google_sheets(
    spreadsheet_id: str,
    db: Session = Depends(get_db)
):
    """Sync data with an existing Google Sheet"""
    try:
        # Get all bills from database
        bills = bill_service.get_bills(db, skip=0, limit=1000)
        
        # Convert to dictionaries
        bills_data = []
        for bill in bills:
            bill_dict = {
                'id': bill.id,
                'vendor': bill.vendor,
                'vendor_address': bill.vendor_address,
                'vendor_contact': bill.vendor_contact,
                'recipient_name': bill.recipient_name,
                'recipient_address': bill.recipient_address,
                'bill_date': bill.bill_date.isoformat() if bill.bill_date else None,
                'document_date': bill.document_date.isoformat() if bill.document_date else None,
                'due_date': bill.due_date.isoformat() if bill.due_date else None,
                'document_type': bill.document_type,
                'bill_id': bill.bill_id,
                'currency': bill.currency,
                'total_amount': bill.total_amount,
                'payment_terms': bill.payment_terms,
                'previous_balance': bill.previous_balance,
                'file_path': bill.file_path,
                'transactions': []
            }
            
            for transaction in bill.transactions:
                bill_dict['transactions'].append({
                    'id': transaction.id,
                    'transaction_date': transaction.transaction_date.isoformat() if transaction.transaction_date else None,
                    'description': transaction.description,
                    'category': transaction.category,
                    'table_section': transaction.table_section,
                    'quantity': transaction.quantity,
                    'unit_price': transaction.unit_price,
                    'total_price': transaction.total_price,
                    'notes': transaction.notes
                })
            
            bills_data.append(bill_dict)
        
        if not bills_data:
            raise HTTPException(status_code=404, detail="No bills found to sync")
        
        # Sync with existing Google Sheet
        result = sheets_service.sync_with_existing_sheet(bills_data, spreadsheet_id)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return {
            'success': True,
            'message': 'Successfully synced with Google Sheets',
            'spreadsheet_url': result['spreadsheet_url'],
            'spreadsheet_id': spreadsheet_id,
            'bills_synced': result['bills_count'],
            'sync_timestamp': datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error syncing with Google Sheets: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@router.get("/google-sheets/setup")
async def get_google_sheets_setup():
    """Get instructions for setting up Google Sheets integration"""
    return {
        'setup_instructions': sheets_service.setup_google_credentials(),
        'credentials_file_path': sheets_service.credentials_file,
        'integration_available': sheets_service.authenticate_google_sheets() is not None
    }

@router.post("/export/simple-csv")
async def export_simple_csv(db: Session = Depends(get_db)):
    """Generate CSV for easy import to any spreadsheet - NO AUTHENTICATION NEEDED"""
    try:
        # Get all bills from database
        bills = bill_service.get_bills(db, skip=0, limit=1000)
        
        # Convert to dictionaries
        bills_data = []
        for bill in bills:
            bill_dict = {
                'id': bill.id,
                'vendor': bill.vendor,
                'bill_date': bill.bill_date.isoformat() if bill.bill_date else None,
                'total_amount': bill.total_amount,
                'document_type': bill.document_type,
                'bill_id': bill.bill_id,
                'currency': bill.currency,
                'due_date': bill.due_date.isoformat() if bill.due_date else None,
                'payment_terms': bill.payment_terms,
                'vendor_address': bill.vendor_address,
                'transactions': bill.transactions
            }
            bills_data.append(bill_dict)
        
        if not bills_data:
            raise HTTPException(status_code=404, detail="No bills found to export")
        
        # Generate simple CSV
        result = simple_service.create_shareable_csv_link(bills_data)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return {
            'success': True,
            'message': 'CSV ready for any spreadsheet!',
            'csv_content': result['csv_content'],
            'filename': result['filename'],
            'size': result['size'],
            'bills_count': len(bills_data),
            'import_instructions': result['import_instructions'],
            'quick_links': {
                'google_sheets': 'https://sheets.google.com/create',
                'excel_online': 'https://office.live.com/start/Excel.aspx',
                'airtable': 'https://airtable.com',
                'notion': 'https://notion.so'
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating simple CSV: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")

@router.post("/export/copy-paste")
async def export_copy_paste_format(db: Session = Depends(get_db)):
    """Generate tab-separated data for copy-paste to any spreadsheet"""
    try:
        # Get all bills from database
        bills = bill_service.get_bills(db, skip=0, limit=1000)
        
        # Convert to dictionaries
        bills_data = []
        for bill in bills:
            bill_dict = {
                'vendor': bill.vendor,
                'bill_date': bill.bill_date.isoformat() if bill.bill_date else '',
                'total_amount': bill.total_amount,
                'document_type': bill.document_type,
                'bill_id': bill.bill_id,
                'currency': bill.currency,
                'due_date': bill.due_date.isoformat() if bill.due_date else '',
                'transactions': bill.transactions
            }
            bills_data.append(bill_dict)
        
        if not bills_data:
            raise HTTPException(status_code=404, detail="No bills found to export")
        
        # Generate copy-paste format
        result = simple_service.generate_copy_paste_format(bills_data)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return {
            'success': True,
            'message': 'Data ready for copy-paste!',
            'tab_separated_content': result['tab_separated_content'],
            'rows_count': result['rows_count'],
            'instructions': result['instructions'],
            'usage': [
                '1. Copy the tab_separated_content below',
                '2. Open Google Sheets, Excel, or any spreadsheet',
                '3. Paste - columns will separate automatically!',
                '4. Format as needed'
            ]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating copy-paste format: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")

@router.get("/health")
async def integration_health_check():
    """Check the health of integrations"""
    return {
        'google_sheets_available': sheets_service.authenticate_google_sheets() is not None,
        'excel_export_available': True,
        'simple_csv_available': True,
        'copy_paste_available': True,
        'exports_directory': os.path.exists("exports"),
        'timestamp': datetime.now().isoformat()
    } 
"""
Google Sheets and Excel Integration Service
Handles exporting bills and transactions to Google Sheets and Excel files
"""

import os
import json
import pandas as pd
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging
from io import BytesIO
import xlsxwriter
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils.dataframe import dataframe_to_rows

# Google Sheets imports
try:
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    GOOGLE_SHEETS_AVAILABLE = True
except ImportError:
    GOOGLE_SHEETS_AVAILABLE = False

logger = logging.getLogger(__name__)

class SheetsIntegrationService:
    """Service for integrating with Google Sheets and Excel"""
    
    # Google Sheets API scopes
    SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
    
    def __init__(self):
        """Initialize the sheets integration service"""
        self.credentials_file = os.path.join(os.path.dirname(__file__), 'google_credentials.json')
        self.token_file = os.path.join(os.path.dirname(__file__), 'token.json')
        
    def authenticate_google_sheets(self) -> Optional[Any]:
        """Authenticate with Google Sheets API"""
        if not GOOGLE_SHEETS_AVAILABLE:
            logger.error("Google Sheets dependencies not installed")
            return None
            
        try:
            creds = None
            
            # Load existing token
            if os.path.exists(self.token_file):
                creds = Credentials.from_authorized_user_file(self.token_file, self.SCOPES)
            
            # If there are no (valid) credentials available, let the user log in
            if not creds or not creds.valid:
                if creds and creds.expired and creds.refresh_token:
                    creds.refresh(Request())
                else:
                    if not os.path.exists(self.credentials_file):
                        logger.error("Google credentials file not found. Please download from Google Cloud Console.")
                        return None
                    
                    flow = InstalledAppFlow.from_client_secrets_file(
                        self.credentials_file, self.SCOPES)
                    creds = flow.run_local_server(port=0)
                
                # Save the credentials for the next run
                with open(self.token_file, 'w') as token:
                    token.write(creds.to_json())
            
            # Build the service
            service = build('sheets', 'v4', credentials=creds)
            return service
            
        except Exception as e:
            logger.error(f"Error authenticating with Google Sheets: {str(e)}")
            return None
    
    def prepare_bills_data(self, bills: List[Dict]) -> pd.DataFrame:
        """Prepare bills data for export"""
        bills_data = []
        
        for bill in bills:
            bills_data.append({
                'ID': bill.get('id'),
                'Vendor': bill.get('vendor', ''),
                'Bill ID': bill.get('bill_id', ''),
                'Date': bill.get('bill_date', ''),
                'Due Date': bill.get('due_date', ''),
                'Document Type': bill.get('document_type', ''),
                'Currency': bill.get('currency', 'USD'),
                'Total Amount': bill.get('total_amount', 0),
                'Payment Terms': bill.get('payment_terms', ''),
                'Previous Balance': bill.get('previous_balance', 0),
                'Vendor Address': bill.get('vendor_address', ''),
                'Vendor Contact': bill.get('vendor_contact', ''),
                'Recipient Name': bill.get('recipient_name', ''),
                'Recipient Address': bill.get('recipient_address', ''),
                'Transaction Count': len(bill.get('transactions', [])),
                'File Path': bill.get('file_path', '')
            })
        
        return pd.DataFrame(bills_data)
    
    def prepare_transactions_data(self, bills: List[Dict]) -> pd.DataFrame:
        """Prepare transactions data for export"""
        transactions_data = []
        
        for bill in bills:
            bill_id = bill.get('id')
            vendor = bill.get('vendor', '')
            bill_date = bill.get('bill_date', '')
            
            for transaction in bill.get('transactions', []):
                transactions_data.append({
                    'Bill ID': bill_id,
                    'Vendor': vendor,
                    'Bill Date': bill_date,
                    'Transaction Date': transaction.get('transaction_date', ''),
                    'Description': transaction.get('description', ''),
                    'Category': transaction.get('category', ''),
                    'Table Section': transaction.get('table_section', ''),
                    'Quantity': transaction.get('quantity', ''),
                    'Unit Price': transaction.get('unit_price', ''),
                    'Total Price': transaction.get('total_price', 0),
                    'Notes': transaction.get('notes', '')
                })
        
        return pd.DataFrame(transactions_data)
    
    def export_to_google_sheets(self, bills: List[Dict], spreadsheet_id: Optional[str] = None) -> Dict[str, Any]:
        """Export bills and transactions to Google Sheets"""
        try:
            service = self.authenticate_google_sheets()
            if not service:
                return {'success': False, 'error': 'Failed to authenticate with Google Sheets'}
            
            # Prepare data
            bills_df = self.prepare_bills_data(bills)
            transactions_df = self.prepare_transactions_data(bills)
            
            if spreadsheet_id is None:
                # Create new spreadsheet
                spreadsheet = {
                    'properties': {
                        'title': f'FinanceFlow Export - {datetime.now().strftime("%Y-%m-%d %H:%M")}'
                    },
                    'sheets': [
                        {'properties': {'title': 'Bills Summary'}},
                        {'properties': {'title': 'Transactions Detail'}},
                        {'properties': {'title': 'Analytics'}}
                    ]
                }
                
                result = service.spreadsheets().create(body=spreadsheet).execute()
                spreadsheet_id = result['spreadsheetId']
                logger.info(f"Created new spreadsheet: {spreadsheet_id}")
            
            # Clear existing data
            service.spreadsheets().values().clear(
                spreadsheetId=spreadsheet_id,
                range='Bills Summary!A:Z'
            ).execute()
            
            service.spreadsheets().values().clear(
                spreadsheetId=spreadsheet_id,
                range='Transactions Detail!A:Z'
            ).execute()
            
            # Export Bills Summary
            bills_values = [bills_df.columns.tolist()] + bills_df.fillna('').values.tolist()
            bills_body = {'values': bills_values}
            
            service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range='Bills Summary!A1',
                valueInputOption='RAW',
                body=bills_body
            ).execute()
            
            # Export Transactions Detail
            transactions_values = [transactions_df.columns.tolist()] + transactions_df.fillna('').values.tolist()
            transactions_body = {'values': transactions_values}
            
            service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range='Transactions Detail!A1',
                valueInputOption='RAW',
                body=transactions_body
            ).execute()
            
            # Add Analytics Summary
            analytics_data = self.generate_analytics_summary(bills)
            analytics_values = [['Metric', 'Value']]
            for key, value in analytics_data.items():
                analytics_values.append([key, str(value)])
            
            analytics_body = {'values': analytics_values}
            service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range='Analytics!A1',
                valueInputOption='RAW',
                body=analytics_body
            ).execute()
            
            # Format the spreadsheet
            self.format_google_sheet(service, spreadsheet_id)
            
            spreadsheet_url = f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}"
            
            return {
                'success': True,
                'spreadsheet_id': spreadsheet_id,
                'spreadsheet_url': spreadsheet_url,
                'bills_count': len(bills),
                'transactions_count': len(transactions_df)
            }
            
        except HttpError as error:
            logger.error(f"Google Sheets API error: {error}")
            return {'success': False, 'error': f'Google Sheets API error: {error}'}
        except Exception as e:
            logger.error(f"Error exporting to Google Sheets: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def format_google_sheet(self, service, spreadsheet_id: str):
        """Apply formatting to the Google Sheet"""
        try:
            requests = []
            
            # Format headers for Bills Summary sheet
            requests.append({
                'repeatCell': {
                    'range': {
                        'sheetId': 0,  # Bills Summary sheet
                        'startRowIndex': 0,
                        'endRowIndex': 1
                    },
                    'cell': {
                        'userEnteredFormat': {
                            'backgroundColor': {'red': 0.2, 'green': 0.8, 'blue': 0.7},
                            'textFormat': {'bold': True, 'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}}
                        }
                    },
                    'fields': 'userEnteredFormat(backgroundColor,textFormat)'
                }
            })
            
            # Format headers for Transactions Detail sheet
            requests.append({
                'repeatCell': {
                    'range': {
                        'sheetId': 1,  # Transactions Detail sheet
                        'startRowIndex': 0,
                        'endRowIndex': 1
                    },
                    'cell': {
                        'userEnteredFormat': {
                            'backgroundColor': {'red': 0.2, 'green': 0.8, 'blue': 0.7},
                            'textFormat': {'bold': True, 'foregroundColor': {'red': 1, 'green': 1, 'blue': 1}}
                        }
                    },
                    'fields': 'userEnteredFormat(backgroundColor,textFormat)'
                }
            })
            
            # Auto-resize columns
            requests.append({
                'autoResizeDimensions': {
                    'dimensions': {
                        'sheetId': 0,
                        'dimension': 'COLUMNS'
                    }
                }
            })
            
            requests.append({
                'autoResizeDimensions': {
                    'dimensions': {
                        'sheetId': 1,
                        'dimension': 'COLUMNS'
                    }
                }
            })
            
            body = {'requests': requests}
            service.spreadsheets().batchUpdate(spreadsheetId=spreadsheet_id, body=body).execute()
            
        except Exception as e:
            logger.error(f"Error formatting Google Sheet: {str(e)}")
    
    def export_to_excel(self, bills: List[Dict], filename: Optional[str] = None) -> Dict[str, Any]:
        """Export bills and transactions to Excel file with advanced formatting"""
        try:
            if filename is None:
                filename = f"FinanceFlow_Export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
            
            # Prepare data
            bills_df = self.prepare_bills_data(bills)
            transactions_df = self.prepare_transactions_data(bills)
            analytics_data = self.generate_analytics_summary(bills)
            
            # Create Excel file with formatting
            with pd.ExcelWriter(filename, engine='xlsxwriter') as writer:
                # Write dataframes to different sheets
                bills_df.to_excel(writer, sheet_name='Bills Summary', index=False)
                transactions_df.to_excel(writer, sheet_name='Transactions Detail', index=False)
                
                # Get workbook and worksheets for formatting
                workbook = writer.book
                bills_sheet = writer.sheets['Bills Summary']
                transactions_sheet = writer.sheets['Transactions Detail']
                
                # Define formats
                header_format = workbook.add_format({
                    'bold': True,
                    'text_wrap': True,
                    'valign': 'top',
                    'fg_color': '#40E0D0',
                    'border': 1
                })
                
                money_format = workbook.add_format({'num_format': '$#,##0.00'})
                date_format = workbook.add_format({'num_format': 'yyyy-mm-dd'})
                
                # Format Bills Summary sheet
                for col_num, value in enumerate(bills_df.columns.values):
                    bills_sheet.write(0, col_num, value, header_format)
                    
                    # Auto-adjust column width
                    column_len = max(len(str(value)), bills_df[value].astype(str).str.len().max())
                    bills_sheet.set_column(col_num, col_num, min(column_len + 2, 50))
                    
                    # Apply money format to amount columns
                    if 'amount' in value.lower() or 'balance' in value.lower():
                        bills_sheet.set_column(col_num, col_num, None, money_format)
                    elif 'date' in value.lower():
                        bills_sheet.set_column(col_num, col_num, None, date_format)
                
                # Format Transactions Detail sheet
                for col_num, value in enumerate(transactions_df.columns.values):
                    transactions_sheet.write(0, col_num, value, header_format)
                    
                    column_len = max(len(str(value)), 
                                   transactions_df[value].astype(str).str.len().max() if len(transactions_df) > 0 else len(str(value)))
                    transactions_sheet.set_column(col_num, col_num, min(column_len + 2, 50))
                    
                    if 'price' in value.lower() or 'amount' in value.lower():
                        transactions_sheet.set_column(col_num, col_num, None, money_format)
                    elif 'date' in value.lower():
                        transactions_sheet.set_column(col_num, col_num, None, date_format)
                
                # Add Analytics sheet
                analytics_sheet = workbook.add_worksheet('Analytics')
                analytics_sheet.write(0, 0, 'Metric', header_format)
                analytics_sheet.write(0, 1, 'Value', header_format)
                
                row = 1
                for key, value in analytics_data.items():
                    analytics_sheet.write(row, 0, key)
                    if isinstance(value, (int, float)):
                        analytics_sheet.write(row, 1, value, money_format if 'amount' in key.lower() else None)
                    else:
                        analytics_sheet.write(row, 1, str(value))
                    row += 1
                
                analytics_sheet.set_column(0, 0, 25)
                analytics_sheet.set_column(1, 1, 20)
            
            return {
                'success': True,
                'filename': filename,
                'bills_count': len(bills),
                'transactions_count': len(transactions_df),
                'file_size': os.path.getsize(filename) if os.path.exists(filename) else 0
            }
            
        except Exception as e:
            logger.error(f"Error exporting to Excel: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def generate_analytics_summary(self, bills: List[Dict]) -> Dict[str, Any]:
        """Generate analytics summary for the export"""
        total_bills = len(bills)
        total_amount = sum(bill.get('total_amount', 0) for bill in bills)
        
        # Vendor analysis
        vendor_amounts = {}
        for bill in bills:
            vendor = bill.get('vendor', 'Unknown')
            vendor_amounts[vendor] = vendor_amounts.get(vendor, 0) + bill.get('total_amount', 0)
        
        top_vendor = max(vendor_amounts.items(), key=lambda x: x[1]) if vendor_amounts else ('None', 0)
        
        # Monthly analysis
        current_month = datetime.now().month
        current_year = datetime.now().year
        
        monthly_bills = [
            bill for bill in bills 
            if bill.get('bill_date') and 
            datetime.fromisoformat(bill['bill_date'].replace('Z', '+00:00')).month == current_month and
            datetime.fromisoformat(bill['bill_date'].replace('Z', '+00:00')).year == current_year
        ]
        
        monthly_amount = sum(bill.get('total_amount', 0) for bill in monthly_bills)
        
        return {
            'Total Bills': total_bills,
            'Total Amount': total_amount,
            'Average Bill Amount': total_amount / total_bills if total_bills > 0 else 0,
            'This Month Bills': len(monthly_bills),
            'This Month Amount': monthly_amount,
            'Top Vendor': top_vendor[0],
            'Top Vendor Amount': top_vendor[1],
            'Unique Vendors': len(vendor_amounts),
            'Export Date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
    
    def sync_with_existing_sheet(self, bills: List[Dict], spreadsheet_id: str) -> Dict[str, Any]:
        """Sync data with an existing Google Sheet"""
        try:
            service = self.authenticate_google_sheets()
            if not service:
                return {'success': False, 'error': 'Failed to authenticate with Google Sheets'}
            
            # Check if spreadsheet exists
            try:
                spreadsheet = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
            except HttpError as e:
                if e.resp.status == 404:
                    return {'success': False, 'error': 'Spreadsheet not found'}
                raise
            
            # Export to existing spreadsheet
            result = self.export_to_google_sheets(bills, spreadsheet_id)
            result['sync_mode'] = 'existing_sheet'
            
            return result
            
        except Exception as e:
            logger.error(f"Error syncing with existing sheet: {str(e)}")
            return {'success': False, 'error': str(e)}

    def setup_google_credentials(self) -> Dict[str, str]:
        """Return instructions for setting up Google Sheets credentials"""
        return {
            'step_1': 'Go to Google Cloud Console (https://console.cloud.google.com/)',
            'step_2': 'Create a new project or select existing project',
            'step_3': 'Enable Google Sheets API',
            'step_4': 'Create credentials (OAuth 2.0 Client ID)',
            'step_5': 'Download credentials JSON file',
            'step_6': f'Save as: {self.credentials_file}',
            'step_7': 'First run will open browser for authorization',
            'note': 'Credentials file should be kept secure and not committed to version control'
        } 
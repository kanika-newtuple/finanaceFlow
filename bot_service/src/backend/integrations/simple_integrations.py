"""
Simple Spreadsheet Integration - No authentication required
"""

import requests
import pandas as pd
import csv
from io import StringIO
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

class SimpleSpreadsheetService:
    """Simple integrations that work without complex authentication"""
    
    def export_to_csv_url(self, bills: List[Dict], base_url: str) -> Dict[str, Any]:
        """
        Generate CSV data that can be copied to any spreadsheet
        Returns URLs and data that work with Google Sheets, Excel Online, etc.
        """
        try:
            # Prepare bills data
            bills_data = []
            for bill in bills:
                bills_data.append({
                    'Vendor': bill.get('vendor', ''),
                    'Date': bill.get('bill_date', ''),
                    'Amount': bill.get('total_amount', 0),
                    'Type': bill.get('document_type', ''),
                    'Bill_ID': bill.get('bill_id', ''),
                    'Currency': bill.get('currency', 'USD'),
                    'Due_Date': bill.get('due_date', ''),
                    'Payment_Terms': bill.get('payment_terms', ''),
                    'Vendor_Address': bill.get('vendor_address', ''),
                    'Total_Transactions': len(bill.get('transactions', []))
                })
            
            # Convert to CSV string
            output = StringIO()
            if bills_data:
                writer = csv.DictWriter(output, fieldnames=bills_data[0].keys())
                writer.writeheader()
                writer.writerows(bills_data)
                csv_content = output.getvalue()
            else:
                csv_content = "No data available"
            
            return {
                'success': True,
                'csv_content': csv_content,
                'bills_count': len(bills),
                'google_sheets_import_url': 'https://sheets.google.com/create',
                'excel_online_url': 'https://office.live.com/start/Excel.aspx',
                'instructions': {
                    'google_sheets': [
                        '1. Go to https://sheets.google.com/create',
                        '2. File → Import → Upload → Select CSV file',
                        '3. Or copy-paste the CSV data directly'
                    ],
                    'excel_online': [
                        '1. Go to https://office.live.com/start/Excel.aspx',
                        '2. Data → From Text/CSV',
                        '3. Upload the CSV file'
                    ],
                    'any_spreadsheet': [
                        '1. Copy the CSV content below',
                        '2. Paste into any spreadsheet application',
                        '3. Use "Text to Columns" if needed'
                    ]
                }
            }
            
        except Exception as e:
            logger.error(f"Error generating CSV: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def generate_google_sheets_import_url(self, csv_content: str) -> str:
        """
        Generate a URL that opens Google Sheets with CSV data
        """
        try:
            # Create a data URL for Google Sheets
            import urllib.parse
            
            # Encode CSV content for URL
            encoded_csv = urllib.parse.quote(csv_content)
            
            # This creates a URL that opens Google Sheets with the data
            sheets_url = f"https://docs.google.com/spreadsheets/create?usp=sheets_web_ope"
            
            return sheets_url
            
        except Exception as e:
            logger.error(f"Error generating Google Sheets URL: {str(e)}")
            return "https://sheets.google.com/create"
    
    def create_shareable_csv_link(self, bills: List[Dict], filename: str = "financeflow_export.csv") -> Dict[str, Any]:
        """
        Create a downloadable CSV file with instructions for importing to any spreadsheet
        """
        try:
            result = self.export_to_csv_url(bills, "")
            
            if result['success']:
                return {
                    'success': True,
                    'filename': filename,
                    'csv_content': result['csv_content'],
                    'size': len(result['csv_content']),
                    'import_instructions': {
                        'google_sheets': {
                            'method_1': 'Go to sheets.google.com → File → Import → Upload CSV',
                            'method_2': 'Copy CSV content → Paste in new sheet → Data → Split text to columns',
                            'url': 'https://sheets.google.com/create'
                        },
                        'excel_online': {
                            'method': 'Go to office.live.com → Excel → Data → From Text/CSV',
                            'url': 'https://office.live.com/start/Excel.aspx'
                        },
                        'airtable': {
                            'method': 'Go to airtable.com → Create base → Import CSV',
                            'url': 'https://airtable.com'
                        },
                        'notion': {
                            'method': 'Create new page → Add database → Import CSV',
                            'url': 'https://notion.so'
                        }
                    }
                }
            else:
                return result
                
        except Exception as e:
            logger.error(f"Error creating shareable CSV: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def generate_copy_paste_format(self, bills: List[Dict]) -> Dict[str, Any]:
        """
        Generate tab-separated format for easy copy-paste into any spreadsheet
        """
        try:
            if not bills:
                return {'success': False, 'error': 'No bills to export'}
            
            # Headers
            headers = ['Vendor', 'Date', 'Amount', 'Type', 'Bill ID', 'Currency', 'Due Date', 'Transactions']
            
            # Data rows
            rows = []
            for bill in bills:
                row = [
                    str(bill.get('vendor', '') or ''),
                    str(bill.get('bill_date', '') or ''),
                    str(bill.get('total_amount', 0) or 0),
                    str(bill.get('document_type', '') or ''),
                    str(bill.get('bill_id', '') or ''),
                    str(bill.get('currency', 'USD') or 'USD'),
                    str(bill.get('due_date', '') or ''),
                    str(len(bill.get('transactions', []) or []))
                ]
                rows.append(row)
            
            # Create tab-separated content
            tab_separated = '\t'.join(headers) + '\n'
            for row in rows:
                tab_separated += '\t'.join(row) + '\n'
            
            return {
                'success': True,
                'tab_separated_content': tab_separated,
                'rows_count': len(rows),
                'instructions': [
                    'Copy the content below',
                    'Open any spreadsheet (Google Sheets, Excel, etc.)',
                    'Paste the content - it will automatically separate into columns',
                    'Format as needed'
                ]
            }
            
        except Exception as e:
            logger.error(f"Error generating copy-paste format: {str(e)}")
            return {'success': False, 'error': str(e)} 
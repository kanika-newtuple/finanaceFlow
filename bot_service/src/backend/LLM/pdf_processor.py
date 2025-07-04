import PyPDF2
import os
import json
import logging
from typing import Dict, Any, List
import openai
from datetime import datetime
import fitz  # PyMuPDF
from dotenv import load_dotenv
logger = logging.getLogger(__name__)
openai.api_key = os.getenv("OPENAI_API_KEY")
print("Loaded key:", openai.api_key)
import os
print("🔑 OPENAI_API_KEY is:", repr(os.getenv("OPENAI_API_KEY")))

class PDFProcessor:
    """
    Class to process PDF bills and extract transaction data using LLM
    """
    
    def __init__(self, openai_api_key: str = None):
        """Initialize the PDF processor with OpenAI API key"""
        openai.api_key = os.environ.get("OPENAI_API_KEY")
        if not openai.api_key:
            raise ValueError("OpenAI API key must be provided")
            raise ValueError("OpenAI API key must be provided")
    
    async def extract_text_from_pdf(self, file_path: str) -> str:
        """Extract text content from a PDF file using PyMuPDF"""
        try:
            text_content = ""
            with fitz.open(file_path) as doc:
                for page in doc:
                    text_content += page.get_text()
            return text_content
        except Exception as e:
            logger.error(f"Error extracting text from PDF: {str(e)}")
            raise ValueError(f"Failed to extract text from PDF: {str(e)}")
    
    async def extract_transactions_from_text(self, text_content: str) -> Dict[str, Any]:
        """Use OpenAI to extract transaction data from text content"""
        try:
            prompt = f"""
            You are an expert financial document analyzer. Extract comprehensive information from this bill/invoice/statement.
            
            EXTRACT THE FOLLOWING DETAILED INFORMATION:
            
            1. COMPANY INFORMATION:
            - Main vendor/company name (who issued the bill)
            - Company address (full address if available)
            - Company contact information (phone, email, website)
            - Document recipient/owner name
            - Recipient address
            
            2. DOCUMENT DETAILS:
            - Document date (format: YYYY-MM-DD)
            - Document type (invoice, statement, bill, receipt, etc.)
            - Document/Bill ID or reference number
            - Due date (if mentioned)
            - Period covered (from date to date if applicable)
            
            3. FINANCIAL SUMMARY:
            - Total amount due/charged
            - Currency (if mentioned, default USD)
            - Payment terms
            - Previous balance (if applicable)
            
            4. ALL TRANSACTIONS/LINE ITEMS:
            For EVERY line item, transaction, fee, tax, discount, or charge, extract:
            - Transaction date (if different from document date)
            - Item/service description (be very detailed)
            - Category/type (e.g., "Management Fee", "Tax", "Service Charge", "Product", etc.)
            - Quantity (if available)
            - Unit price (if available)
            - Total price/amount
            - Any additional notes or details
            - Table heading/section it appears under
            
            5. IDENTIFY TABLE STRUCTURES:
            - Look for table headers/column names
            - Group transactions by their table sections
            - Note any subtotals or running totals
            
            IMPORTANT: Extract EVERY monetary amount mentioned, including:
            - Line items, fees, taxes, discounts, credits, debits
            - Subtotals, grand totals, balances
            - Previous amounts, adjustments, offsets
            - Payment amounts, refunds, penalties
            
            Format the response as a JSON object with this enhanced structure:
            {{
                "vendor": "Main company/vendor name",
                "vendor_address": "Full company address",
                "vendor_contact": "Phone/email/website",
                "recipient_name": "Bill recipient/owner name",
                "recipient_address": "Recipient address",
                "document_date": "YYYY-MM-DD",
                "document_type": "invoice/statement/bill/receipt",
                "bill_id": "Document reference number",
                "due_date": "YYYY-MM-DD or null",
                "period_from": "YYYY-MM-DD or null",
                "period_to": "YYYY-MM-DD or null",
                "currency": "USD",
                "total_amount": 123.45,
                "payment_terms": "Payment terms or null",
                "previous_balance": 0.0,
                "transactions": [
                    {{
                        "transaction_date": "YYYY-MM-DD or null",
                        "description": "Detailed item description",
                        "category": "Fee type/category",
                        "table_section": "Which table/section this appears in",
                        "quantity": 1,
                        "unit_price": 10.99,
                        "total_price": 10.99,
                        "notes": "Any additional details"
                    }}
                ],
                "table_headers": ["List of table column headers found"],
                "subtotals": [
                    {{
                        "section": "Section name",
                        "amount": 100.00
                    }}
                ]
            }}
            
            Bill/Document content:
            {text_content[:4000]}  # Limit content to avoid token limits
            """
            
            # Log that we're sending a request to OpenAI
            logger.info(f"🚀 Sending request to OpenAI with prompt length: {len(prompt)}")
            logger.info(f"🚀 OpenAI API Key (first 10 chars): {os.environ.get('OPENAI_API_KEY', 'NOT_SET')[:10]}...")
            
            # For OpenAI client v1.0+
            client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1,
                max_tokens=2000
            )
            
            # Parse the JSON response
            result_text = response.choices[0].message.content
            
            # Log the full response from OpenAI
            logger.info(f"✅ OpenAI response received: {result_text}")
            
            # Clean the response - remove markdown code blocks if present
            if result_text.startswith("```json"):
                # Remove ```json from start and ``` from end
                result_text = result_text.replace("```json", "").replace("```", "").strip()
                logger.info(f"🧹 Cleaned response (removed markdown): {result_text}")
            elif result_text.startswith("```"):
                # Remove ``` from start and end
                result_text = result_text.replace("```", "").strip()
                logger.info(f"🧹 Cleaned response (removed markdown): {result_text}")
            
            result = json.loads(result_text)
            logger.info(f"✅ JSON parsing successful: {result}")
            return result
        except Exception as e:
            logger.error(f"❌ Error extracting transactions with LLM: {str(e)}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            logger.error(f"❌ Exception args: {e.args}")
            # Return default structure if processing fails
            return {
                "vendor": "Unknown Vendor",
                "date": "",
                "total_amount": 0.0,
                "bill_id": "",
                "transactions": []
            }
    
    async def process_pdf_bill(self, file_path: str) -> Dict[str, Any]:
        """Process a PDF bill and extract transaction data"""
        try:
            # Check if OpenAI API key is set
            if not openai.api_key:
                logger.warning("OpenAI API key not set or invalid")
                return {
                    "vendor": "Unknown Vendor (No API Key)",
                    "date": datetime.now().strftime("%Y-%m-%d"),
                    "total_amount": 0.0,
                    "bill_id": "Missing API Key",
                    "file_path": file_path,
                    "transactions": [
                        {
                            "description": "Please set a valid OpenAI API key in .env file",
                            "quantity": 1,
                            "unit_price": 0,
                            "total_price": 0
                        }
                    ]
                }
            
            # Extract text from PDF
            logger.info(f"Extracting text from PDF: {file_path}")
            text_content = await self.extract_text_from_pdf(file_path)
            
            # Log the extracted text content for debugging
            logger.info(f"📄 EXTRACTED PDF TEXT (length: {len(text_content)} chars):")
            logger.info(f"📄 TEXT CONTENT: {repr(text_content[:1000])}...")  # First 1000 characters
            
            if not text_content or len(text_content.strip()) < 10:
                logger.warning(f"Extracted text is empty or too short: {text_content}")
                return {
                    "vendor": "Unknown Vendor (Empty PDF)",
                    "date": datetime.now().strftime("%Y-%m-%d"),
                    "total_amount": 0.0,
                    "bill_id": "Empty PDF",
                    "file_path": file_path,
                    "transactions": [
                        {
                            "description": "No text could be extracted from PDF",
                            "quantity": 1,
                            "unit_price": 0,
                            "total_price": 0
                        }
                    ]
                }
            
            # Log the text that will be sent to LLM (first 4000 chars)
            llm_text = text_content[:4000]
            logger.info(f"🤖 TEXT BEING SENT TO LLM (length: {len(llm_text)} chars):")
            logger.info(f"🤖 LLM INPUT: {repr(llm_text)}")
            
            # Extract transactions using LLM
            logger.info(f"Sending text to LLM for processing: {len(text_content)} characters")
            result = await self.extract_transactions_from_text(text_content)
            
            # Log the result
            logger.info(f"Processed result: {json.dumps(result, indent=2)}")
            
            # Add the file path to the result
            result["file_path"] = file_path
            
            return result
        except Exception as e:
            logger.error(f"Error processing PDF bill: {str(e)}")
            raise ValueError(f"Failed to process PDF bill: {str(e)}")

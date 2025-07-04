import PyPDF2
import os
import json
import logging
from typing import Dict, Any, List
from datetime import datetime
import fitz  # PyMuPDF
from dotenv import load_dotenv

from LLM.manager import LLMServiceManager
from common.data_model import LLMProvider, LiteLLMModels, LangfuseMetaData

logger = logging.getLogger(__name__)

class PDFProcessor:
    """
    Class to process PDF bills and extract transaction data using LLM
    """
    
    def __init__(self, openai_api_key: str = None):
        """Initialize the PDF processor with LLM service manager"""
        # Initialize LLM service manager
        self.llm_service_manager = LLMServiceManager()
        
        # Get LLM service with GPT-4o-mini model
        self.llm_service = self.llm_service_manager.get_service(
            llm_provider=LLMProvider.lite_llm,
            model_name=LiteLLMModels.gpt_4o_mini.value
        )
        
        # Set up Langfuse metadata for tracking
        self.langfuse_metadata = LangfuseMetaData(
            trace_name="pdf_bill_processing",
            trace_user_id="system",
            mask_input=True
        ).model_dump()
    
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
        """Use LLM service to extract transaction data from text content"""
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
            
            # Log that we're sending a request to LLM
            logger.info(f"🚀 Sending request to LLM with prompt length: {len(prompt)}")
            
            # Use LLM service to get completion
            response = await self.llm_service.completion(
                prompt=[{"role": "user", "content": prompt}],
                langfuse_meta_data=self.langfuse_metadata,
                temperature=0.1,
                max_tokens=2000
            )
            
            # Log the full response from LLM
            logger.info(f"✅ LLM response received: {response}")
            
            # Clean the response - remove markdown code blocks if present
            if response.startswith("```json"):
                # Remove ```json from start and ``` from end
                response = response.replace("```json", "").replace("```", "").strip()
                logger.info(f"🧹 Cleaned response (removed markdown): {response}")
            elif response.startswith("```"):
                # Remove ``` from start and end
                response = response.replace("```", "").strip()
                logger.info(f"🧹 Cleaned response (removed markdown): {response}")
            
            result = json.loads(response)
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

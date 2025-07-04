# Bill Management System

A full-stack application for uploading, processing, and managing bills. The system uses LLM (OpenAI) to extract transaction data from PDF bills.

## Features

- Upload PDF bills
- Extract bill data using OpenAI LLM
- Store bill data in PostgreSQL database
- View bills and their transactions
- Delete bills

## Tech Stack

### Backend
- FastAPI
- SQLAlchemy
- PostgreSQL (with SQLite fallback)
- OpenAI API for LLM processing
- PyPDF2 for PDF text extraction

### Frontend
- React
- Material UI
- Axios for API calls

## Setup Instructions

### Prerequisites
- Python 3.11 or higher
- Node.js and npm
- PostgreSQL (optional, can use SQLite)
- OpenAI API key

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd bot_service/src/backend
   ```

2. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Create a `.env` file based on `.env.example`:
   ```
   cp .env.example .env
   ```

5. Edit the `.env` file with your configuration:
   ```
   # Database Configuration
   DATABASE_URL=postgresql://username:password@localhost:5432/common
   # Or for SQLite:
   # DATABASE_URL=sqlite:///bills.db

   # OpenAI API Key
  

   # Server Configuration
   HOST=0.0.0.0
   PORT=8081
   ```

6. Run the backend server:
   ```
   python main.py
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```
   cd bot_service/src/frontend
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Run the frontend development server:
   ```
   npm start
   ```

4. Open your browser and navigate to:
   ```
   http://localhost:3000
   ```

## API Endpoints

- `GET /api/v1/health` - Health check endpoint
- `GET /api/v1/bills` - Get all bills
- `GET /api/v1/bills/{bill_id}` - Get a specific bill
- `POST /api/v1/bills/upload` - Upload and process a PDF bill
- `DELETE /api/v1/bills/{bill_id}` - Delete a bill

## Database Schema

### Bills Table
- `id` - Primary key
- `vendor` - Vendor/company name
- `bill_date` - Date of the bill
- `total_amount` - Total amount of the bill
- `bill_id` - Bill reference number
- `file_path` - Path to the uploaded PDF file

### Transactions Table
- `id` - Primary key
- `bill_id` - Foreign key to bills table
- `description` - Item description
- `quantity` - Item quantity (optional)
- `unit_price` - Unit price (optional)
- `total_price` - Total price for the item

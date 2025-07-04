# Bill Management Application

A simple web application for uploading, managing, and tracking your bills. Built with FastAPI backend and React frontend.

## Features

- Upload and store bill information
- Categorize bills
- Track spending by category
- Attach bill images or PDFs
- View all bills in a convenient table format

## Getting Started

### Running with Docker

**For Linux/MacOS:**
```bash
# Create Docker networks if starting for the first time
make create-network

# Start the application (backend & frontend)
make start-dev-application

# To stop the application
make stop-dev-application
```

**For Windows:**
```bash
# Start the application
docker compose --project-name bot_main -f docker-compose-main.yml up -d --build

# To stop the application
docker compose --project-name bot_main -f docker-compose-main.yml down
```

### Running Locally

#### Backend Setup

1. Create a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate   # Linux/MacOS
   venv\Scripts\activate      # Windows
   ```

2. Navigate to the backend directory:
   ```bash
   cd bot_service/src/backend
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the backend:
   ```bash
   python main.py
   ```
   The backend will be available at http://localhost:8081/api/v1

#### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd bot_service/src/frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the frontend:
   ```bash
   npm start
   ```
   The frontend will be available at http://localhost:3000

## API Endpoints

- `GET /api/v1/bills` - Get all bills
- `GET /api/v1/bills/{bill_id}` - Get a specific bill
- `POST /api/v1/bills` - Create a new bill
- `DELETE /api/v1/bills/{bill_id}` - Delete a bill
- `GET /api/v1/health` - Check API health

## Technologies Used

- **Backend:** FastAPI, SQLAlchemy, PostgreSQL
- **Frontend:** React, Material-UI

## Reading the docs locally:
>   For Linux/MacOS:
>   - From root dir run `make docs` & `
import psycopg2
from psycopg2 import OperationalError, sql
import sys

# Connection parameters - update these with your actual PostgreSQL credentials
DB_CONFIG = {
    'dbname': 'common',        # The database name you want to connect to
    'user': 'root',        # Your PostgreSQL username
    'password': 'root',    # Your PostgreSQL password
    'host': '8002',       # The host where PostgreSQL is running
    'port': 5432,              # PostgreSQL port
    'connect_timeout': 5       # Timeout in seconds
}

def test_postgres_connection():
    try:
        print("Attempting to connect...")
        conn = psycopg2.connect(**DB_CONFIG)
        print("✅ Connected to PostgreSQL successfully.")

        # Optional: run a test query
        with conn.cursor() as cursor:
            cursor.execute("SELECT version();")
            version = cursor.fetchone()
            print("PostgreSQL version:", version[0])

        conn.close()
        print("Connection closed.")

    except OperationalError as e:
        print("❌ OperationalError:", e)
        sys.exit(1)

    except Exception as e:
        print("❌ Unexpected error:", e)
        sys.exit(1)

if __name__ == "__main__":
    test_postgres_connection()
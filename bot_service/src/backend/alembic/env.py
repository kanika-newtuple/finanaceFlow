import os
from logging.config import fileConfig

from alembic import context
from dotenv import load_dotenv
from sqlalchemy import engine_from_config, pool

# Import models directly to avoid service import chain
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + "/..")

from user.db_models import Base as user_base

# Import models directly without going through __init__.py
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

# Create the bills base directly here to avoid import issues
bills_base = declarative_base()

class Bill(bills_base):
    """SQLAlchemy model for bills - defined here to avoid import issues"""
    __tablename__ = "bills"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Company Information
    vendor = Column(String, index=True)
    vendor_address = Column(Text, nullable=True)
    vendor_contact = Column(String, nullable=True)
    recipient_name = Column(String, index=True, nullable=True)
    recipient_address = Column(Text, nullable=True)
    
    # Document Details
    document_date = Column(DateTime)
    bill_date = Column(DateTime)  # Keep for backward compatibility
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

class Transaction(bills_base):
    """SQLAlchemy model for transactions - defined here to avoid import issues"""
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

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config


# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
# from myapp import mymodel
# target_metadata = mymodel.Base.metadata
# target_metadata = None
target_metadata = [user_base.metadata, bills_base.metadata]

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.


load_dotenv("./etc/.env")

# Use the same PostgreSQL configuration as the main app
DATABASE_URL = "postgresql://root:root@localhost:5433/common"

config = context.config
config.set_main_option("sqlalchemy.url", DATABASE_URL)


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    url = config.get_main_option("sqlalchemy.url")
    config.set_main_option("sqlalchemy.url", url)
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

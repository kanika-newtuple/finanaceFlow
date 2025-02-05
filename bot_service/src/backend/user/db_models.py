from datetime import UTC, datetime

from common.logger import logger
from database.manager import DatabaseServiceManager
from exceptions.db import DBException
from sqlalchemy import JSON, Boolean, Column, DateTime, Integer, String, inspect
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, declarative_base
from sqlalchemy.sql import func
from user.models.interface import UserCreate

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String(2000), unique=True)
    username = Column(String(2000), unique=True)
    hashed_password = Column(String(2000))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now())
    meta_data = Column(JSON, nullable=True)

    # threads = relationship("Thread", back_populates="user")
    def object_as_dict(obj):
        return {c.key: getattr(obj, c.key) for c in inspect(obj).mapper.column_attrs}


class UserModelService:
    def __init__(self, database_service_manager: DatabaseServiceManager) -> None:
        super().__init__()
        self.database_manager = database_service_manager
        self.current_db = self.database_manager.postgres_db_service()
        self.engine = self.current_db.engine

        try:
            if Base:
                logger.info("Trying creating base tables for users..")
                Base.metadata.create_all(bind=self.engine)

        except BaseException as e:
            error = {"ERROR": e}
            logger.critical(f"Could not create base tables for users due to \n {error}, db operations won't work!", exc_info=1)

    def get_user(self, db: Session, username: str = None):
        """
        Retrieves a user from the database based on the username.

        Args:
            db (Session): The database session.
            username (str, optional): The username of the user to retrieve.

        Returns:
            User: The user object if found, otherwise None.
        """
        db_user = db.query(User).filter(User.username == username, User.is_active is True).first()
        return db_user

    def get_user_by_email(self, db: Session, email: str = None):
        """
        Retrieves a user from the database based on the username.

        Args:
            db (Session): The database session.
            username (str, optional): The username of the user to retrieve.

        Returns:
            User: The user object if found, otherwise None.
        """
        try:
            db_user = db.query(User).filter(User.email == email).first()
            return db_user
        except SQLAlchemyError as e:
            raise DBException(f"Could not get user by email due to {e}")

    def create_user(self, db: Session, user: UserCreate) -> User:
        try:
            db_user = User(
                # email=1, # Uncomment this line to test the simulate db error
                email=user.email,
                username=user.username,
                hashed_password=user.password,
            )
            db.add(db_user)
            db.commit()
            db.refresh(db_user)
            return db_user
        except SQLAlchemyError as e:
            raise DBException(f"Could not create user due to {e}")

    def delete_user(self, db: Session, db_user):
        try:
            db_user: User
            db_user.is_active = False
            db_user.updated_at = datetime.now(UTC)
            db.commit()
            db.refresh(db_user)
            return db_user
        except SQLAlchemyError as e:
            raise DBException(f"Could not delete user due to {e}")

    def activate_user(self, db: Session, db_user):
        try:
            db_user: User
            db_user.is_active = True
            db_user.updated_at = datetime.now(UTC)
            db.commit()
            db.refresh(db_user)
            return db_user
        except SQLAlchemyError as e:
            raise DBException(f"Could not activate user due to {e}")

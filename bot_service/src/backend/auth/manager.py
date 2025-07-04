import jwt
import requests
from common.configuration import Configuration
from common.logger import logger
from fastapi import HTTPException, Request, Security, status
from fastapi.security import APIKeyHeader, HTTPBasic
from jwt.algorithms import RSAAlgorithm
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError
import os
from pydantic import BaseModel
from health.models import HealthResponse
from contextlib import contextmanager
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

# bearer_token_header = HTTPBearer()
bearer_token_header = APIKeyHeader(name="x-key")
basic_security = HTTPBasic()

class ServerConfig(BaseModel):
    host: str
    port: str

class PostgreSQLConfig(BaseModel):
    host: str
    port: int
    username: str
    password: str
    db: str
    app_schema: str

class ConfigModel(BaseModel):
    server_configuration: ServerConfig
    postgresql_configuration: PostgreSQLConfig

class Configuration:
    def __init__(self):
        config_obj = {
            "server_configuration": {
                "host": os.environ.get("HOST", "0.0.0.0"),
                "port": os.environ.get("PORT", "8081"),
            },
            "postgresql_configuration": {
                "host": os.environ.get("POSTGRES_HOST", "localhost"),
                "port": int(os.environ.get("POSTGRES_PORT", "5432")),
                "username": os.environ.get("POSTGRES_USERNAME", "postgres"),
                "password": os.environ.get("POSTGRES_PASSWRD", "postgres"),
                "db": os.environ.get("POSTGRES_DB", "postgres"),
                "app_schema": os.environ.get("POSTGRES_APP_SCHEMA", "public"),
            }
        }
        self._configuration = ConfigModel(**config_obj)

    def configuration(self):
        return self._configuration

class AuthManager:
    def __init__(self, config: Configuration) -> None:
        self.config_env: Configuration = config.configuration()
        self.config_ini = config.config_ini()
        # bearer_token_header = HTTPBearer()
        # self.jwks_url = self.config_env.auth_configuration.jwks_url
        # self.auth0_audience = self.config_env.auth_configuration.auth0_audience

    def authenticate(self, request: Request, bearer_token: str = Security(bearer_token_header)):
        logger.info("Starting API key validation")
        token = bearer_token.credentials
        jwks_url = self.jwks_url
        jwks = requests.get(jwks_url, timeout=10).json()
        if not jwks:
            logger.error("JWKS URL timeout")
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="JWKS URL timeout")
        headers = jwt.get_unverified_header(token)
        kid = headers["kid"]

        public_key = None
        for key in jwks["keys"]:
            if key["kid"] == kid:
                public_key = RSAAlgorithm.from_jwk(key)
                break

        if not public_key:
            logger.error("Public key not found")
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Public key not found")

        try:
            decoded_token = jwt.decode(token, public_key, algorithms=["RS256"], audience=self.auth0_audience)
            logger.info("Token successfully validated")
            request.state.user = decoded_token
            return decoded_token
        except ExpiredSignatureError:
            logger.warning("Token has expired")
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired")
        except InvalidTokenError as e:
            logger.error(f"Invalid token: {str(e)}")
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Invalid token: {str(e)}")

    def validate_api_key(self, bearer_token: str = Security(bearer_token_header)):

        ttoken = self.config_env.common_configuration.api_key
        token = bearer_token

        try:
            if token == ttoken:
                return True
            raise ValueError("Unauthorized")
        except Exception as e:
            logger.error(f"Failed to validate API key: {str(e)}")
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired API key")

class HealthResponse(BaseModel):
    """Represents the health response"""
    alive: bool

class HealthServiceManager:
    """Implements the health service manager"""
    async def ping(self) -> HealthResponse:
        """Returns the health response"""
        return HealthResponse(alive=True)

class PostgresDBService:
    def __init__(self, config: Configuration) -> None:
        """Initialize PostgresDBService with configuration"""
        self.config = config
        postgres_config = config.configuration().postgresql_configuration
        
        connection_string = f"postgresql://{postgres_config.username}:{postgres_config.password}@{postgres_config.host}:{postgres_config.port}/{postgres_config.db}"
        self.engine = create_engine(connection_string)
        self.session_factory = sessionmaker(bind=self.engine)
        self.Session = scoped_session(self.session_factory)
    
    def get_db_session(self):
        """Returns a database session"""
        return self.Session()
    
    @contextmanager
    def session_scope(self):
        """Provide a transactional scope around a series of operations."""
        session = self.get_db_session()
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Database error: {str(e)}")
            raise
        finally:
            session.close()

class DatabaseServiceManager:
    """Manages database service instances"""
    def __init__(self, config: Configuration):
        """Initialize with configuration"""
        self.config = config
        self._postgres_db_service = PostgresDBService(config)
    
    def postgres_db_service(self) -> PostgresDBService:
        """Returns the PostgreSQL database service"""
        return self._postgres_db_service

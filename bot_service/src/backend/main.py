"""Main module for the backend application.

This module defines the main entry point for the FastAPI application,
initializes and configures the necessary services and components,
and starts the Uvicorn server.
"""

from argparse import ArgumentParser

import uvicorn
from auth.manager import AuthManager
from common.configuration import Configuration
from database.manager import DatabaseServiceManager
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from health.controller import HealthRestController
from health.manager import HealthServiceManager
from LLM.manager import LLMServiceManager
from metrics.controller import MetricsRestController
from metrics.manager import MetricsService
from user.controller import UserRestController
from user.db_models import UserModelService
from user.manager import UserServiceManager


def main():
    """
    Main entry point for the application.
    """
    parser = ArgumentParser(description="Runs the BOT service")
    parser.add_argument("-e", "--env", help="Path to .env file", default="./etc/.env")
    args = parser.parse_args()
    load_dotenv(args.env)

    # common services
    config = Configuration()
    config_env = config.configuration()
    config_ini = config.config_ini()
    app_router = APIRouter()

    auth_manager = AuthManager(config)

    health_service_manager = HealthServiceManager()
    health_rest_contoller = HealthRestController(health_service_manager).prepare(app_router)

    database_service_manager = DatabaseServiceManager(config)
    llm_service_manager = LLMServiceManager()

    user_db_model_service = UserModelService(database_service_manager)
    user_service_manager = UserServiceManager(user_db_model_service, config)
    user_rest_controller = UserRestController(user_service_manager, database_service_manager)
    user_rest_controller.prepare(app_router)

    metrics_service_manager = MetricsService()
    metrics_rest_controller = MetricsRestController(metrics_service_manager).prepare(app_router, Depends(user_rest_controller.get_current_username))

    app = FastAPI()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(app_router, prefix="/v1/api")

    uvicorn.run("main:app", host=config_env.server_configuration.host, timeout_keep_alive=600, port=int(config_env.server_configuration.port), reload=True)


if __name__ == "__main__":
    """
    Main entry point for the application.
    """
    main()

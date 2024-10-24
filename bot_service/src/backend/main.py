from argparse import ArgumentParser

import uvicorn
from common.configuration import Configuration
from database.manager import DatabaseServiceManager
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from health.controller import HealthRestController
from health.controller import app as HealthRouter
from health.manager import HealthServiceManager
from LLM.manager import LLMServiceManager

parser = ArgumentParser(description="Runs the BOT service")
parser.add_argument("-e", "--env", help="Path to .env file", default="./etc/.env")
args = parser.parse_args()
load_dotenv(args.env)

# common services
config = Configuration()
config_env = config.configuration()
config_ini = config.config_ini()

health_service_manager = HealthServiceManager()
health_rest_contoller = HealthRestController(health_service_manager).prepare()

database_service_manager = DatabaseServiceManager(config)
llm_service_manager = LLMServiceManager()


app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(HealthRouter, prefix="/api")

if __name__ == "__main__":
    uvicorn.run("main:app", host=config_env.server_configuration.host, timeout_keep_alive=600, port=int(config_env.server_configuration.port), reload=True)

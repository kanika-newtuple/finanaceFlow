"""Health REST controller module"""

# from common.controller import APIRouter
from fastapi import APIRouter
from health.manager import HealthServiceManager
from health.models import HealthResponse
from uuid import uuid4

app = APIRouter()


class HealthRestController:
    """Implements health REST controller"""

    def __init__(self, health_service_manager: HealthServiceManager) -> None:
        super().__init__()
        self._health_service_manager = health_service_manager

    def prepare(self) -> None:

        @app.get("/health", response_model=HealthResponse)
        async def health() -> HealthResponse:
            """Returns the health response"""
            return await self._health_service_manager.ping()
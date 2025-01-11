from common.logger import logger
from health.models import HealthResponse


class HealthServiceManager:
    """Implements the health service manager"""

    async def ping(self) -> HealthResponse:
        """Returns the health response"""
        logger.info("HealthServiceManager.ping")
        return HealthResponse(alive=True)

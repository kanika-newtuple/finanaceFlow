# This file contains the manager for the metrics service
from monitoring.prometheus import (
    CLASSIFY_EXTRACT_TIME,
    INFO,
    OPERATION_TIME,
    REQUEST_COUNT,
    REQUEST_TIME,
    SYSTEM_USAGE,
    prom_client,
)


class MetricsService:
    """Implements the Metrics service manager"""

    def get_metrics(self):
        metrics = []
        metrics.append((prom_client.generate_latest(REQUEST_COUNT).decode("utf-8")))
        metrics.append((prom_client.generate_latest(SYSTEM_USAGE).decode("utf-8")))
        metrics.append((prom_client.generate_latest(INFO).decode("utf-8")))
        metrics.append((prom_client.generate_latest(REQUEST_TIME).decode("utf-8")))
        metrics.append((prom_client.generate_latest(OPERATION_TIME).decode("utf-8")))
        metrics.append((prom_client.generate_latest(CLASSIFY_EXTRACT_TIME).decode("utf-8")))
        return metrics  # m

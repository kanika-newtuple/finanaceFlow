from time import sleep

from celery import Celery, Task
from celery.result import AsyncResult
from common.logger import logger, tracer


class TasksService:
    """Implements the task service"""

    def task(self):
        """Create a new task"""
        with tracer.start_as_current_span("TasksService.task"):
            logger.info("Creating a new task")
            sleep(10)
            return "Hello"  # noqa

    def get_task(self, task_id: str):
        """Get the status of a task"""
        with tracer.start_as_current_span("TasksService.get_task"):
            logger.info(f"Getting task status for task_id: {task_id}")
            task_response = AsyncResult(task_id)

            task_result = {"task_id": task_response.task_id, "task_status": task_response.status, "task_result": task_response.result}
            return task_result

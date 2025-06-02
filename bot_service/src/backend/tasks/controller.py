"""Health REST controller module"""

# from common.controller import APIRouter
import datetime as dt
from time import sleep

from celery import Celery, Task
from celery.result import AsyncResult
from celery_tasks import dummy_task
from fastapi import APIRouter
from tasks.manager import TasksService


class TaskRestController:
    """Implements task REST controller"""

    def __init__(self, task_service: TasksService) -> None:
        super().__init__()
        self._task_service = task_service

    def prepare(self, app: APIRouter) -> None:

        @app.get("/create_task")
        async def create_task():
            """Creates a new task"""
            # dummy_task: Task
            # task = dummy_task.delay()
            # dummy_task: Task = dummy_task.s()  # Create a signature for the task
            task = dummy_task.delay()
            # task = dummy_task.apply_async(eta=dt.datetime(2025, 5, 31, 10, 0))
            return {"task_id": task.id, "status": task.status, "result": task.result}

        @app.get("/get_task/{task_id}")
        async def get_task(task_id: str):
            """Returns the readiness response"""
            task_status_response = self._task_service.get_task(task_id)
            return task_status_response

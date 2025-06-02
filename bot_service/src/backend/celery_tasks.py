import os
from time import sleep

from celery import Celery
from celery.schedules import crontab

celery = Celery(__name__)
BROKER_URL = "redis://localhost:6379/0"
BACKEND_URL = "redis://localhost:6379/1"
celery.conf.broker_url = os.environ.get("CELERY_BROKER_URL", BROKER_URL)
celery.conf.result_backend = os.environ.get("CELERY_RESULT_BACKEND", BACKEND_URL)


from tasks.manager import TasksService

task_service = TasksService()


@celery.task(name="dummy_task.delay")
def dummy_task():
    """Celery task for dummy_task"""
    # Add your async task logic here
    task_service.task()
    return True

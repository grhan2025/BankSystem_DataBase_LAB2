# BankDatabase/tasks.py
from celery import shared_task
from django.db import connection
import logging

logger = logging.getLogger(__name__)

@shared_task
def monthly_interest_settlement():
    """
    每月1日凌晨自动结息。
    Celery Beat 配置（settings.py）：
    
    from celery.schedules import crontab
    CELERY_BEAT_SCHEDULE = {
        'monthly-interest': {
            'task': 'BankDatabase.tasks.monthly_interest_settlement',
            'schedule': crontab(hour=0, minute=0, day_of_month=1),
        },
    }
    """
    try:
        with connection.cursor() as cursor:
            cursor.callproc('apply_saving_interest')
        with connection.cursor() as cursor:
            cursor.callproc('apply_loan_interest')
        logger.info("月度结息完成")
        return "success"
    except Exception as e:
        logger.error(f"结息失败: {e}")
        raise
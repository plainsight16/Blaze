from apscheduler.schedulers.background import BackgroundScheduler
from app.database import SessionLocal
from app.services.cycle import process_all_due_slots

def _run_due_slots() -> None:
    db = SessionLocal()
    try:
        process_all_due_slots(db)
    finally:
        db.close()

def start_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler()
    scheduler.add_job(_run_due_slots, "interval", hours=1, id="process_due_slots")
    scheduler.start()
    return scheduler
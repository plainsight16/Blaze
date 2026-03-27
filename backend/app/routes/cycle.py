from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.cycle import CycleResponse, InsuranceWalletResponse, StartCycleRequest
from app.services import cycle as svc
from app.services import groups as group_svc
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.post(
    "/groups/{group_id}/cycle",
    response_model=CycleResponse,
    status_code=status.HTTP_201_CREATED,
)
def start_cycle(
    group_id: str,
    payload: StartCycleRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CycleResponse:
    group = group_svc._get_group_or_404(group_id, db)
    group_svc._require_admin(current_user.id, group_id, db)
    cycle = svc.start_cycle(
        db=db,
        group=group,
        actor=current_user,
        frequency=payload.frequency,
        max_reduction_pct=payload.max_reduction_pct,
    )
    return CycleResponse.model_validate(cycle)


@router.get("/groups/{group_id}/cycle", response_model=CycleResponse)
def get_active_cycle(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CycleResponse:
    group_svc._get_group_or_404(group_id, db)
    group_svc._require_membership(current_user.id, group_id, db)
    cycle = svc.get_active_cycle(group_id, db)
    if not cycle:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No active cycle for this group.")
    return CycleResponse.model_validate(cycle)


@router.get("/groups/{group_id}/cycle/{cycle_id}", response_model=CycleResponse)
def get_cycle(
    group_id: str,
    cycle_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CycleResponse:
    group_svc._get_group_or_404(group_id, db)
    group_svc._require_membership(current_user.id, group_id, db)
    cycle = svc.get_cycle_by_id(cycle_id, db)
    if not cycle or cycle.group_id != group_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cycle not found.")
    return CycleResponse.model_validate(cycle)


@router.get(
    "/groups/{group_id}/cycle/{cycle_id}/insurance",
    response_model=InsuranceWalletResponse,
)
def get_my_insurance(
    group_id: str,
    cycle_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> InsuranceWalletResponse:
    group_svc._get_group_or_404(group_id, db)
    group_svc._require_membership(current_user.id, group_id, db)
    iw = svc.get_user_insurance_wallet(cycle_id, current_user.id, db)
    if not iw:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No insurance wallet found for this cycle.")
    return InsuranceWalletResponse.model_validate(iw)


@router.post("/internal/process-due-slots", include_in_schema=False)
def trigger_due_slots(db: Session = Depends(get_db)) -> dict:
    """
    Internal endpoint for the scheduler to call (cron job / APScheduler).
    Lock this down to internal traffic only in production.
    """
    svc.process_all_due_slots(db)
    return {"ok": True}
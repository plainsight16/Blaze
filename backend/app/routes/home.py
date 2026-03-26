from fastapi import APIRouter
from fastapi.responses import RedirectResponse

router = APIRouter()

@router.get("/")
def docs():
    response = RedirectResponse(url='/docs')
    return response
from fastapi import FastAPI
from app.routes import auth, groups

app = FastAPI(title="Auth API", version="1.0.0")

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(groups.router, prefix="/groups", tags=["groups"]) 
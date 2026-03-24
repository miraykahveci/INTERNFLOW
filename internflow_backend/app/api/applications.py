from fastapi import APIRouter

router = APIRouter()

@router.get("/applications")
async def get_applications():
    return {"applications": []}
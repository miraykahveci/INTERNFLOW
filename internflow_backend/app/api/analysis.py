from fastapi import APIRouter

router = APIRouter()

@router.get("/analysis/health")
async def analysis_health():
    return {"status": "ok", "module": "analysis"}
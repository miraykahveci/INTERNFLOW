from fastapi import FastAPI
from app.api import analysis, applications

app = FastAPI(
    title="InternFlow AI Service",
    version="1.0.0"
)

app.include_router(analysis.router, prefix="/api/v1")
app.include_router(applications.router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "InternFlow AI Service"}
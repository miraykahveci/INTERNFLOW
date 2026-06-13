from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv


load_dotenv()

from app.api import analysis, applications, yonerge

app = FastAPI(
    title="InternFlow AI Service",
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analysis.router, prefix="/api/v1")
app.include_router(applications.router, prefix="/api/v1")
app.include_router(yonerge.router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "InternFlow AI Service"}
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv


load_dotenv()

from app.api import analysis, applications, yonerge

app = FastAPI(
    title="InternFlow AI Service",
    version="1.0.0"
)


# ============================================
# CORS Configuration
# ============================================
# Production: sadece bilinen Netlify URL
# Development: tüm lokal portlar 
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://famous-biscuit-3638d1.netlify.app",
    ],
    allow_origin_regex=r"http://localhost:\d+|http://127\.0\.0\.1:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================
# Routers
# ============================================
app.include_router(analysis.router, prefix="/api/v1")
app.include_router(applications.router, prefix="/api/v1")
app.include_router(yonerge.router, prefix="/api/v1")


# ============================================
# Health Check
# ============================================
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "InternFlow AI Service"}
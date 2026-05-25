"""
Analysis API Router

AI tabanlı staj defteri analizi endpoint'leri:
- POST /api/v1/ai/analyze/{document_id}          
- GET  /api/v1/ai/analysis/{analysis_id}/status  
- GET  /api/v1/ai/analysis/document/{document_id} 
- GET  /api/v1/ai/analyses                        

Mimari not:
- Analiz başlatma (POST) ile işleme (orchestrator) ayrıldı.
- POST kaydı açıp HEMEN döner, ağır iş BackgroundTask ile arka planda çalışır.
- Kullanıcı GET /status ile polling yaparak ilerlemeyi takip eder.
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks

from app.db.supabase_client import supabase_admin as supabase, supabase_admin
from app.services.ai_orchestrator import run_analysis_pipeline

router = APIRouter()


# ==========================================================================
# Health check 
# ==========================================================================
@router.get("/analysis/health")
async def analysis_health():
    return {"status": "ok", "module": "analysis"}


# ==========================================================================
# POST /ai/analyze/{document_id} 
# ==========================================================================
@router.post("/ai/analyze/{document_id}")
async def start_analysis(document_id: str, background_tasks: BackgroundTasks):
    
    try:
    
        doc_resp = supabase.table("documents").select(
            "document_id, doc_type"
        ).eq("document_id", document_id).single().execute()

        if not doc_resp.data:
            raise HTTPException(status_code=404, detail="Belge bulunamadı")

        if doc_resp.data["doc_type"] != "staj_defteri":
            raise HTTPException(
                status_code=400,
                detail=f"Sadece staj defteri analiz edilebilir. "
                       f"Bu belge: {doc_resp.data['doc_type']}",
            )

        insert_resp = supabase.table("analysis_result").insert({
            "document_id": document_id,
            "status": "processing",
            "progress": 0,
            "current_step": "Analiz başlatılıyor",
        }).execute()

        analysis_id = insert_resp.data[0]["analysis_id"]

        
        background_tasks.add_task(
            run_analysis_pipeline, analysis_id, document_id
        )

        return {
            "analysis_id": analysis_id,
            "status": "processing",
            "message": "Analiz başlatıldı. Durumu /status endpoint'inden takip edebilirsiniz.",
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()  # ← Tam hatayı terminale bas
        raise HTTPException(status_code=500, detail=f"Analiz başlatılamadı: {str(e)}")


# ==========================================================================
# GET /ai/analysis/{analysis_id}/status 
# ==========================================================================
@router.get("/ai/analysis/{analysis_id}/status")
async def get_analysis_status(analysis_id: str):
   
    try:
        resp = supabase.table("analysis_result").select(
            "analysis_id, status, progress, current_step, error_message"
        ).eq("analysis_id", analysis_id).single().execute()

        if not resp.data:
            raise HTTPException(status_code=404, detail="Analiz bulunamadı")

        return resp.data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Durum alınamadı: {str(e)}")


# ==========================================================================
# GET /ai/analysis/document/{document_id} 
# ==========================================================================
@router.get("/ai/analysis/document/{document_id}")
async def get_analysis_result(document_id: str):
    
    try:
        resp = supabase.table("analysis_result").select(
            "analysis_id, document_id, similar_document_id, status, "
            "progress, plagiarism_score, risk_level, is_risky, "
            "ai_summary, plagiarism_explanation, masked_text, completed_at"
        ).eq("document_id", document_id).order(
            "completed_at", desc=True
        ).limit(1).execute()

        if not resp.data:
            raise HTTPException(
                status_code=404, detail="Bu belge için analiz bulunamadı"
            )

        return resp.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sonuç alınamadı: {str(e)}")


# ==========================================================================
# GET /ai/analyses 
# ==========================================================================
@router.get("/ai/analyses")
async def list_analyses():
    """
    Tüm analizleri listeler (en yeniden eskiye).
    Akademisyen panosu için özet liste.
    """
    try:
        resp = supabase.table("analysis_result").select(
            "analysis_id, document_id, status, risk_level, "
            "plagiarism_score, is_risky, completed_at"
        ).order("completed_at", desc=True).execute()

        return {"count": len(resp.data or []), "analyses": resp.data or []}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Liste alınamadı: {str(e)}")
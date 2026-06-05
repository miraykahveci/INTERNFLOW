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
# POST 
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
        traceback.print_exc() 
        raise HTTPException(status_code=500, detail=f"Analiz başlatılamadı: {str(e)}")


# ==========================================================================
# GET 
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
# GET 
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

        result = resp.data[0]

        
        similar_doc_id = result.get("similar_document_id")
        if similar_doc_id:
            try:
                similar_doc = supabase.table("documents").select(
                    "intern_id, "
                    "internship!inner("
                    "company_name, "
                    "users!internship_student_id_fkey(full_name, student_number)"
                    ")"
                ).eq("document_id", similar_doc_id).limit(1).execute()

                if similar_doc.data and len(similar_doc.data) > 0:
                    record = similar_doc.data[0]
                    internship = record.get("internship") or {}
                    user = internship.get("users") or {}
                    result["similar_student_name"] = user.get("full_name")
                    result["similar_student_number"] = user.get("student_number")
                    result["similar_company_name"] = internship.get("company_name")
            except Exception as e:
                print(f"[get_analysis_result] Similar zenginleştirme hatası: {e}")

        return result

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
    

# ==========================================================================
# get results academician pano
# ==========================================================================
@router.get("/ai/analyses/pending")
async def list_pending_documents(academician_id: str):
   
    try:
        documents = supabase.table("documents") \
            .select("*, internship!inner(intern_id, student_id, academician_id, company_name, users!internship_student_id_fkey(full_name, student_number))") \
            .eq("doc_type", "staj_defteri") \
            .eq("internship.academician_id", academician_id) \
            .execute()
        
        if not documents.data:
            return {"count": 0, "pending": []}
        
        document_ids = [doc["document_id"] for doc in documents.data]
        
        existing = supabase.table("analysis_result") \
            .select("document_id") \
            .in_("document_id", document_ids) \
            .execute()
        
        analyzed_ids = {row["document_id"] for row in (existing.data or [])}
        
        pending = [
            {
                "document_id": doc["document_id"],
                "file_url": doc["file_url"],
                "uploaded_at": doc.get("uploaded_at"),
                "intern_id": doc["internship"]["intern_id"],
                "student_id": doc["internship"]["student_id"],
                "student_name": doc["internship"]["users"]["full_name"] if doc["internship"].get("users") else "Bilinmeyen",
                "student_number": doc["internship"]["users"].get("student_number") if doc["internship"].get("users") else None,
                "company_name": doc["internship"].get("company_name", "-"),
            }
            for doc in documents.data
            if doc["document_id"] not in analyzed_ids
        ]
        
        return {"count": len(pending), "pending": pending}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Bekleyen defterler alınamadı: {str(e)}")


@router.get("/ai/analyses/completed")
async def list_completed_analyses(academician_id: str):
  
    try:
        
        documents = supabase.table("documents") \
            .select("document_id, internship!inner(student_id, academician_id, company_name, users!internship_student_id_fkey(full_name, student_number))") \
            .eq("doc_type", "staj_defteri") \
            .eq("internship.academician_id", academician_id) \
            .execute()
        
        if not documents.data:
            return {"count": 0, "completed": []}
        
        document_ids = [doc["document_id"] for doc in documents.data]
        doc_map = {doc["document_id"]: doc for doc in documents.data}
        
    
        analyses = supabase.table("analysis_result") \
            .select("*") \
            .in_("document_id", document_ids) \
            .eq("status", "completed") \
            .order("completed_at", desc=True) \
            .execute()
        
        
        completed = []
        for a in (analyses.data or []):
            doc = doc_map.get(a["document_id"], {})
            internship = doc.get("internship", {})
            user = internship.get("users") or {}
            completed.append({
                "analysis_id": a["analysis_id"],
                "document_id": a["document_id"],
                "risk_level": a.get("risk_level"),
                "plagiarism_score": a.get("plagiarism_score"),
                "is_risky": a.get("is_risky"),
                "completed_at": a.get("completed_at"),
                "student_name": user.get("full_name", "Bilinmeyen"),
                "student_number": user.get("student_number"),
                "company_name": internship.get("company_name", "-"),
            })
        
        return {"count": len(completed), "completed": completed}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Tamamlanan analizler alınamadı: {str(e)}")
"""
AI Orchestrator - Pipeline Koordinatörü

Bu modül, tüm AI servislerini birbirine bağlayan pipeline'ı yönetir.
document_id alır, baştan sona analizi yürütür, sonucu analysis_result'a yazar.

Mimari not:
- Bu bir "orchestrator" (orkestra şefi) deseni. Kendisi iş yapmaz,
  uzman servisleri doğru sırayla çağırır ve koordine eder.
- Her adımda progress güncellenir → frontend polling ile takip eder.
- Hata yönetimi: herhangi bir adım patlarsa analiz 'failed' işaretlenir,
  pipeline çökmez (graceful failure).
- PDF in-memory işlenir (diske yazılmaz) - KVKK + performans.
"""

from datetime import datetime, timezone

from app.db.supabase_client import supabase_admin as supabase, supabase_admin
from app.ai.text_extractor import get_text_extractor
from app.ai.pii_masker import get_pii_masker
from app.ai.vector_service import get_embedder
from app.ai.similarity_engine import get_similarity_engine
from app.ai.llm_service import get_llm_service

STORAGE_BUCKET = "documents"


# ==========================================================================
# YARDIMCI FONKSİYONLAR
# ==========================================================================

def _update_progress(analysis_id: str, progress: int, step: str) -> None:
    
    try:
        supabase.table("analysis_result").update({
            "progress": progress,
            "current_step": step,
        }).eq("analysis_id", analysis_id).execute()
        print(f"[Orchestrator] {analysis_id} → %{progress}: {step}")
    except Exception as e:
        print(f"[Orchestrator] Progress güncelleme hatası: {e}")


def _mark_as_failed(analysis_id: str, error_message: str) -> None:
   
    try:
        supabase.table("analysis_result").update({
            "status": "failed",
            "error_message": error_message[:500],  # çok uzun olmasın
            "current_step": "Hata oluştu",
        }).eq("analysis_id", analysis_id).execute()
        print(f"[Orchestrator] {analysis_id} → FAILED: {error_message}")
    except Exception as e:
        print(f"[Orchestrator] Failed işaretleme hatası: {e}")


# ==========================================================================
# ANA PIPELINE
# ==========================================================================

async def run_analysis_pipeline(analysis_id: str, document_id: str) -> None:
   
    try:
        # ------------------------------------------------------------------
        # ADIM 0: Belge bilgilerini al + staj defteri mi kontrol et
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 5, "Belge bilgileri alınıyor")

        doc_response = supabase.table("documents").select(
            "document_id, intern_id, file_url, doc_type"
        ).eq("document_id", document_id).single().execute()

        document = doc_response.data
        if not document:
            raise ValueError(f"Belge bulunamadı: {document_id}")

        if document["doc_type"] != "staj_defteri":
            raise ValueError(
                f"Bu belge analiz edilemez. Tip: {document['doc_type']}. "
                "Sadece staj_defteri analiz edilebilir."
            )

        file_url = document["file_url"]

        # ------------------------------------------------------------------
        # ADIM 1: PDF'i Storage'dan indir (in-memory, service key ile)
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 15, "PDF indiriliyor")

        pdf_bytes = supabase_admin.storage.from_(STORAGE_BUCKET).download(file_url)
        if not pdf_bytes:
            raise ValueError(f"PDF indirilemedi: {file_url}")

        # ------------------------------------------------------------------
        # ADIM 2: PDF'ten metin çıkar
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 30, "Metin çıkarılıyor")

        extractor = get_text_extractor()
        text = extractor.extract(pdf_bytes, "application/pdf")
        if not text or len(text.strip()) < 50:
            raise ValueError("PDF'ten yeterli metin çıkarılamadı")

        # ------------------------------------------------------------------
        # ADIM 3: PII maskele (embedding'den ÖNCE - Privacy by Design)
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 45, "Kişisel veriler maskeleniyor")

        masker = get_pii_masker()
        masked_text = masker.mask(text)

        # ------------------------------------------------------------------
        # ADIM 4: Embedding üret 
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 60, "Anlamsal vektör üretiliyor")

        embedder = get_embedder()
        embedding = embedder.generate_embedding(masked_text)

        # ------------------------------------------------------------------
        # ADIM 5: Embedding'i kaydet 
        # ------------------------------------------------------------------
        supabase.table("analysis_result").update({
            "embedding": embedding,
            "masked_text": masked_text,
        }).eq("analysis_id", analysis_id).execute()

        # ------------------------------------------------------------------
        # ADIM 6: Benzerlik analizi 
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 75, "Benzerlik analizi yapılıyor")

        engine = get_similarity_engine()
        top_match = engine.get_top_match(
            query_embedding=embedding,
            exclude_analysis_id=analysis_id,  # kendini hariç tut
        )

        
        similar_document_id = None
        plagiarism_score = 0.0
        if top_match:
            similar_document_id = top_match.get("document_id")
            plagiarism_score = float(top_match.get("similarity", 0.0))

        # ------------------------------------------------------------------
        # ADIM 7: Risk seviyesi hesapla 
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 85, "Risk seviyesi belirleniyor")

        risk_level = engine.calculate_risk_level(plagiarism_score)
        is_risky = engine.is_risky(plagiarism_score)

        # ------------------------------------------------------------------
        # ADIM 8: AI özet üret 
        # ------------------------------------------------------------------
        _update_progress(analysis_id, 92, "AI özet hazırlanıyor")

        llm = get_llm_service()
        ai_summary = await llm.summarize(masked_text)

        # ------------------------------------------------------------------
        # ADIM 9: İntihal açıklaması 
        # ------------------------------------------------------------------
        plagiarism_explanation = None
        if risk_level == "high" and similar_document_id:
            _update_progress(analysis_id, 96, "İntihal açıklaması hazırlanıyor")
            
            similar_text = ""
            try:
                similar_resp = supabase.table("analysis_result").select(
                    "masked_text"
                ).eq("document_id", similar_document_id).eq(
                    "status", "completed"
                ).limit(1).execute()
                if similar_resp.data:
                    similar_text = similar_resp.data[0].get("masked_text") or ""
            except Exception as e:
                print(f"[Orchestrator] Benzer metin çekilemedi: {e}")
            
            plagiarism_explanation = await llm.explain_similarity(
                masked_text, similar_text
            )

        # ------------------------------------------------------------------
        # ADIM 10: Sonuçları kaydet 
        # ------------------------------------------------------------------
        supabase.table("analysis_result").update({
            "status": "completed",
            "progress": 100,
            "current_step": "Tamamlandı",
            "similar_document_id": similar_document_id,
            "plagiarism_score": plagiarism_score,
            "risk_level": risk_level,
            "is_risky": is_risky,
            "ai_summary": ai_summary,
            "plagiarism_explanation": plagiarism_explanation,
            "completed_at": datetime.now(timezone.utc).isoformat(),
        }).eq("analysis_id", analysis_id).execute()

        print(f"[Orchestrator] ✅ Analiz tamamlandı: {analysis_id}")
        print(f"   → Risk: {risk_level}, Skor: {plagiarism_score:.4f}")

    except Exception as e:
        _mark_as_failed(analysis_id, str(e))
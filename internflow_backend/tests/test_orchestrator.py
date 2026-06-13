"""
AI Orchestrator Birim Testleri
===============================
Tüm AI pipeline'ının orkestrasyonunu test eder.
Her dış servis (PDF, PII, Embedder, Similarity, LLM, Supabase) MOCK'lanır.
"""

import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from app.services.ai_orchestrator import (
    run_analysis_pipeline,
    _update_progress,
    _mark_as_failed,
)


# ============================================================
# Helper: Tüm bağımlılıkları mock'layan fixture
# ============================================================

def setup_full_pipeline_mocks(
    mock_supabase,
    mock_supabase_admin,
    mock_extractor,
    mock_masker,
    mock_embedder,
    mock_engine,
    mock_llm,
    *,
    doc_type="staj_defteri",
    extracted_text="Test staj defteri içeriği. " * 20,
    embedding_vector=None,
    top_match=None,
    risk_level="low",
    summary="Mock AI özet metnidir.",
    explanation="Mock intihal açıklaması.",
):
    """Tüm mock'ları varsayılan değerlerle hazırlar."""

    if embedding_vector is None:
        embedding_vector = [0.1] * 768

    # 1. supabase.table().select().single().execute() 
    doc_response = MagicMock()
    doc_response.data = {
        "document_id": "doc-123",
        "intern_id": "intern-456",
        "file_url": "path/to/file.pdf",
        "doc_type": doc_type,
    }

    # 2. supabase.table().update().eq().execute() 
    update_response = MagicMock()
    update_response.data = []

    # supabase.table chain mock
    table_mock = MagicMock()
    table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = doc_response
    table_mock.update.return_value.eq.return_value.execute.return_value = update_response

    # Benzer metin sorgusu için
    similar_response = MagicMock()
    similar_response.data = [{"masked_text": "Benzer defter metni"}]
    table_mock.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = similar_response

    mock_supabase.table.return_value = table_mock

    # 3. supabase_admin.storage.from_().download()
    storage_mock = MagicMock()
    storage_mock.download.return_value = b"%PDF-1.4 fake pdf bytes"
    mock_supabase_admin.storage.from_.return_value = storage_mock

    # 4. Text extractor
    extractor_instance = MagicMock()
    extractor_instance.extract.return_value = extracted_text
    mock_extractor.return_value = extractor_instance

    # 5. PII Masker
    masker_instance = MagicMock()
    masker_instance.mask.return_value = "Maskelenmiş metin"
    mock_masker.return_value = masker_instance

    # 6. Embedder
    embedder_instance = MagicMock()
    embedder_instance.generate_embedding.return_value = embedding_vector
    mock_embedder.return_value = embedder_instance

    # 7. Similarity Engine
    engine_instance = MagicMock()
    engine_instance.get_top_match.return_value = top_match
    engine_instance.calculate_risk_level.return_value = risk_level
    engine_instance.is_risky.return_value = (risk_level == "high")
    mock_engine.return_value = engine_instance

    # 8. LLM Service (async)
    llm_instance = MagicMock()
    llm_instance.summarize = AsyncMock(return_value=summary)
    llm_instance.explain_similarity = AsyncMock(return_value=explanation)
    mock_llm.return_value = llm_instance

    return {
        "supabase_table": table_mock,
        "extractor": extractor_instance,
        "masker": masker_instance,
        "embedder": embedder_instance,
        "engine": engine_instance,
        "llm": llm_instance,
        "storage": storage_mock,
    }


# ============================================================
# 1. Helper Function Tests (_update_progress, _mark_as_failed)
# ============================================================

class TestProgressUpdate:
    """Progress güncelleme yardımcı fonksiyonu."""

    @patch("app.services.ai_orchestrator.supabase")
    def test_update_progress_calls_supabase(self, mock_supabase):
        """_update_progress Supabase'e update gönderir."""
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        _update_progress("analysis-1", 50, "Test adım")

        mock_supabase.table.assert_called_with("analysis_result")
        update_call = mock_supabase.table.return_value.update.call_args
        assert update_call[0][0]["progress"] == 50
        assert update_call[0][0]["current_step"] == "Test adım"

    @patch("app.services.ai_orchestrator.supabase")
    def test_update_progress_handles_exception(self, mock_supabase):
        """_update_progress hata atmamalı, sadece print etmeli."""
        mock_supabase.table.side_effect = Exception("DB error")

        
        _update_progress("analysis-1", 50, "Test")


class TestMarkAsFailed:
    """Analysis'ı failed olarak işaretleme."""

    @patch("app.services.ai_orchestrator.supabase")
    def test_mark_as_failed_sets_status(self, mock_supabase):
        """_mark_as_failed status='failed' yapar."""
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        _mark_as_failed("analysis-1", "Test hata")

        update_call = mock_supabase.table.return_value.update.call_args
        assert update_call[0][0]["status"] == "failed"
        assert "Test hata" in update_call[0][0]["error_message"]

    @patch("app.services.ai_orchestrator.supabase")
    def test_mark_as_failed_truncates_long_message(self, mock_supabase):
        """Çok uzun hata mesajı 500 karaktere kırpılmalı."""
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        long_error = "x" * 1000
        _mark_as_failed("analysis-1", long_error)

        update_call = mock_supabase.table.return_value.update.call_args
        error_msg = update_call[0][0]["error_message"]
        assert len(error_msg) <= 500


# ============================================================
# 2. Pipeline - Validation Errors
# ============================================================

class TestPipelineValidation:
    """Pipeline'ın validation hatalarını ele alış testleri."""

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_document_not_found_marks_as_failed(self, mock_supabase, mock_admin):
        """Belge bulunamazsa pipeline failed olarak işaretlenmeli."""
        
        doc_response = MagicMock()
        doc_response.data = None

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = doc_response
        table_mock.update.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase.table.return_value = table_mock

        await run_analysis_pipeline("analysis-1", "doc-nonexistent")

        # _mark_as_failed çağrıldı mı? (update with status='failed')
        # Update çağrılarını kontrol et
        update_calls = [
            call for call in table_mock.update.call_args_list
            if call[0][0].get("status") == "failed"
        ]
        assert len(update_calls) > 0

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_wrong_doc_type_fails(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Yanlış belge türü (basvuru_formu) hata vermeli."""
        setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            doc_type="basvuru_formu",  
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # status='failed' update'i olmalı
        update_calls = [
            call for call in mock_supabase.table.return_value.update.call_args_list
            if call[0][0].get("status") == "failed"
        ]
        assert len(update_calls) > 0

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_pdf_download_fails(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """PDF indirilemezse failed olmalı."""
        setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
        )
        # PDF download None döner
        mock_admin.storage.from_.return_value.download.return_value = None

        await run_analysis_pipeline("analysis-1", "doc-123")

        update_calls = [
            call for call in mock_supabase.table.return_value.update.call_args_list
            if call[0][0].get("status") == "failed"
        ]
        assert len(update_calls) > 0

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_text_too_short_fails(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Çıkan metin 50 karakterden azsa failed olmalı."""
        setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            extracted_text="kısa",  
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        update_calls = [
            call for call in mock_supabase.table.return_value.update.call_args_list
            if call[0][0].get("status") == "failed"
        ]
        assert len(update_calls) > 0


# ============================================================
# 3. Pipeline - Full Happy Path (LOW Risk)
# ============================================================

class TestPipelineLowRisk:
    """Düşük risk pipeline akışı (Gemini explanation ÇAĞRILMAZ)."""

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_low_risk_completes_without_explanation(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Düşük risk: summary üretilir, explanation ÇAĞRILMAZ (cost-aware)."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            top_match={"document_id": "doc-other", "similarity": 0.445},
            risk_level="low",
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # Summary çağrılmış olmalı
        mocks["llm"].summarize.assert_called_once()
        mocks["llm"].explain_similarity.assert_not_called()

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_pipeline_completes_status_set(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Başarılı pipeline status='completed' yapmalı."""
        setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            risk_level="low",
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # Completed update'i var mı?
        completed_calls = [
            call for call in mock_supabase.table.return_value.update.call_args_list
            if call[0][0].get("status") == "completed"
        ]
        assert len(completed_calls) > 0


# ============================================================
# 4. Pipeline - HIGH Risk (Gemini Explanation ÇAĞRILIR)
# ============================================================

class TestPipelineHighRisk:
    """Yüksek risk pipeline akışı (Gemini explanation ÇAĞRILIR)."""

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_high_risk_triggers_explanation(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """HIGH risk: hem summary hem explanation çağrılmalı."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            top_match={"document_id": "doc-other", "similarity": 0.95},
            risk_level="high",
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # Summary çağrıldı
        mocks["llm"].summarize.assert_called_once()
        # Explanation çağrıldı 
        mocks["llm"].explain_similarity.assert_called_once()

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_high_risk_no_match_no_explanation(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """HIGH risk ama benzer belge yoksa explanation çağrılmamalı."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            top_match=None,  
            risk_level="high",
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # similar_document_id None olduğu için explanation çağrılmaz
        mocks["llm"].explain_similarity.assert_not_called()


# ============================================================
# 5. Pipeline - Service Çağrı Sırası
# ============================================================

class TestPipelineServiceCalls:
    """Pipeline'ın doğru servisleri doğru sırayla çağırdığını doğrular."""

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_all_services_called_in_pipeline(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Tüm AI servisleri pipeline'da çağrılmalı."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # Tüm servisler çağrıldı mı?
        mocks["extractor"].extract.assert_called_once()
        mocks["masker"].mask.assert_called_once()
        mocks["embedder"].generate_embedding.assert_called_once()
        mocks["engine"].get_top_match.assert_called_once()
        mocks["engine"].calculate_risk_level.assert_called_once()
        mocks["llm"].summarize.assert_called_once()

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_pdf_downloaded_from_storage(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """PDF storage'dan indirilmeli."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # Storage download çağrıldı mı?
        mocks["storage"].download.assert_called_once_with("path/to/file.pdf")

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_masked_text_used_for_embedding(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Embedding maskelenmiş metin üzerinden üretilmeli (privacy)."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
        )

        await run_analysis_pipeline("analysis-1", "doc-123")

        # generate_embedding "Maskelenmiş metin" ile çağrıldı mı?
        embed_call = mocks["embedder"].generate_embedding.call_args
        assert embed_call[0][0] == "Maskelenmiş metin"


# ============================================================
# 6. Real World Scenarios
# ============================================================

class TestRealWorldScenarios:
    """Demo senaryoları (Miray-Ahmet, Leyla, Meryem)."""

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_ahmet_miray_high_risk_full_flow(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Ahmet-Miray %97 senaryosu: HIGH risk, explanation üretilir."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            top_match={"document_id": "miray-doc", "similarity": 0.97},
            risk_level="high",
        )

        await run_analysis_pipeline("analysis-ahmet", "ahmet-doc")

        mocks["llm"].summarize.assert_called_once()
        mocks["llm"].explain_similarity.assert_called_once()

    @pytest.mark.asyncio
    @patch("app.services.ai_orchestrator.get_llm_service")
    @patch("app.services.ai_orchestrator.get_similarity_engine")
    @patch("app.services.ai_orchestrator.get_embedder")
    @patch("app.services.ai_orchestrator.get_pii_masker")
    @patch("app.services.ai_orchestrator.get_text_extractor")
    @patch("app.services.ai_orchestrator.supabase_admin")
    @patch("app.services.ai_orchestrator.supabase")
    async def test_meryem_clean_diary_low_risk(
        self, mock_supabase, mock_admin, mock_ext, mock_pii,
        mock_embed, mock_engine, mock_llm
    ):
        """Meryem temiz defter senaryosu: LOW risk, sadece summary."""
        mocks = setup_full_pipeline_mocks(
            mock_supabase, mock_admin, mock_ext, mock_pii,
            mock_embed, mock_engine, mock_llm,
            top_match={"document_id": "other", "similarity": 0.445},
            risk_level="low",
        )

        await run_analysis_pipeline("analysis-meryem", "meryem-doc")

        # Sadece summary çağrıldı 
        mocks["llm"].summarize.assert_called_once()
        mocks["llm"].explain_similarity.assert_not_called()
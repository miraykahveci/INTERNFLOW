"""
Analysis API Endpoint Birim Testleri
=====================================
FastAPI router endpoint'lerini TestClient ile test eder.
Supabase ve BackgroundTask MOCK'lanır.
"""

import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# 1. Health Check Endpoint
# ============================================================

class TestAnalysisHealth:
    """GET /api/v1/analysis/health endpoint testleri."""

    def test_health_returns_200(self):
        """Health endpoint 200 dönmeli."""
        response = client.get("/api/v1/analysis/health")
        assert response.status_code == 200

    def test_health_returns_ok_status(self):
        """Health response status 'ok' olmalı."""
        response = client.get("/api/v1/analysis/health")
        assert response.json()["status"] == "ok"

    def test_health_returns_module_name(self):
        """Health response module='analysis' olmalı."""
        response = client.get("/api/v1/analysis/health")
        assert response.json()["module"] == "analysis"


# ============================================================
# 2. POST /ai/analyze/{document_id} — Start Analysis
# ============================================================

class TestStartAnalysis:
    """POST /api/v1/ai/analyze/{document_id} endpoint testleri."""

    @patch("app.api.analysis.run_analysis_pipeline")
    @patch("app.api.analysis.supabase")
    def test_start_analysis_returns_processing(self, mock_supabase, mock_pipeline):

        doc_response = MagicMock()
        doc_response.data = {"document_id": "doc-123", "doc_type": "staj_defteri"}

        # Insert response mock
        insert_response = MagicMock()
        insert_response.data = [{"analysis_id": "analysis-789"}]

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = doc_response
        table_mock.insert.return_value.execute.return_value = insert_response
        mock_supabase.table.return_value = table_mock

        # ACT
        response = client.post("/api/v1/ai/analyze/doc-123")

        # ASSERT
        assert response.status_code == 200
        data = response.json()
        assert data["analysis_id"] == "analysis-789"
        assert data["status"] == "processing"

    @patch("app.api.analysis.supabase")
    def test_start_analysis_document_not_found(self, mock_supabase):
        """Belge yoksa 404 dönmeli."""
        doc_response = MagicMock()
        doc_response.data = None

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = doc_response
        mock_supabase.table.return_value = table_mock

        response = client.post("/api/v1/ai/analyze/nonexistent-doc")

        assert response.status_code == 404
        assert "bulunamadı" in response.json()["detail"].lower()

    @patch("app.api.analysis.supabase")
    def test_start_analysis_wrong_doc_type(self, mock_supabase):
        """Staj defteri değilse 400 dönmeli."""
        doc_response = MagicMock()
        doc_response.data = {
            "document_id": "doc-123",
            "doc_type": "basvuru_formu",  # Yanlış tip
        }

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = doc_response
        mock_supabase.table.return_value = table_mock

        response = client.post("/api/v1/ai/analyze/doc-123")

        assert response.status_code == 400
        assert "staj defteri" in response.json()["detail"].lower()


# ============================================================
# 3. GET /ai/analysis/{id}/status — Get Status
# ============================================================

class TestGetAnalysisStatus:
    """GET /api/v1/ai/analysis/{analysis_id}/status endpoint testleri."""

    @patch("app.api.analysis.supabase")
    def test_get_status_returns_data(self, mock_supabase):
        """Geçerli analysis_id için status dönmeli."""
        status_response = MagicMock()
        status_response.data = {
            "analysis_id": "analysis-789",
            "status": "processing",
            "progress": 60,
            "current_step": "Embedding üretiliyor",
            "error_message": None,
        }

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = status_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/analysis-789/status")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "processing"
        assert data["progress"] == 60

    @patch("app.api.analysis.supabase")
    def test_get_status_not_found(self, mock_supabase):
        """Analiz yoksa 404 dönmeli."""
        status_response = MagicMock()
        status_response.data = None

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.single.return_value.execute.return_value = status_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/nonexistent/status")

        assert response.status_code == 404


# ============================================================
# 4. GET /ai/analysis/document/{document_id} — Get Result
# ============================================================

class TestGetAnalysisResult:
    """GET /api/v1/ai/analysis/document/{document_id} endpoint testleri."""

    @patch("app.api.analysis.supabase")
    def test_get_result_returns_completed_analysis(self, mock_supabase):
        """Tamamlanmış analiz için sonuç dönmeli."""
        result_response = MagicMock()
        result_response.data = [{
            "analysis_id": "analysis-789",
            "document_id": "doc-123",
            "similar_document_id": None,  
            "status": "completed",
            "progress": 100,
            "plagiarism_score": 0.445,
            "risk_level": "low",
            "is_risky": False,
            "ai_summary": "Meryem'in defteri tertemiz.",
            "plagiarism_explanation": None,
            "masked_text": "Maskelenmiş metin",
            "completed_at": "2026-01-31T10:00:00Z",
        }]

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = result_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/document/doc-123")

        assert response.status_code == 200
        data = response.json()
        assert data["risk_level"] == "low"
        assert data["plagiarism_score"] == 0.445

    @patch("app.api.analysis.supabase")
    def test_get_result_not_found(self, mock_supabase):
        """Analiz yoksa 404 dönmeli."""
        result_response = MagicMock()
        result_response.data = []  # Boş

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = result_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/document/doc-unknown")

        assert response.status_code == 404

    @patch("app.api.analysis.supabase")
    def test_get_result_enriches_similar_student_data(self, mock_supabase):
        """Benzer belge varsa öğrenci bilgileri eklenmelidir."""
        
        result_response = MagicMock()
        result_response.data = [{
            "analysis_id": "analysis-789",
            "document_id": "doc-ahmet",
            "similar_document_id": "doc-miray",
            "status": "completed",
            "progress": 100,
            "plagiarism_score": 0.97,
            "risk_level": "high",
            "is_risky": True,
            "ai_summary": "Özet",
            "plagiarism_explanation": "Açıklama",
            "masked_text": "metin",
            "completed_at": "2026-01-31T10:00:00Z",
        }]

        similar_response = MagicMock()
        similar_response.data = [{
            "intern_id": "intern-1",
            "internship": {
                "company_name": "TechCorp",
                "users": {
                    "full_name": "Miray Kahveci",
                    "student_number": "231201047",
                }
            }
        }]

    
        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = result_response
        table_mock.select.return_value.eq.return_value.limit.return_value.execute.return_value = similar_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/document/doc-ahmet")

        assert response.status_code == 200


# ============================================================
# 5. GET /ai/analyses — List All Analyses
# ============================================================

class TestListAnalyses:
    """GET /api/v1/ai/analyses endpoint testleri."""

    @patch("app.api.analysis.supabase")
    def test_list_returns_all_analyses(self, mock_supabase):
        """Tüm analizler liste olarak dönmeli."""
        list_response = MagicMock()
        list_response.data = [
            {"analysis_id": "a-1", "status": "completed", "risk_level": "high"},
            {"analysis_id": "a-2", "status": "completed", "risk_level": "low"},
            {"analysis_id": "a-3", "status": "processing", "risk_level": None},
        ]

        table_mock = MagicMock()
        table_mock.select.return_value.order.return_value.execute.return_value = list_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses")

        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 3
        assert len(data["analyses"]) == 3

    @patch("app.api.analysis.supabase")
    def test_list_returns_empty_when_no_analyses(self, mock_supabase):
        """Hiç analiz yoksa boş liste dönmeli."""
        list_response = MagicMock()
        list_response.data = []

        table_mock = MagicMock()
        table_mock.select.return_value.order.return_value.execute.return_value = list_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses")

        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0
        assert data["analyses"] == []


# ============================================================
# 6. GET /ai/analyses/pending — Pending Documents
# ============================================================

class TestListPendingDocuments:
    """GET /api/v1/ai/analyses/pending endpoint testleri."""

    @patch("app.api.analysis.supabase")
    def test_pending_returns_only_unanalyzed_docs(self, mock_supabase):
        """Henüz analiz edilmemiş defterler dönmeli."""
        # Belgeler
        documents_response = MagicMock()
        documents_response.data = [
            {
                "document_id": "doc-1",
                "file_url": "path1.pdf",
                "uploaded_at": "2026-01-01",
                "internship": {
                    "intern_id": "intern-1",
                    "student_id": "student-1",
                    "company_name": "TechCorp",
                    "users": {
                        "full_name": "Ali Veli",
                        "student_number": "111111",
                    }
                }
            },
            {
                "document_id": "doc-2",
                "file_url": "path2.pdf",
                "uploaded_at": "2026-01-02",
                "internship": {
                    "intern_id": "intern-2",
                    "student_id": "student-2",
                    "company_name": "InnoCorp",
                    "users": {
                        "full_name": "Ayşe Kaya",
                        "student_number": "222222",
                    }
                }
            },
        ]

        # Analiz edilmiş doc'lar
        existing_response = MagicMock()
        existing_response.data = [{"document_id": "doc-1"}]  # doc-1 analiz edildi

        table_mock = MagicMock()
        # documents query
        table_mock.select.return_value.eq.return_value.eq.return_value.execute.return_value = documents_response
        # analysis_result query
        table_mock.select.return_value.in_.return_value.execute.return_value = existing_response

        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses/pending?academician_id=acad-123")

        assert response.status_code == 200
        data = response.json()
        # doc-1 analiz edildi, doc-2 pending olmalı
        assert data["count"] == 1
        assert data["pending"][0]["document_id"] == "doc-2"

    @patch("app.api.analysis.supabase")
    def test_pending_returns_empty_when_no_documents(self, mock_supabase):
        """Hiç belge yoksa boş liste dönmeli."""
        documents_response = MagicMock()
        documents_response.data = []

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.eq.return_value.execute.return_value = documents_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses/pending?academician_id=acad-123")

        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0


# ============================================================
# 7. GET /ai/analyses/completed — Completed Analyses
# ============================================================

class TestListCompletedAnalyses:
    """GET /api/v1/ai/analyses/completed endpoint testleri."""

    @patch("app.api.analysis.supabase")
    def test_completed_returns_only_finished_analyses(self, mock_supabase):
        """Sadece tamamlanmış analizler dönmeli."""
        # Belgeler
        documents_response = MagicMock()
        documents_response.data = [
            {
                "document_id": "doc-1",
                "internship": {
                    "student_id": "s-1",
                    "academician_id": "acad-123",
                    "company_name": "TechCorp",
                    "users": {
                        "full_name": "Ali Veli",
                        "student_number": "111",
                    }
                }
            }
        ]

        # Tamamlanmış analizler
        analyses_response = MagicMock()
        analyses_response.data = [
            {
                "analysis_id": "a-1",
                "document_id": "doc-1",
                "risk_level": "high",
                "plagiarism_score": 0.95,
                "is_risky": True,
                "completed_at": "2026-01-31",
            }
        ]

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.eq.return_value.execute.return_value = documents_response
        table_mock.select.return_value.in_.return_value.eq.return_value.order.return_value.execute.return_value = analyses_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses/completed?academician_id=acad-123")

        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 1
        assert data["completed"][0]["risk_level"] == "high"

    @patch("app.api.analysis.supabase")
    def test_completed_returns_empty_when_no_documents(self, mock_supabase):
        """Hiç belge yoksa boş liste dönmeli."""
        documents_response = MagicMock()
        documents_response.data = []

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.eq.return_value.execute.return_value = documents_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analyses/completed?academician_id=acad-123")

        assert response.status_code == 200
        assert response.json()["count"] == 0


# ============================================================
# 8. Real World Demo Scenarios
# ============================================================

class TestRealWorldDemoScenarios:
    """Demo senaryoları: Miray-Ahmet, Leyla, Meryem."""

    @patch("app.api.analysis.supabase")
    def test_meryem_low_risk_result_endpoint(self, mock_supabase):
        """Meryem temiz defter analiz sonucu doğru dönmeli."""
        result_response = MagicMock()
        result_response.data = [{
            "analysis_id": "a-meryem",
            "document_id": "doc-meryem",
            "similar_document_id": None,
            "status": "completed",
            "progress": 100,
            "plagiarism_score": 0.445,
            "risk_level": "low",
            "is_risky": False,
            "ai_summary": "Veri analizi stajı...",
            "plagiarism_explanation": None,  
            "masked_text": "metin",
            "completed_at": "2026-01-31T10:00:00Z",
        }]

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = result_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/document/doc-meryem")

        assert response.status_code == 200
        data = response.json()
        assert data["risk_level"] == "low"
        assert data["plagiarism_explanation"] is None  # Cost-aware!

    @patch("app.api.analysis.supabase")
    def test_ahmet_high_risk_with_explanation(self, mock_supabase):
        """Ahmet HIGH risk sonucunda explanation dönmeli."""
        result_response = MagicMock()
        result_response.data = [{
            "analysis_id": "a-ahmet",
            "document_id": "doc-ahmet",
            "similar_document_id": "doc-miray",
            "status": "completed",
            "progress": 100,
            "plagiarism_score": 0.97,
            "risk_level": "high",
            "is_risky": True,
            "ai_summary": "Yazılım stajı özeti...",
            "plagiarism_explanation": "İntihal şüphesi yüksek.",
            "masked_text": "metin",
            "completed_at": "2026-01-31T10:00:00Z",
        }]

        similar_response = MagicMock()
        similar_response.data = [{
            "intern_id": "intern-miray",
            "internship": {
                "company_name": "MetaCorp",
                "users": {
                    "full_name": "Miray Kahveci",
                    "student_number": "231201047",
                }
            }
        }]

        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = result_response
        table_mock.select.return_value.eq.return_value.limit.return_value.execute.return_value = similar_response
        mock_supabase.table.return_value = table_mock

        response = client.get("/api/v1/ai/analysis/document/doc-ahmet")

        assert response.status_code == 200
        data = response.json()
        assert data["risk_level"] == "high"
        assert data["plagiarism_explanation"] is not None  # HIGH risk → açıklama VAR
"""
InternFlow Backend - Sistem Testleri (E2E)
============================================
Uçtan uca sistem test senaryoları.
Gerçek kullanıcı akışlarını simüle eder.
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# Senaryo 1: Sistem Sağlık Doğrulama (Smoke Test)
# ============================================================

class TestSystemSmokeScenario:
    """
    Senaryo: Sistem ayağa kalktığında tüm endpoint'ler erişilebilir mi?

    Giriş:           Sistem yeni başlatıldı
    Beklenen Sonuç:  Tüm temel endpoint'ler 200 döner
    """

    def test_system_smoke_all_endpoints_alive(self):
        """E2E: Sistem ayakta tüm endpoint'lere erişilebilir."""
        # 1. Ana sistem
        assert client.get("/health").status_code == 200

        # 2. Analysis modülü
        assert client.get("/api/v1/analysis/health").status_code == 200

        # 3. Applications modülü
        assert client.get("/api/v1/applications").status_code == 200


# ============================================================
# Senaryo 2: Başvuru Listeleme E2E Akışı
# ============================================================

class TestApplicationListingScenario:
    """
    Senaryo: Kullanıcı başvuruları görüntülemek istediğinde sistem doğru yanıt verir.

    Giriş:           GET /api/v1/applications
    Beklenen Sonuç:  HTTP 200 + JSON formatında applications listesi
    """

    def test_e2e_application_listing_returns_proper_format(self):
        """E2E: Başvuru listeleme akışı doğru JSON formatı dönmeli."""
        response = client.get("/api/v1/applications")

        # 1. HTTP status kontrolü
        assert response.status_code == 200

        # 2. JSON format kontrolü
        assert response.headers["content-type"] == "application/json"

        # 3. Data structure kontrolü
        data = response.json()
        assert "applications" in data
        assert isinstance(data["applications"], list)


# ============================================================
# Senaryo 3: AI Analiz Modülü Erişilebilirlik E2E
# ============================================================

class TestAIAnalysisAccessScenario:
    """
    Senaryo: AI Analiz modülü çalışır durumda ve erişilebilir.

    Giriş:           GET /api/v1/analysis/health
    Beklenen Sonuç:  Modül adı 'analysis' ve durum 'ok'
    """

    def test_e2e_ai_analysis_module_operational(self):
        """E2E: AI Analiz modülü ayakta ve doğru cevap veriyor."""
        response = client.get("/api/v1/analysis/health")

        # 1. Modül erişilebilir
        assert response.status_code == 200

        # 2. Yanıt formatı doğru
        data = response.json()
        assert data["module"] == "analysis"
        assert data["status"] == "ok"


# ============================================================
# Senaryo 4: 404 Hata Yönetimi E2E
# ============================================================

class TestErrorHandlingScenario:
    """
    Senaryo: Geçersiz endpoint çağrıldığında sistem düzgün hata döner.

    Giriş:           GET /api/v1/nonexistent
    Beklenen Sonuç:  HTTP 404 + uygun hata mesajı
    """

    def test_e2e_invalid_endpoint_returns_404(self):
        """E2E: Geçersiz endpoint 404 ile düzgün şekilde reddedilmeli."""
        response = client.get("/api/v1/nonexistent")

        # 1. HTTP 404 dönmeli
        assert response.status_code == 404

        # 2. JSON formatında hata mesajı dönmeli
        data = response.json()
        assert "detail" in data


# ============================================================
# Senaryo 5: Tam Sistem Workflow E2E
# ============================================================

class TestCompleteSystemWorkflowScenario:
    """
    Senaryo: Kullanıcı sistemi adım adım kontrol eder.

    Giriş:           Sırayla health → analysis → applications
    Beklenen Sonuç:  Her adımda doğru yanıt + sistem tutarlı çalışır
    """

    def test_e2e_complete_user_workflow(self):
        """E2E: Tipik kullanıcı workflow'u baştan sona sorunsuz."""
        # ADIM 1: Sistem genel sağlık kontrolü
        health_response = client.get("/health")
        assert health_response.status_code == 200
        assert health_response.json()["status"] == "ok"

        # ADIM 2: AI modül erişilebilirlik kontrolü
        analysis_response = client.get("/api/v1/analysis/health")
        assert analysis_response.status_code == 200

        # ADIM 3: Başvuru sayfası erişimi
        applications_response = client.get("/api/v1/applications")
        assert applications_response.status_code == 200

        # ADIM 4: Geçersiz endpoint koruması
        invalid_response = client.get("/api/v1/invalid")
        assert invalid_response.status_code == 404

        # Tüm adımlar başarılı = sistem stabil
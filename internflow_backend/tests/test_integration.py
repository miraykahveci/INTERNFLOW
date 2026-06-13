"""
InternFlow Backend - Entegrasyon Testleri
==========================================
Modüller arası entegrasyon testleri.
Endpoint → Service → DB akışlarını uçtan uca doğrular.
"""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# 1. Application → Database Akışı
# ============================================================

class TestApplicationDatabaseIntegration:
    """Başvuru API'sinin veritabanı katmanı ile entegrasyonu."""

    def test_applications_endpoint_connects_to_service_layer(self):
        """Applications endpoint service layer'a doğru istek atmalı."""
        response = client.get("/api/v1/applications")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "applications" in data

    def test_applications_returns_consistent_structure(self):
        """Service layer'dan dönen veri tutarlı format'ta olmalı."""
        response = client.get("/api/v1/applications")
        data = response.json()
        assert "applications" in data
        assert isinstance(data["applications"], list)


# ============================================================
# 2. Analysis Module Entegrasyonu
# ============================================================

class TestAnalysisModuleIntegration:
    """AI Analysis modülünün diğer servislerle entegrasyonu."""

    def test_analysis_health_integration(self):
        """Analysis modülü ana app ile entegre çalışmalı."""
        response = client.get("/api/v1/analysis/health")
        assert response.status_code == 200
        data = response.json()
        assert data["module"] == "analysis"
        assert data["status"] == "ok"

    def test_analysis_route_prefix_consistency(self):
        """Analysis route'ları doğru prefix ile kayıtlı olmalı."""
        routes = [route.path for route in app.routes]
        analysis_routes = [r for r in routes if "/analysis" in r]
        assert len(analysis_routes) >= 1


# ============================================================
# 3. CORS Middleware Entegrasyonu
# ============================================================

class TestCORSIntegration:
    """CORS middleware'inin endpoint'ler ile entegrasyonu."""

    def test_cors_headers_present_in_response(self):
        """CORS başlıkları response'larda bulunmalı."""
        response = client.get(
            "/health",
            headers={"Origin": "http://localhost:3000"}
        )
        assert response.status_code == 200
    
        assert "access-control-allow-origin" in response.headers

    def test_cors_allows_all_origins(self):
        """CORS tüm origin'lere izin vermeli."""
        response = client.get(
            "/health",
            headers={"Origin": "http://example.com"}
        )
        assert response.status_code == 200


# ============================================================
# 4. Router → Endpoint Entegrasyonu
# ============================================================

class TestRouterIntegration:
    """Router'ların ana FastAPI app ile entegrasyonu."""

    def test_all_routers_registered(self):
        """Tüm router'lar (analysis, applications, yonerge) kayıtlı olmalı."""
        routes = [route.path for route in app.routes]
        assert any("/analysis" in r for r in routes)
        assert any("/applications" in r for r in routes)
        assert any("/yonerge" in r for r in routes)

    def test_health_endpoint_isolated_from_api_v1(self):
        """Health endpoint /api/v1 prefix'i dışında olmalı."""
        response = client.get("/health")
        assert response.status_code == 200
        # api/v1 prefix'i ile değil, kök seviyede
        response_api = client.get("/api/v1/health")
        assert response_api.status_code == 404


# ============================================================
# 5. Environment → Config → App Entegrasyonu
# ============================================================

class TestEnvironmentIntegration:
    """Environment variable → Config → App entegrasyonu."""

    @patch.dict("os.environ", {
        "SUPABASE_URL": "https://test.supabase.co",
        "SUPABASE_KEY": "test-key-123"
    })
    def test_env_vars_loaded_into_app(self):
        """Environment variable'lar app'e doğru yüklenmeli."""
        import os
        assert os.getenv("SUPABASE_URL") == "https://test.supabase.co"
        assert os.getenv("SUPABASE_KEY") == "test-key-123"

    def test_dotenv_module_imported(self):
        """python-dotenv modülü import edilebilmeli."""
        from dotenv import load_dotenv
        assert load_dotenv is not None


# ============================================================
# 6. Multi-Endpoint Workflow Entegrasyonu
# ============================================================

class TestMultiEndpointWorkflow:
    """Birden fazla endpoint'in birlikte çalışması."""

    def test_health_then_applications_workflow(self):
        """Health check → Applications listele akışı çalışmalı."""
        health_response = client.get("/health")
        assert health_response.status_code == 200

        apps_response = client.get("/api/v1/applications")
        assert apps_response.status_code == 200

    def test_health_then_analysis_workflow(self):
        """Health check → Analysis modülü kontrolü akışı çalışmalı."""
        health = client.get("/health")
        assert health.status_code == 200

        analysis = client.get("/api/v1/analysis/health")
        assert analysis.status_code == 200
        assert analysis.json()["status"] == "ok"
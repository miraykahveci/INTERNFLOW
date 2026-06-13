"""
Yönerge API Endpoint Birim Testleri
====================================
Yönerge bilgi alma ve PDF indirme endpoint'lerini test eder.
yonerge_service mock'lanır - external proxy çağrısı YOK.
"""

import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# 1. GET /yonerge/info — Yönerge Bilgisi
# ============================================================

class TestYonergeInfo:
    """GET /api/v1/yonerge/info endpoint testleri."""

    @patch("app.api.yonerge.get_yonerge_info", new_callable=AsyncMock)
    def test_info_returns_200_on_success(self, mock_get_info):
        """Başarılı yönerge bilgisi 200 dönmeli."""
        mock_get_info.return_value = {
            "success": True,
            "filename": "staj_yonergesi.pdf",
            "size": 245760,
            "last_modified": "2026-01-15T10:00:00Z",
        }

        response = client.get("/api/v1/yonerge/info")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["filename"] == "staj_yonergesi.pdf"

    @patch("app.api.yonerge.get_yonerge_info", new_callable=AsyncMock)
    def test_info_returns_503_when_service_fails(self, mock_get_info):
        """Service success=False dönerse 503 dönmeli."""
        mock_get_info.return_value = {
            "success": False,
            "error": "Yönerge sunucusuna ulaşılamıyor",
        }

        response = client.get("/api/v1/yonerge/info")

        assert response.status_code == 503
        assert "ulaşılamıyor" in response.json()["detail"]

    @patch("app.api.yonerge.get_yonerge_info", new_callable=AsyncMock)
    def test_info_returns_default_error_message(self, mock_get_info):
        """Service error mesajı yoksa default mesaj dönmeli."""
        mock_get_info.return_value = {"success": False}  # error key yok

        response = client.get("/api/v1/yonerge/info")

        assert response.status_code == 503
        assert "Yönerge bilgisi alınamadı" in response.json()["detail"]

    @patch("app.api.yonerge.get_yonerge_info", new_callable=AsyncMock)
    def test_info_returns_500_on_exception(self, mock_get_info):
        """Beklenmeyen exception 500 dönmeli."""
        mock_get_info.side_effect = Exception("Beklenmeyen hata")

        response = client.get("/api/v1/yonerge/info")

        assert response.status_code == 500
        assert "Sunucu hatası" in response.json()["detail"]

    @patch("app.api.yonerge.get_yonerge_info", new_callable=AsyncMock)
    def test_info_calls_service_function(self, mock_get_info):
        """Service function çağrılmalı."""
        mock_get_info.return_value = {"success": True}

        client.get("/api/v1/yonerge/info")

        mock_get_info.assert_called_once()


# ============================================================
# 2. GET /yonerge/download — PDF İndirme
# ============================================================

class TestYonergeDownload:
    """GET /api/v1/yonerge/download endpoint testleri."""

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_returns_pdf_stream(self, mock_download):
        """Başarılı indirme PDF stream dönmeli."""
        # Fake PDF bytes
        fake_pdf = b"%PDF-1.4 fake yonerge content"
        mock_download.return_value = fake_pdf

        response = client.get("/api/v1/yonerge/download")

        assert response.status_code == 200
        assert response.content == fake_pdf

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_returns_pdf_media_type(self, mock_download):
        """Content-Type 'application/pdf' olmalı."""
        mock_download.return_value = b"%PDF-1.4 fake"

        response = client.get("/api/v1/yonerge/download")

        assert response.headers["content-type"] == "application/pdf"

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_includes_content_disposition(self, mock_download):
        """Content-Disposition inline header set edilmeli."""
        mock_download.return_value = b"%PDF-1.4 fake"

        response = client.get("/api/v1/yonerge/download")

        content_disposition = response.headers.get("content-disposition", "")
        assert "inline" in content_disposition
        assert "staj_yonergesi.pdf" in content_disposition

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_includes_cache_control(self, mock_download):
        """Cache-Control header set edilmeli (1 saat)."""
        mock_download.return_value = b"%PDF-1.4 fake"

        response = client.get("/api/v1/yonerge/download")

        cache_control = response.headers.get("cache-control", "")
        assert "public" in cache_control
        assert "max-age=3600" in cache_control

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_returns_404_when_pdf_not_found(self, mock_download):
        """PDF None dönerse 404 dönmeli."""
        mock_download.return_value = None

        response = client.get("/api/v1/yonerge/download")

        assert response.status_code == 404
        assert "bulunamadı" in response.json()["detail"]

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_returns_404_when_empty_bytes(self, mock_download):
        """PDF boş bytes dönerse 404 dönmeli."""
        mock_download.return_value = b""

        response = client.get("/api/v1/yonerge/download")

        assert response.status_code == 404

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_returns_500_on_exception(self, mock_download):
        """Beklenmeyen exception 500 dönmeli."""
        mock_download.side_effect = Exception("Storage hatası")

        response = client.get("/api/v1/yonerge/download")

        assert response.status_code == 500
        assert "PDF indirme hatası" in response.json()["detail"]

    @patch("app.api.yonerge.download_yonerge_pdf", new_callable=AsyncMock)
    def test_download_calls_service_function(self, mock_download):
        """Service function çağrılmalı."""
        mock_download.return_value = b"%PDF-1.4 fake"

        client.get("/api/v1/yonerge/download")

        mock_download.assert_called_once()


# ============================================================
# 3. Router Configuration
# ============================================================

class TestYonergeRouter:
    """Yönerge router konfigürasyon testleri."""

    def test_yonerge_routes_registered(self):
        """Yönerge route'ları app'e kayıtlı olmalı."""
        routes = [route.path for route in app.routes]
        assert any("/yonerge/info" in r for r in routes)
        assert any("/yonerge/download" in r for r in routes)

    def test_yonerge_info_uses_get_method(self):
        """yonerge/info GET endpoint olmalı."""
        # Routes arasında GET yöntemi olduğunu kontrol et
        for route in app.routes:
            if "/yonerge/info" in route.path:
                assert "GET" in route.methods
                break
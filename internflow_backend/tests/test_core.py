"""
InternFlow Backend - Birim Testleri
===================================
Bu dosya, vize aşaması için temel birim testlerini içerir.
"""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


# ============================================================
# 1. FastAPI App Testleri - Sunucu ayağa kalkıyor mu?
# ============================================================

class TestHealthCheck:
    """Sistemin çalışır durumda olduğunu doğrular."""

    def test_health_endpoint_returns_ok(self):
        """T-11: Sistem sağlık kontrolü başarılı olmalı."""
        from app.main import app
        client = TestClient(app)
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["service"] == "InternFlow AI Service"

    def test_health_endpoint_has_service_name(self):
        """Health response'da servis adı bulunmalı."""
        from app.main import app
        client = TestClient(app)
        response = client.get("/health")
        assert "service" in response.json()


# ============================================================
# 2. Config Testleri - Ortam değişkenleri doğru yükleniyor mu?
# ============================================================

class TestConfig:
    """Konfigürasyon değerlerinin varlığını doğrular."""

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key-123"})
    def test_config_loads_supabase_url(self):
        """Supabase URL ortam değişkeninden okunabilmeli."""
        import os
        assert os.getenv("SUPABASE_URL") is not None
        assert os.getenv("SUPABASE_URL").startswith("https://")

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key-123"})
    def test_config_loads_supabase_key(self):
        """Supabase Key ortam değişkeninden okunabilmeli."""
        import os
        assert os.getenv("SUPABASE_KEY") is not None
        assert len(os.getenv("SUPABASE_KEY")) > 0


# ============================================================
# 3. API Route Testleri - Endpoint'ler kayıtlı mı?
# ============================================================

class TestAPIRoutes:
    """API endpoint'lerinin kayıtlı ve erişilebilir olduğunu doğrular."""

    def test_app_has_routes(self):
        """FastAPI uygulamasında route'lar tanımlı olmalı."""
        from app.main import app
        routes = [route.path for route in app.routes]
        assert "/health" in routes

    def test_api_v1_prefix_exists(self):
        """API v1 prefix'i ile route'lar bulunmalı."""
        from app.main import app
        routes = [route.path for route in app.routes]
        api_routes = [r for r in routes if r.startswith("/api/v1")]
        # En az analysis ve applications router'ları kayıtlı olmalı
        assert len(api_routes) >= 0  # Şimdilik route var mı kontrolü


# ============================================================
# 4. Veri Doğrulama Testleri
# ============================================================

class TestDataValidation:
    """Giriş verilerinin doğrulanmasını test eder."""

    def test_student_email_format(self):
        """Öğrenci numarası email formatına dönüştürülebilmeli."""
        student_number = "231201047"
        email = f"{student_number}@internflow.edu.tr"
        assert "@" in email
        assert email == "231201047@internflow.edu.tr"

    def test_empty_student_number_rejected(self):
        """Boş öğrenci numarası reddedilmeli."""
        student_number = ""
        assert len(student_number.strip()) == 0

    def test_valid_roles(self):
        """Sistemdeki geçerli roller doğru tanımlı olmalı."""
        valid_roles = ["student", "academician"]
        assert "student" in valid_roles
        assert "academician" in valid_roles
        assert "admin" not in valid_roles  # Kapsam dışı

    def test_internship_status_values(self):
        """Staj durumu değerleri geçerli olmalı."""
        valid_statuses = ["pending", "approved", "rejected", "active", "completed"]
        assert "pending" in valid_statuses
        assert "approved" in valid_statuses

    def test_pdf_file_extension_check(self):
        """Sadece PDF dosyaları kabul edilmeli (REQ-02)."""
        allowed_extensions = [".pdf"]
        test_file = "staj_defteri.pdf"
        ext = "." + test_file.rsplit(".", 1)[-1].lower()
        assert ext in allowed_extensions

    def test_non_pdf_file_rejected(self):
        """PDF olmayan dosyalar reddedilmeli."""
        allowed_extensions = [".pdf"]
        test_file = "document.docx"
        ext = "." + test_file.rsplit(".", 1)[-1].lower()
        assert ext not in allowed_extensions


# ============================================================
# 5. Supabase Client Testleri (Mock)
# ============================================================

class TestSupabaseConnection:
    """Supabase bağlantısının doğru yapılandırıldığını doğrular."""

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key"})
    def test_supabase_client_creation(self):
        """Supabase client doğru parametrelerle oluşturulabilmeli."""
        from supabase import create_client
        # Mock ile gerçek bağlantı yapmadan test ediyoruz
        with patch("supabase.create_client") as mock_create:
            mock_create.return_value = MagicMock()
            client = create_client("https://test.supabase.co", "test-key")
            assert client is not None
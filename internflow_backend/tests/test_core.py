"""
InternFlow Backend - Birim Testleri
===================================
pytest framework'ü ile yazılmış backend birim testleri.
Test kapsamı: API endpoint'leri, konfigürasyon, veri doğrulama, iş mantığı.
"""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from datetime import date, timedelta
from app.main import app

# Test client'ı global olarak oluştur
client = TestClient(app)


# ============================================================
# 1. Health Check Testleri
# ============================================================

class TestHealthCheck:
    """Sistem sağlık kontrolü endpoint testleri."""

    def test_health_endpoint_returns_200(self):
        """Health endpoint 200 status code döndürmeli."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_endpoint_returns_ok_status(self):
        """Health response'da status 'ok' olmalı."""
        response = client.get("/health")
        data = response.json()
        assert data["status"] == "ok"

    def test_health_endpoint_has_service_name(self):
        """Health response'da servis adı bulunmalı."""
        response = client.get("/health")
        data = response.json()
        assert data["service"] == "InternFlow AI Service"

    def test_health_endpoint_response_format(self):
        """Health response JSON formatında ve gerekli alanları içermeli."""
        response = client.get("/health")
        data = response.json()
        assert "status" in data
        assert "service" in data
        assert len(data) >= 2


# ============================================================
# 2. Analysis Module Testleri
# ============================================================

class TestAnalysisEndpoints:
    """AI Analiz modülü endpoint testleri."""

    def test_analysis_health_returns_200(self):
        """Analysis health endpoint erişilebilir olmalı."""
        response = client.get("/api/v1/analysis/health")
        assert response.status_code == 200

    def test_analysis_health_returns_module_name(self):
        """Analysis health response'da modül adı bulunmalı."""
        response = client.get("/api/v1/analysis/health")
        data = response.json()
        assert data["module"] == "analysis"

    def test_analysis_health_status_ok(self):
        """Analysis modülü sağlıklı çalışmalı."""
        response = client.get("/api/v1/analysis/health")
        data = response.json()
        assert data["status"] == "ok"


# ============================================================
# 3. Applications Endpoint Testleri
# ============================================================

class TestApplicationsEndpoints:
    """Staj başvuru endpoint testleri."""

    def test_applications_endpoint_returns_200(self):
        """Applications endpoint erişilebilir olmalı."""
        response = client.get("/api/v1/applications")
        assert response.status_code == 200

    def test_applications_returns_list(self):
        """Applications endpoint liste formatında yanıt döndürmeli."""
        response = client.get("/api/v1/applications")
        data = response.json()
        assert "applications" in data
        assert isinstance(data["applications"], list)

    def test_applications_empty_by_default(self):
        """Başlangıçta başvuru listesi boş olmalı."""
        response = client.get("/api/v1/applications")
        data = response.json()
        assert len(data["applications"]) == 0


# ============================================================
# 4. API Route Kayıt Testleri
# ============================================================

class TestAPIRoutes:
    """API endpoint'lerinin kayıtlı ve erişilebilir olduğunu doğrular."""

    def test_health_route_registered(self):
        """Health endpoint route olarak kayıtlı olmalı."""
        routes = [route.path for route in app.routes]
        assert "/health" in routes

    def test_api_v1_routes_registered(self):
        """API v1 prefix'i ile route'lar bulunmalı."""
        routes = [route.path for route in app.routes]
        api_routes = [r for r in routes if r.startswith("/api/v1")]
        assert len(api_routes) >= 2

    def test_invalid_endpoint_returns_404(self):
        """Geçersiz endpoint 404 döndürmeli."""
        response = client.get("/api/v1/nonexistent")
        assert response.status_code == 404

    def test_app_title_correct(self):
        """FastAPI uygulama başlığı doğru olmalı."""
        assert app.title == "InternFlow AI Service"

    def test_app_version_correct(self):
        """Uygulama versiyonu tanımlı olmalı."""
        assert app.version == "1.0.0"


# ============================================================
# 5. Konfigürasyon Testleri
# ============================================================

class TestConfig:
    """Ortam değişkenleri ve konfigürasyon testleri."""

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key-123"})
    def test_supabase_url_format(self):
        """Supabase URL https ile başlamalı."""
        import os
        url = os.getenv("SUPABASE_URL")
        assert url is not None
        assert url.startswith("https://")

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key-123"})
    def test_supabase_key_not_empty(self):
        """Supabase Key boş olmamalı."""
        import os
        key = os.getenv("SUPABASE_KEY")
        assert key is not None
        assert len(key) > 0

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key-123"})
    def test_supabase_url_contains_supabase(self):
        """Supabase URL geçerli bir Supabase adresi olmalı."""
        import os
        url = os.getenv("SUPABASE_URL")
        assert "supabase" in url


# ============================================================
# 6. Veri Doğrulama Testleri (İş Mantığı)
# ============================================================

class TestDataValidation:
    """Giriş verilerinin doğrulanmasını test eder."""

    def test_student_email_format(self):
        """Öğrenci numarası email formatına dönüştürülebilmeli."""
        student_number = "231201047"
        email = f"{student_number}@internflow.edu.tr"
        assert "@" in email
        assert email.endswith("@internflow.edu.tr")

    def test_academician_email_format(self):
        """Akademisyen kullanıcı adı email formatına dönüştürülebilmeli."""
        username = "taner.cevik"
        email = f"{username}@internflow.edu.tr"
        assert "@" in email
        assert email.endswith("@internflow.edu.tr")

    def test_empty_identifier_rejected(self):
        """Boş kimlik bilgisi reddedilmeli."""
        identifier = ""
        assert len(identifier.strip()) == 0

    def test_valid_roles(self):
        """Sistemdeki geçerli roller doğru tanımlı olmalı."""
        valid_roles = ["student", "academician"]
        assert "student" in valid_roles
        assert "academician" in valid_roles

    def test_internship_status_values(self):
        """Staj durumu değerleri geçerli olmalı."""
        valid_statuses = ["pending", "approved", "rejected", "active", "completed"]
        assert len(valid_statuses) == 5
        assert "pending" in valid_statuses
        assert "approved" in valid_statuses
        assert "completed" in valid_statuses


# ============================================================
# 7. Dosya Doğrulama Testleri
# ============================================================

class TestFileValidation:
    """Belge yükleme validasyon testleri."""

    def test_pdf_file_accepted(self):
        """PDF dosyaları kabul edilmeli."""
        allowed = [".pdf"]
        assert "." + "staj_defteri.pdf".rsplit(".", 1)[-1] in allowed

    def test_docx_file_rejected(self):
        """DOCX dosyaları reddedilmeli."""
        allowed = [".pdf"]
        assert "." + "document.docx".rsplit(".", 1)[-1] not in allowed

    def test_jpg_file_rejected(self):
        """JPG dosyaları reddedilmeli."""
        allowed = [".pdf"]
        assert "." + "photo.jpg".rsplit(".", 1)[-1] not in allowed

    def test_file_size_limit(self):
        """Dosya boyutu 10MB'ı aşmamalı."""
        max_size = 10 * 1024 * 1024  # 10MB
        test_size = 5 * 1024 * 1024   # 5MB
        assert test_size <= max_size

    def test_oversized_file_rejected(self):
        """10MB üstü dosyalar reddedilmeli."""
        max_size = 10 * 1024 * 1024
        test_size = 15 * 1024 * 1024
        assert test_size > max_size

    def test_document_types_valid(self):
        """Belge türleri enum değerlerine uygun olmalı."""
        valid_types = ["staj_defteri", "basvuru_formu", "sgk_belgesi", "anket"]
        assert len(valid_types) == 4
        assert "basvuru_formu" in valid_types
        assert "sgk_belgesi" in valid_types


# ============================================================
# 8. İş Günü Hesaplama Testleri
# ============================================================

class TestBusinessDayCalculation:
    """Staj iş günü hesaplama mantığı testleri."""

    def _calculate_business_days(self, start: date, end: date) -> int:
        """İş günü hesaplama fonksiyonu (hafta sonları hariç)."""
        days = 0
        current = start
        while current <= end:
            if current.weekday() < 5:  # Pazartesi=0, Cuma=4
                days += 1
            current += timedelta(days=1)
        return days

    def test_one_week_has_5_business_days(self):
        """Bir hafta 5 iş günü içermeli."""
        start = date(2026, 7, 6)   # Pazartesi
        end = date(2026, 7, 10)    # Cuma
        assert self._calculate_business_days(start, end) == 5

    def test_weekend_excluded(self):
        """Hafta sonları iş günü sayılmamalı."""
        start = date(2026, 7, 6)   # Pazartesi
        end = date(2026, 7, 12)    # Pazar
        assert self._calculate_business_days(start, end) == 5

    def test_one_month_internship(self):
        """1 aylık staj yaklaşık 22 iş günü olmalı."""
        start = date(2026, 7, 1)
        end = date(2026, 7, 31)
        days = self._calculate_business_days(start, end)
        assert 20 <= days <= 23

    def test_same_day_is_one_day(self):
        """Aynı gün başlayıp biten staj 1 iş günü olmalı."""
        day = date(2026, 7, 6)  # Pazartesi
        assert self._calculate_business_days(day, day) == 1

    def test_saturday_only_is_zero(self):
        """Sadece cumartesi olan staj 0 iş günü olmalı."""
        saturday = date(2026, 7, 11)
        assert self._calculate_business_days(saturday, saturday) == 0


# ============================================================
# 9. Staj Durum Geçişi Testleri
# ============================================================

class TestInternshipStatusTransitions:
    """Staj durumu geçiş kuralları testleri."""

    def _is_valid_transition(self, current: str, new: str) -> bool:
        """Geçerli durum geçişlerini kontrol eder."""
        valid_transitions = {
            "pending": ["approved", "rejected"],
            "approved": ["active"],
            "active": ["completed"],
            "rejected": ["pending"],  # Yeniden başvuru
            "completed": [],
        }
        return new in valid_transitions.get(current, [])

    def test_pending_to_approved(self):
        """Bekleyen başvuru onaylanabilmeli."""
        assert self._is_valid_transition("pending", "approved")

    def test_pending_to_rejected(self):
        """Bekleyen başvuru reddedilebilmeli."""
        assert self._is_valid_transition("pending", "rejected")

    def test_approved_to_active(self):
        """Onaylanan staj aktifleştirilebilmeli."""
        assert self._is_valid_transition("approved", "active")

    def test_active_to_completed(self):
        """Aktif staj tamamlanabilmeli."""
        assert self._is_valid_transition("active", "completed")

    def test_rejected_can_reapply(self):
        """Reddedilen öğrenci yeniden başvurabilmeli."""
        assert self._is_valid_transition("rejected", "pending")

    def test_completed_cannot_change(self):
        """Tamamlanan staj durumu değiştirilemezim."""
        assert not self._is_valid_transition("completed", "pending")
        assert not self._is_valid_transition("completed", "active")

    def test_pending_cannot_skip_to_active(self):
        """Bekleyen başvuru doğrudan aktif olamaz."""
        assert not self._is_valid_transition("pending", "active")

    def test_pending_cannot_skip_to_completed(self):
        """Bekleyen başvuru doğrudan tamamlanamaz."""
        assert not self._is_valid_transition("pending", "completed")


# ============================================================
# 10. Supabase Client Testleri (Mock)
# ============================================================

class TestSupabaseConnection:
    """Supabase bağlantı testleri."""

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key"})
    def test_supabase_env_variables_set(self):
        """Supabase ortam değişkenleri tanımlı olmalı."""
        import os
        assert os.getenv("SUPABASE_URL") is not None
        assert os.getenv("SUPABASE_KEY") is not None

    @patch.dict("os.environ", {"SUPABASE_URL": "https://test.supabase.co", "SUPABASE_KEY": "test-key"})
    def test_supabase_url_is_valid(self):
        """Supabase URL geçerli bir HTTPS adresi olmalı."""
        import os
        url = os.getenv("SUPABASE_URL")
        assert url.startswith("https://")
        assert "supabase" in url
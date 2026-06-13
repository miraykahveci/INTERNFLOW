"""
PII Masker Birim Testleri
==========================
PII (Personal Identifiable Information) maskeleme katmanının
pattern matching ve değiştirme mantığını doğrular.

"""

import pytest
from app.ai.pii_masker import PIIMasker, get_pii_masker


# ============================================================
# 1. Email Maskeleme
# ============================================================

class TestEmailMasking:
    """E-posta adresi maskeleme testleri."""

    def setup_method(self):
        """Her test öncesi yeni masker instance'ı oluştur."""
        self.masker = PIIMasker()

    def test_simple_email_masked(self):
        """Basit e-posta adresi maskelenmelidir."""
        text = "İletişim: ahmet@meta.com"
        masked = self.masker.mask(text)
        assert "[MASKED_EMAIL]" in masked
        assert "ahmet@meta.com" not in masked

    def test_corporate_email_masked(self):
        """Kurumsal e-posta maskelenmelidir."""
        text = "Mail: leyla.kara@garantibbva.com.tr"
        masked = self.masker.mask(text)
        assert "[MASKED_EMAIL]" in masked
        assert "leyla.kara" not in masked

    def test_multiple_emails_all_masked(self):
        """Birden fazla e-posta varsa hepsi maskelenmelidir."""
        text = "A: a@x.com B: b@y.com C: c@z.com"
        masked = self.masker.mask(text)
        assert masked.count("[MASKED_EMAIL]") == 3

    def test_no_email_no_mask(self):
        """E-posta yoksa maskeleme yapılmamalı."""
        text = "Bu metin e-posta içermez."
        masked = self.masker.mask(text)
        assert "[MASKED_EMAIL]" not in masked


# ============================================================
# 2. Telefon Maskeleme
# ============================================================

class TestPhoneMasking:
    """Telefon numarası maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_phone_with_country_code(self):
        """+90 ile başlayan telefon maskelenmelidir."""
        text = "Telefonum: +90 532 123 45 67"
        masked = self.masker.mask(text)
        assert "[MASKED_PHONE]" in masked

    def test_phone_starting_with_zero(self):
        """0 ile başlayan telefon maskelenmelidir."""
        text = "Ulaşmak için 0532 123 45 67"
        masked = self.masker.mask(text)
        assert "[MASKED_PHONE]" in masked

    def test_phone_without_spaces(self):
        """Boşluksuz telefon maskelenmelidir."""
        text = "05321234567"
        masked = self.masker.mask(text)
        assert "[MASKED_PHONE]" in masked


# ============================================================
# 3. TC Kimlik Numarası Maskeleme
# ============================================================

class TestTcknMasking:
    """TC Kimlik numarası maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_valid_tckn_masked(self):
        """Geçerli formatlı TC kimlik no maskelenmelidir."""
        text = "TC: 12345678901"
        masked = self.masker.mask(text)
        assert "[MASKED_TCKN]" in masked
        assert "12345678901" not in masked

    def test_short_number_not_masked_as_tckn(self):
        """10 haneli sayı TC sayılmamalıdır."""
        text = "Sayı: 1234567890"
        masked = self.masker.mask(text)
        assert "[MASKED_TCKN]" not in masked


# ============================================================
# 4. Employee ID & Generic ID Maskeleme
# ============================================================

class TestEmployeeIdMasking:
    """Çalışan ID maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_internship_id_masked(self):
        """Stajyer ID formatı maskelenmelidir."""
        text = "Stajyer no: META-INT-2026-441"
        masked = self.masker.mask(text)
        assert "[MASKED_EMPLOYEE_ID]" in masked

    def test_garanti_id_masked(self):
        """GTI-2025-1847 formatı maskelenmelidir."""
        text = "Personel ID: GTI-2025-1847"
        masked = self.masker.mask(text)
        # Bu generic_id pattern'e takılır
        assert "[MASKED" in masked


# ============================================================
# 5. Ticket Maskeleme
# ============================================================

class TestTicketMasking:
    """Jira/Task ticket maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_jira_ticket_masked(self):
        """Jira ticket maskelenmelidir."""
        text = "Görev: JIRA-1234"
        masked = self.masker.mask(text)
        assert "[MASKED_TICKET]" in masked

    def test_task_ticket_masked(self):
        """Task ticket maskelenmelidir."""
        text = "TASK-9912 numaralı iş"
        masked = self.masker.mask(text)
        assert "[MASKED_TICKET]" in masked

    def test_pr_ticket_masked(self):
        """Pull request numarası maskelenmelidir."""
        text = "Bkz: PR-3308"
        masked = self.masker.mask(text)
        assert "[MASKED_TICKET]" in masked


# ============================================================
# 6. IP Adresi Maskeleme
# ============================================================

class TestIpMasking:
    """IP adresi maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_internal_ip_masked(self):
        """Internal IP adresi maskelenmelidir."""
        text = "Sunucu: 10.42.18.27"
        masked = self.masker.mask(text)
        assert "[MASKED_IP]" in masked

    def test_public_ip_masked(self):
        """Public IP adresi maskelenmelidir."""
        text = "IP: 192.168.1.1"
        masked = self.masker.mask(text)
        assert "[MASKED_IP]" in masked


# ============================================================
# 7. URL Maskeleme
# ============================================================

class TestUrlMasking:
    """URL maskeleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_https_url_masked(self):
        """HTTPS URL maskelenmelidir."""
        text = "Site: https://wiki.example.com/page"
        masked = self.masker.mask(text)
        assert "[MASKED_URL]" in masked

    def test_www_url_masked(self):
        """www ile başlayan URL maskelenmelidir."""
        text = "www.example.com adresine bakın"
        masked = self.masker.mask(text)
        assert "[MASKED_URL]" in masked


# ============================================================
# 8. İsim Maskeleme (name_list ile)
# ============================================================

class TestNameMasking:
    """Önceden tanımlı isim listesi ile maskeleme."""

    def test_name_in_list_masked(self):
        """Listedeki isim maskelenmelidir."""
        masker = PIIMasker(name_list=["Ahmet Yılmaz"])
        text = "Bugün Ahmet Yılmaz ile toplantı yaptım."
        masked = masker.mask(text)
        assert "[MASKED_NAME]" in masked
        assert "Ahmet Yılmaz" not in masked

    def test_name_case_insensitive(self):
        """İsim maskelemesi büyük/küçük harf duyarsız olmalı."""
        masker = PIIMasker(name_list=["Ahmet Yılmaz"])
        text = "AHMET YILMAZ konuştu."
        masked = masker.mask(text)
        assert "[MASKED_NAME]" in masked

    def test_empty_name_list_no_mask(self):
        """Boş isim listesi maskeleme yapmamalı."""
        masker = PIIMasker(name_list=[])
        text = "Ahmet ile konuştum."
        masked = masker.mask(text)
        assert "[MASKED_NAME]" not in masked


# ============================================================
# 9. Şablon Temizleme (Üniversite Footer)
# ============================================================

class TestTemplateRemoval:
    """Üniversite şablonu/footer temizleme testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_university_title_removed(self):
        """Üniversite başlığı temizlenmelidir."""
        text = "Bugün İSTANBUL RUMELİ ÜNİVERSİTESİ binasına gittim."
        masked = self.masker.mask(text)
        assert "İSTANBUL RUMELİ ÜNİVERSİTESİ" not in masked

    def test_faculty_removed(self):
        """Fakülte adı temizlenmelidir."""
        text = "MÜHENDİSLİK ve DOĞA BİLİMLERİ FAKÜLTESİ"
        masked = self.masker.mask(text)
        assert "MÜHENDİSLİK" not in masked

    def test_form_header_removed(self):
        """Form başlığı temizlenmelidir."""
        text = "YAPILAN İŞİN ADI / KAPSAMI: Yazılım geliştirme"
        masked = self.masker.mask(text)
        assert "YAPILAN İŞİN ADI" not in masked

    def test_date_pattern_removed(self):
        """TARİH XX/XX/XXXX şablonu temizlenmelidir."""
        text = "TARİH 13 / 08 / 2026 Bugün işlem yaptım."
        masked = self.masker.mask(text)
        assert "TARİH 13" not in masked


# ============================================================
# 10. İstatistik Fonksiyonu
# ============================================================

class TestStatistics:
    """Maskeleme istatistik fonksiyonu testleri."""

    def setup_method(self):
        self.masker = PIIMasker()

    def test_stats_counts_emails(self):
        """İstatistik e-posta sayısını doğru saymalıdır."""
        text = "a@x.com b@y.com c@z.com"
        masked = self.masker.mask(text)
        stats = self.masker.get_stats(text, masked)
        assert stats["email"] == 3

    def test_stats_zero_when_no_pii(self):
        """PII yoksa tüm sayaçlar 0 olmalıdır."""
        text = "Bu metin temizdir."
        masked = self.masker.mask(text)
        stats = self.masker.get_stats(text, masked)
        assert all(v == 0 for v in stats.values())


# ============================================================
# 11. Singleton Pattern
# ============================================================

class TestSingleton:
    """get_pii_masker singleton testleri."""

    def test_singleton_returns_same_instance(self):
        """get_pii_masker aynı instance'ı dönmeli."""
        masker1 = get_pii_masker()
        masker2 = get_pii_masker()
        assert masker1 is masker2


# ============================================================
# 12. Kombine Senaryo - Gerçek Defter Cümleleri
# ============================================================

class TestRealWorldScenarios:
    """Gerçek staj defteri cümleleri ile uçtan uca testler."""

    def setup_method(self):
        self.masker = PIIMasker(name_list=["Burak Şahin", "Funda Köksal"])

    def test_real_diary_entry_masking(self):
        """Tipik bir defter cümlesinde tüm PII'lar maskelenmelidir."""
        text = (
            "Mentorum Burak Şahin ile iletişimimi "
            "ahmet@meta.com üzerinden sağladım. "
            "Sunucu IP'si 10.42.18.27 ve görev JIRA-1234."
        )
        masked = self.masker.mask(text)
        assert "[MASKED_NAME]" in masked
        assert "[MASKED_EMAIL]" in masked
        assert "[MASKED_IP]" in masked
        assert "[MASKED_TICKET]" in masked

    def test_diary_with_template_and_pii(self):
        """Defter şablonu + PII birlikte temizlenmelidir."""
        text = (
            "İSTANBUL RUMELİ ÜNİVERSİTESİ "
            "İletişim: ahmet@meta.com "
            "Telefonum: +90 532 123 45 67"
        )
        masked = self.masker.mask(text)
        assert "İSTANBUL RUMELİ" not in masked
        assert "[MASKED_EMAIL]" in masked
        assert "[MASKED_PHONE]" in masked
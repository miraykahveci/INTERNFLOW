"""
PII Masker - Kişisel Veri Maskeleme (KVKK Uyumluluğu)

Bu modül metindeki kişisel verileri regex ile tespit edip maskeler.
Pipeline'da embedding'den ÖNCE çalışır (Privacy by Design).
Böylece vektör veritabanına yazılan temsiller PII içermez.

Maskelenen veriler:
  - Email          → [MASKED_EMAIL]
  - Telefon        → [MASKED_PHONE]
  - TC Kimlik No   → [MASKED_TCKN]
  - Çalışan/Stajyer ID → [MASKED_EMPLOYEE_ID]
  - URL            → [MASKED_URL]
  - İsim (liste)   → [MASKED_NAME]

Mimari not: Regex tabanlı desen eşleştirme.
İki katman: (1) Net desenli PII (email, telefon vb.) otomatik,
(2) İsimler kontrollü liste ile. Bu, false-positive riskini azaltır.
"""

import re


class PIIMasker:
    

    def __init__(self, name_list: list[str] | None = None):
       
        self.name_list = name_list or []

        
        self.email_pattern = re.compile(
            r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"
        )

        
        self.phone_pattern = re.compile(
            r"(?:\+90|0)?\s*\(?5\d{2}\)?[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}"
        )
        
        self.tckn_pattern = re.compile(r"\b[1-9]\d{10}\b")

        self.employee_id_pattern = re.compile(
            r"\b[A-Z]{2,6}-INT-\d{4}-\d{2,6}\b"
        )
        self.generic_id_pattern = re.compile(
            r"\b[A-Z]{2,5}-\d{4,}(?:-\d+)?\b"
        )

        
        self.url_pattern = re.compile(
            r"(?:https?://|www\.)[^\s]+"
        )
        self.ticket_pattern = re.compile(
            r"\b(?:MEET|JIRA|TASK|TICKET|REF|PR)-\d{3,6}\b"
        )

    
        self.ip_pattern = re.compile(
            r"\b(?:\d{1,3}\.){3}\d{1,3}\b"
        )

    def mask(self, text: str) -> str:
       
        masked = text

        
        masked = self.email_pattern.sub("[MASKED_EMAIL]", masked)

        
        masked = self.url_pattern.sub("[MASKED_URL]", masked)
        
        
        masked = self.ticket_pattern.sub("[MASKED_TICKET]", masked)

       
        masked = self.ip_pattern.sub("[MASKED_IP]", masked)

        
        masked = self.employee_id_pattern.sub("[MASKED_EMPLOYEE_ID]", masked)

       
        masked = self.generic_id_pattern.sub("[MASKED_ID]", masked)

       
        masked = self.tckn_pattern.sub("[MASKED_TCKN]", masked)

       
        masked = self.phone_pattern.sub("[MASKED_PHONE]", masked)

      
        for name in self.name_list:
            if name.strip():
                name_pattern = re.compile(
                    r"\b" + re.escape(name) + r"\b", re.IGNORECASE
                )
                masked = name_pattern.sub("[MASKED_NAME]", masked)

        return masked

    def get_stats(self, original: str, masked: str) -> dict:
        """Kaç maskeleme yapıldığını sayar (demo/debug için)"""
        return {
            "email": masked.count("[MASKED_EMAIL]"),
            "phone": masked.count("[MASKED_PHONE]"),
            "tckn": masked.count("[MASKED_TCKN]"),
            "employee_id": masked.count("[MASKED_EMPLOYEE_ID]"),
            "generic_id": masked.count("[MASKED_ID]"),
            "url": masked.count("[MASKED_URL]"),
            "name": masked.count("[MASKED_NAME]"),
            "ticket": masked.count("[MASKED_TICKET]"),
            "ip": masked.count("[MASKED_IP]"),
        }


# ==========================================================================
# Singleton
# ==========================================================================
_masker_instance: PIIMasker | None = None


def get_pii_masker(name_list: list[str] | None = None) -> PIIMasker:
    """Singleton: tek PIIMasker instance döner"""
    global _masker_instance
    if _masker_instance is None:
        _masker_instance = PIIMasker(name_list=name_list)
    return _masker_instance


# ==========================================================================
# TEST ALANI — python -m app.ai.pii_masker
# ==========================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("PII Masker Test")
    print("=" * 60)

    # Demo isim listesi
    test_names = ["Ahmet Yılmaz", "Mehmet Demir", "Ayşe Kaya"]
    masker = PIIMasker(name_list=test_names)

    test_metni = """Bugün mentorum Ahmet Yılmaz ile toplantı yaptık.
İletişim için mail adresim ahmet.yilmaz@meta.com, telefonum 0532 123 45 67.
Çalışan numaram META-INT-2026-441, kullanıcı ID'm USR-884291.
TC kimlik numaram 12345678901 olarak sisteme kaydedildi.
Detaylar için https://analytics.meta-internal.net adresine bakabilirsiniz.
Ayşe Kaya da projeye katıldı."""

    print("\n--- ORİJİNAL METİN ---")
    print(test_metni)

    masked = masker.mask(test_metni)

    print("\n--- MASKELENMİŞ METİN ---")
    print(masked)

    print("\n--- İSTATİSTİK ---")
    stats = masker.get_stats(test_metni, masked)
    for key, count in stats.items():
        if count > 0:
            print(f"  {key}: {count} adet maskelendi")

    print("\n" + "=" * 60)
    has_email = "@meta.com" in masked
    has_phone = "0532" in masked
    if not has_email and not has_phone:
        print("✅ TEST BAŞARILI! Hassas veriler maskelendi.")
    else:
        print("⚠️ Bazı veriler maskelenemedi, kontrol et.")
    print("=" * 60)
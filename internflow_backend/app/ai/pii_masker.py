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
        
        self.template_patterns = [
            re.compile(r"İSTANBUL\s+RUMELİ\s+ÜNİVERSİTESİ", re.IGNORECASE),
            re.compile(r"MÜHENDİSLİK\s+ve\s+DOĞA\s+BİLİMLERİ\s+FAKÜLTESİ", re.IGNORECASE),
            re.compile(r"BİLGİSAYAR\s+MÜHENDİSLİĞİ\s+BÖLÜMÜ", re.IGNORECASE),
            re.compile(r"İş\s+Yerinde\s+Uygulama.*?Günlüğü", re.IGNORECASE),
            re.compile(r"YAPILAN\s+İŞİN\s+ADI\s*/?\s*KAPSAMI", re.IGNORECASE),
            re.compile(r"ÇALIŞMA\s+GÜNÜ\s*\d+", re.IGNORECASE),
            re.compile(r"TARİH\s*\d{1,2}\s*/\s*\d{1,2}\s*/\s*\d{4}", re.IGNORECASE),
            re.compile(r"Mehmet\s+Balcı\s+Yerleşkesi.*?bilgi@rumeli\.edu\.tr", re.IGNORECASE | re.DOTALL),
            re.compile(r"Staj\s+Yeri\s+Yetkilisinin\s+Adı.*?İmza\s+ve\s+Kaşe", re.IGNORECASE | re.DOTALL),
            re.compile(r"Tarih\s*:\s*$", re.IGNORECASE | re.MULTILINE),
        ]

    def mask(self, text: str) -> str:
       
        masked = text
        
        for pattern in self.template_patterns:
            masked = pattern.sub("", masked)

        masked = re.sub(r"\s+", " ", masked).strip()

        
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
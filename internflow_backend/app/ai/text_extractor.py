"""
Text Extractor - Belgeden metin çıkarma

Bu modül yüklenen belgeden ham metni çıkarır.
Pipeline'ın giriş katmanıdır: PDF/belge → düz metin

Desteklenen formatlar:
  - PDF: pdfplumber ile (saf Python, Türkçe destekli, deploy dostu)
  - Görüntü (PNG/JPG): OCR arayüzü hazır, Tesseract kurulunca aktif

Mimari not: Format-agnostic tasarım.
Yeni format desteği eklemek, mevcut kodu bozmadan mümkün (Open/Closed).
Tesseract kurulu değilse sistem çökmez, açıklayıcı hata verir (graceful degradation).
"""

import io


class TextExtractor:
    """Belgeden metin çıkaran ana sınıf"""

    PDF_TYPES = {"application/pdf"}
    IMAGE_TYPES = {"image/png", "image/jpeg", "image/jpg"}

    def extract(self, file_bytes: bytes, content_type: str) -> str:
        """
        Dosya tipine göre doğru extraction yöntemini seçer.

        Args:
            file_bytes: Dosyanın binary içeriği
            content_type: MIME type (örn: 'application/pdf')

        Returns:
            Çıkarılan düz metin

        Raises:
            ValueError: Desteklenmeyen format veya boş metin
        """
        content_type = (content_type or "").lower().strip()

        if content_type in self.PDF_TYPES:
            return self._extract_from_pdf(file_bytes)
        elif content_type in self.IMAGE_TYPES:
            return self._extract_from_image(file_bytes)
        else:
            raise ValueError(
                f"Desteklenmeyen dosya formatı: '{content_type}'. "
                f"Desteklenen: PDF (application/pdf)"
            )

    def _extract_from_pdf(self, file_bytes: bytes) -> str:
        """
        PDF'den metin çıkarır (pdfplumber ile).

        pdfplumber neden? Saf Python, sistem bağımlılığı yok,
        Türkçe karakterleri (ç,ğ,ı,ö,ş,ü) doğru işler, deploy dostu.
        """
        import pdfplumber

        text_parts = []
        try:
            with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
                for page_num, page in enumerate(pdf.pages, 1):
                    page_text = page.extract_text()
                    if page_text:
                        text_parts.append(page_text)
        except Exception as e:
            raise ValueError(f"PDF okunamadı: {str(e)}") from e

        full_text = "\n".join(text_parts).strip()

        if not full_text:
            raise ValueError(
                "PDF'den metin çıkarılamadı. "
                "Belge taranmış görüntü olabilir (OCR gerekir) veya boş olabilir."
            )

        return full_text

    def _extract_from_image(self, file_bytes: bytes) -> str:
        """
        Görüntüden metin çıkarır (OCR - Tesseract ile).
        Mimari OCR'a hazır; sadece sistem bağımlılığı eklenince aktif olacak.
        """
        try:
            import pytesseract
            from PIL import Image
        except ImportError as e:
            raise ValueError(
                "OCR kütüphaneleri yüklü değil. PDF formatı kullanın."
            ) from e

        try:
            image = Image.open(io.BytesIO(file_bytes))
            text = pytesseract.image_to_string(image, lang="tur")
        except pytesseract.TesseractNotFoundError as e:
            raise ValueError(
                "Tesseract OCR motoru sistemde kurulu değil. "
                "Şu an PDF formatı destekleniyor. "
                "OCR için: 'brew install tesseract tesseract-lang'"
            ) from e
        except Exception as e:
            raise ValueError(f"Görüntü işlenemedi: {str(e)}") from e

        text = text.strip()
        if not text:
            raise ValueError("Görüntüden metin çıkarılamadı.")

        return text


# ==========================================================================
# Singleton — tek instance 
# ==========================================================================
_extractor_instance: TextExtractor | None = None


def get_text_extractor() -> TextExtractor:
    """Singleton: tek TextExtractor instance döner"""
    global _extractor_instance
    if _extractor_instance is None:
        _extractor_instance = TextExtractor()
    return _extractor_instance


# ==========================================================================
# TEST ALANI — python -m app.ai.text_extractor ile çalıştırılır
# ==========================================================================
if __name__ == "__main__":
    import sys

    print("=" * 60)
    print("Text Extractor Test")
    print("=" * 60)

    extractor = get_text_extractor()

    
    if len(sys.argv) > 1:
        pdf_path = sys.argv[1]
        print(f"\nTest edilen dosya: {pdf_path}")
        with open(pdf_path, "rb") as f:
            file_bytes = f.read()
        text = extractor.extract(file_bytes, "application/pdf")
        print(f"\n✓ Çıkarılan metin ({len(text)} karakter, {len(text.split())} kelime):")
        print("-" * 60)
        print(text[:500])
        print("..." if len(text) > 500 else "")
        print("-" * 60)
        print("✅ TEST BAŞARILI!")
    else:
        print("\nKullanım: python -m app.ai.text_extractor <pdf_dosya_yolu>")
        print("Örnek:    python -m app.ai.text_extractor test_defter.pdf")
        print("\nDesteklenen formatlar:")
        print("  ✓ PDF (application/pdf) — aktif")
        print("  ⏸ Görüntü (PNG/JPG) — Tesseract kurulunca aktif")
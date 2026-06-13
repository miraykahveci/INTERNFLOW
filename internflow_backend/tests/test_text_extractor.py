"""
Text Extractor Birim Testleri
==============================
PDF ve görüntü (OCR) metin çıkarma stratejilerini test eder.
pdfplumber, pytesseract, PIL MOCK'lanır.
"""

import pytest
import io
from unittest.mock import patch, MagicMock
from app.ai.text_extractor import TextExtractor, get_text_extractor


# ============================================================
# 1. Content Type Routing
# ============================================================

class TestContentTypeRouting:
    """extract() içerik tipine göre doğru metoda yönlendirir."""

    def setup_method(self):
        self.extractor = TextExtractor()

    @patch.object(TextExtractor, "_extract_from_pdf")
    def test_pdf_content_type_routes_to_pdf_extractor(self, mock_pdf):
        """application/pdf → _extract_from_pdf çağrılmalı."""
        mock_pdf.return_value = "PDF metni"

        result = self.extractor.extract(b"fake bytes", "application/pdf")

        mock_pdf.assert_called_once_with(b"fake bytes")
        assert result == "PDF metni"

    @patch.object(TextExtractor, "_extract_from_image")
    def test_image_png_routes_to_image_extractor(self, mock_img):
        """image/png → _extract_from_image çağrılmalı."""
        mock_img.return_value = "OCR metni"

        result = self.extractor.extract(b"fake bytes", "image/png")

        mock_img.assert_called_once_with(b"fake bytes")
        assert result == "OCR metni"

    @patch.object(TextExtractor, "_extract_from_image")
    def test_image_jpeg_routes_to_image_extractor(self, mock_img):
        """image/jpeg → _extract_from_image çağrılmalı."""
        mock_img.return_value = "OCR metni"
        self.extractor.extract(b"fake", "image/jpeg")
        mock_img.assert_called_once()

    @patch.object(TextExtractor, "_extract_from_image")
    def test_image_jpg_routes_to_image_extractor(self, mock_img):
        """image/jpg → _extract_from_image çağrılmalı."""
        mock_img.return_value = "OCR metni"
        self.extractor.extract(b"fake", "image/jpg")
        mock_img.assert_called_once()

    def test_unsupported_content_type_raises_error(self):
        """Desteklenmeyen tip → ValueError fırlatılmalı."""
        with pytest.raises(ValueError, match="Desteklenmeyen dosya formatı"):
            self.extractor.extract(b"fake", "application/msword")

    def test_empty_content_type_raises_error(self):
        """Boş content type → ValueError fırlatılmalı."""
        with pytest.raises(ValueError, match="Desteklenmeyen dosya formatı"):
            self.extractor.extract(b"fake", "")

    def test_content_type_is_normalized(self):
        """Content type lower-case'e çevrilmeli."""
        with patch.object(TextExtractor, "_extract_from_pdf") as mock_pdf:
            mock_pdf.return_value = "metin"
            # Büyük harf gönder
            self.extractor.extract(b"fake", "APPLICATION/PDF")
            mock_pdf.assert_called_once()

    def test_content_type_is_trimmed(self):
        """Content type başında/sonunda boşluk varsa temizlenmeli."""
        with patch.object(TextExtractor, "_extract_from_pdf") as mock_pdf:
            mock_pdf.return_value = "metin"
            self.extractor.extract(b"fake", "  application/pdf  ")
            mock_pdf.assert_called_once()


# ============================================================
# 2. PDF Extraction (pdfplumber mock'lı)
# ============================================================

class TestPdfExtraction:
    """PDF metin çıkarma testleri (pdfplumber mock'lı)."""

    def setup_method(self):
        self.extractor = TextExtractor()

    @patch("pdfplumber.open")
    def test_pdf_extracts_text_from_pages(self, mock_open):
        """PDF'in tüm sayfalarından metin çıkarılmalı."""
        # 2 sayfalık fake PDF
        page1 = MagicMock()
        page1.extract_text.return_value = "Sayfa 1 metni"
        page2 = MagicMock()
        page2.extract_text.return_value = "Sayfa 2 metni"

        mock_pdf = MagicMock()
        mock_pdf.pages = [page1, page2]
        mock_open.return_value.__enter__.return_value = mock_pdf

        result = self.extractor._extract_from_pdf(b"fake pdf bytes")

        assert "Sayfa 1 metni" in result
        assert "Sayfa 2 metni" in result

    @patch("pdfplumber.open")
    def test_pdf_joins_pages_with_newline(self, mock_open):
        """Sayfa metinleri newline ile birleştirilmeli."""
        page1 = MagicMock()
        page1.extract_text.return_value = "Birinci"
        page2 = MagicMock()
        page2.extract_text.return_value = "İkinci"

        mock_pdf = MagicMock()
        mock_pdf.pages = [page1, page2]
        mock_open.return_value.__enter__.return_value = mock_pdf

        result = self.extractor._extract_from_pdf(b"fake")

        assert result == "Birinci\nİkinci"

    @patch("pdfplumber.open")
    def test_pdf_skips_empty_pages(self, mock_open):
        """Boş sayfalar atlanmalı."""
        page1 = MagicMock()
        page1.extract_text.return_value = "İçerikli sayfa"
        page2 = MagicMock()
        page2.extract_text.return_value = None  # Boş sayfa

        mock_pdf = MagicMock()
        mock_pdf.pages = [page1, page2]
        mock_open.return_value.__enter__.return_value = mock_pdf

        result = self.extractor._extract_from_pdf(b"fake")

        assert result == "İçerikli sayfa"

    @patch("pdfplumber.open")
    def test_empty_pdf_raises_error(self, mock_open):
        """Tamamen boş PDF → ValueError fırlatılmalı."""
        page1 = MagicMock()
        page1.extract_text.return_value = None

        mock_pdf = MagicMock()
        mock_pdf.pages = [page1]
        mock_open.return_value.__enter__.return_value = mock_pdf

        with pytest.raises(ValueError, match="metin çıkarılamadı"):
            self.extractor._extract_from_pdf(b"fake")

    @patch("pdfplumber.open")
    def test_pdf_parsing_error_raises_value_error(self, mock_open):
        """pdfplumber hatası ValueError'a dönüşmeli."""
        mock_open.side_effect = Exception("Bozuk PDF dosyası")

        with pytest.raises(ValueError, match="PDF okunamadı"):
            self.extractor._extract_from_pdf(b"corrupted bytes")


# ============================================================
# 3. Image (OCR) Extraction
# ============================================================

class TestImageExtraction:
    """Görüntü OCR metin çıkarma testleri (pytesseract mock'lı)."""

    def setup_method(self):
        self.extractor = TextExtractor()

    @patch("pytesseract.image_to_string")
    @patch("PIL.Image.open")
    def test_image_extracts_text_via_tesseract(self, mock_img_open, mock_ocr):
        """OCR ile metin çıkarılmalı."""
        mock_img = MagicMock()
        mock_img_open.return_value = mock_img
        mock_ocr.return_value = "OCR ile okunan Türkçe metin"

        result = self.extractor._extract_from_image(b"fake image bytes")

        assert "OCR ile okunan" in result

    @patch("pytesseract.image_to_string")
    @patch("PIL.Image.open")
    def test_ocr_uses_turkish_language(self, mock_img_open, mock_ocr):
        """OCR Türkçe (tur) diliyle yapılmalı."""
        mock_img = MagicMock()
        mock_img_open.return_value = mock_img
        mock_ocr.return_value = "metin"

        self.extractor._extract_from_image(b"fake")

        # image_to_string lang='tur' ile çağrıldı mı?
        call_kwargs = mock_ocr.call_args.kwargs
        assert call_kwargs["lang"] == "tur"

    @patch("pytesseract.image_to_string")
    @patch("PIL.Image.open")
    def test_empty_ocr_result_raises_error(self, mock_img_open, mock_ocr):
        """OCR boş metin dönerse ValueError."""
        mock_img = MagicMock()
        mock_img_open.return_value = mock_img
        mock_ocr.return_value = ""  # Boş OCR sonucu

        with pytest.raises(ValueError, match="metin çıkarılamadı"):
            self.extractor._extract_from_image(b"fake")

    @patch("PIL.Image.open")
    def test_image_processing_error_raises_value_error(self, mock_img_open):
        """PIL hatası ValueError'a dönüşmeli."""
        mock_img_open.side_effect = Exception("Bozuk görüntü")

        with pytest.raises(ValueError, match="Görüntü işlenemedi"):
            self.extractor._extract_from_image(b"corrupted")


# ============================================================
# 4. Class Attributes
# ============================================================

class TestClassAttributes:
    """Sabit class attribute testleri."""

    def test_pdf_types_defined(self):
        """PDF_TYPES set'i tanımlı olmalı."""
        assert "application/pdf" in TextExtractor.PDF_TYPES

    def test_image_types_include_common_formats(self):
        """IMAGE_TYPES yaygın formatları içermeli."""
        assert "image/png" in TextExtractor.IMAGE_TYPES
        assert "image/jpeg" in TextExtractor.IMAGE_TYPES
        assert "image/jpg" in TextExtractor.IMAGE_TYPES


# ============================================================
# 5. Singleton Pattern
# ============================================================

class TestSingleton:
    """get_text_extractor singleton testleri."""

    def setup_method(self):
        """Singleton sıfırla."""
        import app.ai.text_extractor as te
        te._extractor_instance = None

    def test_returns_same_instance(self):
        """get_text_extractor aynı instance'ı dönmeli."""
        extractor1 = get_text_extractor()
        extractor2 = get_text_extractor()
        assert extractor1 is extractor2

    def test_singleton_is_text_extractor_type(self):
        """Singleton TextExtractor tipinde olmalı."""
        extractor = get_text_extractor()
        assert isinstance(extractor, TextExtractor)


# ============================================================
# 6. Integration: Public API
# ============================================================

class TestExtractPublicAPI:
    """extract() public API uçtan uca testleri."""

    def setup_method(self):
        self.extractor = TextExtractor()

    @patch("pdfplumber.open")
    def test_full_pdf_extraction_flow(self, mock_open):
        """extract() PDF için tam akış."""
        page = MagicMock()
        page.extract_text.return_value = "Tam akış testi metin"

        mock_pdf = MagicMock()
        mock_pdf.pages = [page]
        mock_open.return_value.__enter__.return_value = mock_pdf

        result = self.extractor.extract(b"fake pdf", "application/pdf")

        assert "Tam akış testi metin" in result
        assert isinstance(result, str)
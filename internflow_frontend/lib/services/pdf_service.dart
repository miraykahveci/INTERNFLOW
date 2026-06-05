import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ai_analysis.dart';


class PdfService {
  
  static final _primaryColor = PdfColor.fromHex('#6A0F0F'); // bordo
  static final _purpleGlow = PdfColor.fromHex('#8B5CF6'); // mor
  static final _textPrimary = PdfColor.fromHex('#1A1A2E');
  static final _textSecondary = PdfColor.fromHex('#64748B');
  static final _highRisk = PdfColor.fromHex('#DC2626');
  static final _mediumRisk = PdfColor.fromHex('#EA580C');
  static final _lowRisk = PdfColor.fromHex('#16A34A');
  static final _bgLight = PdfColor.fromHex('#F8F7FB');

  
  Future<void> generateAndDownload({
    required AiAnalysis analysis,
    required String studentName,
  }) async {
    // Türkçe karakter desteği için font yükle
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontSemi = await PdfGoogleFonts.openSansSemiBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(studentName, analysis),
          pw.SizedBox(height: 24),
          _buildRiskSection(analysis, fontSemi, fontBold),
          pw.SizedBox(height: 20),
          _buildSummarySection(analysis, fontSemi),
          if (analysis.plagiarismExplanation != null &&
              analysis.plagiarismExplanation!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildExplanationSection(analysis, fontSemi),
          ],
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'AI_Analiz_Raporu_${studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  // ===== BÖLÜMLER =====

  pw.Widget _buildHeader(String studentName, AiAnalysis a) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_primaryColor, PdfColor.fromHex('#4A0808')],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white.shade(0.15),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'AI ANALİZ RAPORU',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 9, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            studentName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Staj Defteri Intihal Analizi ve Otomatik Ozet',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 13,
            ),
          ),
          if (a.completedAt != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Analiz Tarihi: ${_formatDate(a.completedAt!)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRiskSection(AiAnalysis a, pw.Font fontSemi, pw.Font fontBold) {
    final riskColor = _riskColor(a.riskLevel);
    return pw.Row(
      children: [
        // Risk kartı
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: riskColor.shade(0.3), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RISK SEVIYESI',
                  style: pw.TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    font: fontSemi,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  a.riskLabel,
                  style: pw.TextStyle(
                    color: riskColor,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        // Skor kartı
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: _purpleGlow.shade(0.3), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BENZERLIK ORANI',
                  style: pw.TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    font: fontSemi,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '%${a.scorePercent}',
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection(AiAnalysis a, pw.Font fontSemi) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#EEEEF2'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 16,
                color: _purpleGlow,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'AI Ozet',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            a.aiSummary ?? 'Ozet bulunamadi.',
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 11,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExplanationSection(AiAnalysis a, pw.Font fontSemi) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _highRisk.shade(0.04),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _highRisk.shade(0.3), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 16,
                color: _highRisk,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Intihal Aciklamasi',
                style: pw.TextStyle(
                  color: _highRisk,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            a.plagiarismExplanation ?? '',
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 11,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#EEEEF2'), width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'InternFlow - AI Analiz Sistemi',
            style: pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
          pw.Text(
            'Bu rapor otomatik olarak uretilmistir.',
            style: pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  

  PdfColor _riskColor(String? risk) {
    switch (risk) {
      case 'high':
        return _highRisk;
      case 'medium':
        return _mediumRisk;
      case 'low':
        return _lowRisk;
      default:
        return _textSecondary;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }
}
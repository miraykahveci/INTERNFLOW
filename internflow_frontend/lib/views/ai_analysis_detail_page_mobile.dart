import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../models/ai_analysis.dart';

class AiAnalysisDetailMobile extends StatefulWidget {
  final String documentId;
  final String studentName;

  const AiAnalysisDetailMobile({
    super.key,
    required this.documentId,
    required this.studentName,
  });

  @override
  State<AiAnalysisDetailMobile> createState() => _AiAnalysisDetailMobileState();
}

class _AiAnalysisDetailMobileState extends State<AiAnalysisDetailMobile> {
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  final AiService _aiService = AiService();
  final PdfService _pdfService = PdfService();

  bool _isLoading = true;
  AiAnalysis? _analysis;
  String? _analysisId;
  Timer? _pollTimer;
  bool _isStarting = false;
  bool _isGeneratingPdf = false;

  
  String? _internshipId;
  String? _internshipResult;
  String? _academicianComment;
  DateTime? _completedAt;
  bool _isSubmittingResult = false;

  @override
  void initState() {
    super.initState();
    _loadExistingResult();
    _loadInternshipData();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExistingResult() async {
    setState(() => _isLoading = true);
    final result = await _aiService.getResult(widget.documentId);
    if (!mounted) return;
    setState(() {
      _analysis = result != null ? AiAnalysis.fromJson(result) : null;
      _isLoading = false;
    });
  }

  
  Future<void> _loadInternshipData() async {
    try {
      final docRes = await Supabase.instance.client
          .from('documents')
          .select('intern_id')
          .eq('document_id', widget.documentId)
          .maybeSingle();

      if (docRes == null) return;
      final internId = docRes['intern_id'] as String?;
      if (internId == null) return;

      final intRes = await Supabase.instance.client
          .from('internship')
          .select('intern_id, status, result, academician_comment, completed_at')
          .eq('intern_id', internId)
          .maybeSingle();

      if (intRes == null || !mounted) return;

      setState(() {
        _internshipId = intRes['intern_id'] as String?;
        _internshipResult = intRes['result'] as String?;
        _academicianComment = intRes['academician_comment'] as String?;
        _completedAt = intRes['completed_at'] != null
            ? DateTime.tryParse(intRes['completed_at'].toString())
            : null;
      });
    } catch (e) {
      debugPrint('Internship verisi yüklenemedi: $e');
    }
  }

  Future<void> _startAnalysis() async {
    setState(() => _isStarting = true);
    final response = await _aiService.startAnalysis(widget.documentId);
    if (!mounted) return;

    if (response == null) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analiz başlatılamadı. Backend çalışıyor mu?'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _analysisId = response['analysis_id']?.toString();
    setState(() {
      _isStarting = false;
      _analysis = AiAnalysis(
        analysisId: _analysisId ?? '',
        status: 'processing',
        progress: 0,
        currentStep: 'Analiz başlatılıyor',
      );
    });
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_analysisId == null) return;
      final status = await _aiService.getStatus(_analysisId!);
      if (!mounted) return;
      if (status == null) return;

      final updated = AiAnalysis.fromJson(status);
      setState(() => _analysis = updated);

      if (updated.isCompleted) {
        timer.cancel();
        final full = await _aiService.getResult(widget.documentId);
        if (!mounted) return;
        if (full != null) {
          setState(() => _analysis = AiAnalysis.fromJson(full));
        }
      } else if (updated.isFailed) {
        timer.cancel();
      }
    });
  }

  Future<void> _downloadPdf() async {
    final a = _analysis;
    if (a == null || !a.isCompleted) return;

    setState(() => _isGeneratingPdf = true);
    try {
      await _pdfService.generateAndDownload(
        analysis: a,
        studentName: widget.studentName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  /// Stajı sonuçlandır — Supabase'e UPDATE atar
  Future<void> _submitResult({
    required bool isSuccess,
    required String comment,
  }) async {
    if (_internshipId == null) return;

    setState(() => _isSubmittingResult = true);

    try {
      final now = DateTime.now();

      await Supabase.instance.client
          .from('internship')
          .update({
            'status': 'completed',
            'result': isSuccess ? 'success' : 'fail',
            'academician_comment': comment,
            'completed_at': now.toIso8601String(),
          })
          .eq('intern_id', _internshipId!);

      

      if (!mounted) return;

      setState(() {
        _internshipResult = isSuccess ? 'success' : 'fail';
        _academicianComment = comment;
        _completedAt = now;
        _isSubmittingResult = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess
                  ? 'Staj BAŞARILI olarak sonuçlandırıldı ✅'
                  : 'Staj BAŞARISIZ olarak sonuçlandırıldı ❌',
            ),
            backgroundColor: isSuccess
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingResult = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sonuçlandırma başarısız: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  
  void _showResultBottomSheet() {
    bool? isSuccess;
    final commentController = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Başlık
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryColor, primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.emoji_events,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stajı Sonuçlandır',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Akademik değerlendirme',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'Sonuç',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResultOption(
                              isSelected: isSuccess == true,
                              label: 'BAŞARILI',
                              icon: Icons.check_circle,
                              color: const Color(0xFF16A34A),
                              onTap: () => setSheetState(() => isSuccess = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildResultOption(
                              isSelected: isSuccess == false,
                              label: 'BAŞARISIZ',
                              icon: Icons.cancel,
                              color: const Color(0xFFDC2626),
                              onTap: () => setSheetState(() => isSuccess = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Akademisyen Yorumu',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFC),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: errorText != null
                                ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                                : const Color(0xFFEEEEF2),
                          ),
                        ),
                        child: TextField(
                          controller: commentController,
                          maxLines: 4,
                          minLines: 3,
                          maxLength: 1000,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Değerlendirmenizi yazınız (min 30 karakter)...',
                            hintStyle: TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                            counterText: '',
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFDC2626), size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                child: const Text(
                                  'İptal',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isSuccess == null) {
                                    setSheetState(() {
                                      errorText = 'Lütfen sonuç seçiniz';
                                    });
                                    return;
                                  }
                                  final comment = commentController.text.trim();
                                  if (comment.length < 30) {
                                    setSheetState(() {
                                      errorText =
                                          'Yorum en az 30 karakter (${comment.length}/30)';
                                    });
                                    return;
                                  }
                                  Navigator.pop(sheetContext);
                                  _showConfirmDialog(
                                    isSuccess: isSuccess!,
                                    comment: comment,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Sonuçlandır',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Başarılı/Başarısız seçim kartı
  Widget _buildResultOption({
    required bool isSelected,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                : null,
            color: !isSelected ? const Color(0xFFFAFAFC) : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFEEEEF2),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Onay diyaloğu
  void _showConfirmDialog({required bool isSuccess, required String comment}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEA580C), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sonuçlandırma Onayı',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu staj ${isSuccess ? "BAŞARILI" : "BAŞARISIZ"} olarak sonuçlandırılacak.\nBu işlem GERİ ALINAMAZ.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _submitResult(isSuccess: isSuccess, comment: comment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Onayla',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(String? risk) {
    switch (risk) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFEA580C);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18),
            SizedBox(width: 8),
            Text('AI Analiz', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.studentName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Staj defteri intihal kontrolü',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: purpleGlow)),
      );
    }
    final a = _analysis;
    if (a == null) return _buildIdle();
    if (a.isProcessing) return _buildProcessing(a);
    if (a.isCompleted) return _buildCompleted(a);
    if (a.isFailed) return _buildFailed(a);
    return _buildIdle();
  }

  Widget _buildIdle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 18),
          const Text(
            'AI Analizi Henüz Yapılmadı',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'İntihal kontrolü ve otomatik özet için analizi başlatın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startAnalysis,
              icon: _isStarting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: Text(_isStarting ? 'Başlatılıyor...' : 'AI Analiz Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleGlow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CircularProgressIndicator(color: purpleGlow),
          const SizedBox(height: 20),
          Text(
            '%${a.progress}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            a.currentStep ?? 'İşleniyor...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: a.progress / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(purpleGlow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(AiAnalysis a) {
    final riskColor = _riskColor(a.riskLevel);
    final hasResult = _internshipResult != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk kartı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [riskColor, riskColor.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.riskLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                  ),
                  Text('Benzerlik: %${a.scorePercent}', style: const TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // AI Özet
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.summarize_outlined, color: purpleGlow, size: 20),
                  const SizedBox(width: 8),
                  const Text('AI Özet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                a.aiSummary ?? 'Özet bulunamadı.',
                style: const TextStyle(fontSize: 13, color: textPrimary, height: 1.6),
              ),
            ],
          ),
        ),
        // ===== EN BENZER DEFTER KARTI  =====
        if (a.hasSimilarMatch) ...[
          const SizedBox(height: 16),
          _buildSimilarMatchCard(a),
        ],
        if (a.plagiarismExplanation != null && a.plagiarismExplanation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text('İntihal Açıklaması', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  a.plagiarismExplanation ?? '',
                  style: const TextStyle(fontSize: 13, color: textPrimary, height: 1.6),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // PDF İndir butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _downloadPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 18),
            label: Text(_isGeneratingPdf ? 'Oluşturuluyor...' : 'PDF İndir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              elevation: 4,
              shadowColor: purpleGlow.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Yeniden Analiz butonu
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _startAnalysis,
            icon: Icon(Icons.refresh, color: purpleGlow, size: 18),
            label: const Text('Yeniden Analiz Et'),
            style: OutlinedButton.styleFrom(
              foregroundColor: purpleGlow,
              side: BorderSide(color: purpleGlow.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // SONUÇLANDIRMA: ya buton, ya rozet
        if (hasResult) _buildResultBanner() else _buildResultButton(),
      ],
    );
  }

  // ===== EN BENZER DEFTER KARTI  =====
  Widget _buildSimilarMatchCard(AiAnalysis a) {
    final score = a.scorePercent;
    final riskColor = _riskColor(a.riskLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            purpleGlow.withValues(alpha: 0.05),
            const Color(0xFF2563EB).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleGlow.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, const Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: purpleGlow.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'En Benzer Defter',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [riskColor, riskColor.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '%$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Öğrenci bilgi kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      a.similarStudentName!.isNotEmpty
                          ? a.similarStudentName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.similarStudentName ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (a.similarStudentNumber != null) ...[
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 11, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'No: ${a.similarStudentNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (a.similarCompanyName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.business_outlined, size: 11, color: textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.similarCompanyName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bilgi notu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 12, color: textMuted),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Bu defter, yukarıdaki öğrencinin defteriyle yüksek anlamsal benzerlik gösteriyor.',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== STAJI SONUÇLANDIR BUTONU  =====
  Widget _buildResultButton() {
    return GestureDetector(
      onTap: _isSubmittingResult ? null : _showResultBottomSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: purpleGlow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stajı Sonuçlandır',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Akademik değerlendirme yap',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isSubmittingResult)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ===== SONUÇLANDIRILDI ROZETİ  =====
  Widget _buildResultBanner() {
    final isSuccess = _internshipResult == 'success';
    final color = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = isSuccess ? 'BAŞARILI' : 'BAŞARISIZ';
    final icon = isSuccess ? Icons.check_circle : Icons.cancel;

    String completedDateText = '-';
    if (_completedAt != null) {
      final d = _completedAt!;
      completedDateText =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rozet satırı
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Staj Sonuçlandırıldı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.event_available, size: 12, color: textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          completedDateText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFEEEEF2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 10, color: textMuted),
                              SizedBox(width: 3),
                              Text(
                                'KALICI',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Akademisyen yorumu 
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.format_quote, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'Akademisyen Değerlendirmesi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: Text(
              _academicianComment ?? '-',
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailed(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 16),
          const Text('Analiz Başarısız', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text(
            a.errorMessage ?? 'Bilinmeyen bir hata oluştu.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startAnalysis,
              icon: Icon(Icons.refresh, color: purpleGlow, size: 18),
              label: const Text('Yeniden Dene'),
              style: OutlinedButton.styleFrom(
                foregroundColor: purpleGlow,
                side: BorderSide(color: purpleGlow.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEF2)),
      boxShadow: [
        BoxShadow(
          color: purpleGlow.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
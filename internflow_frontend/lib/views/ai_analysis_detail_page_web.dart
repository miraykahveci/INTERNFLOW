import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../models/ai_analysis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiAnalysisDetailWeb extends StatefulWidget {
  final String documentId;
  final String studentName;

  const AiAnalysisDetailWeb({
    super.key,
    required this.documentId,
    required this.studentName,
  });

  @override
  State<AiAnalysisDetailWeb> createState() => _AiAnalysisDetailWebState();
}

class _AiAnalysisDetailWebState extends State<AiAnalysisDetailWeb> {
  
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
  bool _hoveredStart = false;
  bool _isGeneratingPdf = false;

  String? _internshipId;
  String? _internshipStatus;
  String? _internshipResult;
  String? _academicianComment;
  DateTime? _completedAt;
  bool _isSubmittingResult = false;
  bool _hoveredResultButton = false;

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
      // 1. document'tan intern_id'yi al
      final docRes = await Supabase.instance.client
          .from('documents')
          .select('intern_id')
          .eq('document_id', widget.documentId)
          .maybeSingle();

      if (docRes == null) return;
      final internId = docRes['intern_id'] as String?;
      if (internId == null) return;

      // 2. internship verisini çek
      final intRes = await Supabase.instance.client
          .from('internship')
          .select('intern_id, status, result, academician_comment, completed_at')
          .eq('intern_id', internId)
          .maybeSingle();

      if (intRes == null || !mounted) return;

      setState(() {
        _internshipId = intRes['intern_id'] as String?;
        _internshipStatus = intRes['status'] as String?;
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

      // TODO: öğrenciye notification atılacak

      if (!mounted) return;

      setState(() {
        _internshipStatus = 'completed';
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
      _showError('Sonuçlandırma başarısız: $e');
    }
  }

  /// "Stajı Sonuçlandır" 
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48, height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryColor, primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.emoji_events,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stajı Sonuçlandır',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Akademik değerlendirmeni gir',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        'Sonuç',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 24),

                      const Text(
                        'Akademisyen Yorumu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: errorText != null
                                ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                                : const Color(0xFFEEEEF2),
                          ),
                        ),
                        child: TextField(
                          controller: commentController,
                          maxLines: 5,
                          minLines: 4,
                          maxLength: 1000,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Öğrenci hakkındaki değerlendirmenizi yazınız (en az 30 karakter)...',
                            hintStyle: TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                            counterText: '',
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFDC2626), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              errorText!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFFE4E4E7)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                child: const Text(
                                  'İptal',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 52,
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
                                          'Yorum en az 30 karakter olmalıdır (${comment.length}/30)';
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
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  elevation: 8,
                                  shadowColor:
                                      primaryColor.withValues(alpha: 0.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sonuçlandır',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                : null,
            color: !isSelected ? const Color(0xFFFAFAFC) : null,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFEEEEF2),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 13,
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

  void _showConfirmDialog({required bool isSuccess, required String comment}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEA580C), size: 32),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sonuçlandırma Onayı',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bu staj ${isSuccess ? "BAŞARILI" : "BAŞARISIZ"} olarak sonuçlandırılacak.\nBu işlem GERİ ALINAMAZ.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _submitResult(isSuccess: isSuccess, comment: comment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Onayla',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  /// "AI Analiz Et" 
  Future<void> _startAnalysis() async {
    setState(() => _isStarting = true);
    final response = await _aiService.startAnalysis(widget.documentId);
    if (!mounted) return;

    if (response == null) {
      setState(() => _isStarting = false);
      _showError('Analiz başlatılamadı. Backend çalışıyor mu kontrol edin.');
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
      if (mounted) _showError('PDF oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(80),
        child: Center(child: CircularProgressIndicator(color: purpleGlow)),
      );
    }
    final a = _analysis;
    if (a == null) return _buildIdleState();
    if (a.isProcessing) return _buildProcessingState(a);
    if (a.isCompleted) return _buildCompletedState(a);
    if (a.isFailed) return _buildFailedState(a);
    return _buildIdleState();
  }

  // ===== HERO HEADER =====
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60, top: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 90, bottom: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'AI ANALİZ',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Staj defteri intihal kontrolü ve otomatik özet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: purpleGlow.withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI Analizi Henüz Yapılmadı',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu staj defterini analiz ederek intihal kontrolü yapın ve otomatik özet oluşturun.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStart = true),
      onExit: (_) => setState(() => _hoveredStart = false),
      child: GestureDetector(
        onTap: _isStarting ? null : _startAnalysis,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(0, _hoveredStart ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryColor, purpleGlow]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: purpleGlow.withValues(alpha: _hoveredStart ? 0.5 : 0.3),
                blurRadius: _hoveredStart ? 24 : 16,
                offset: Offset(0, _hoveredStart ? 10 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isStarting)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              else
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                _isStarting ? 'Başlatılıyor...' : 'AI Analiz Et',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== PROCESSING =====
  Widget _buildProcessingState(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '%${a.progress} Tamamlandı',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            a.currentStep ?? 'İşleniyor...',
            style: const TextStyle(fontSize: 15, color: textSecondary),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: a.progress / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(purpleGlow),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu işlem birkaç saniye sürebilir. Lütfen bekleyin.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ],
      ),
    );
  }

  // ===== COMPLETED =====
  Widget _buildCompletedState(AiAnalysis a) {
    final riskColor = _riskColor(a.riskLevel);
    final hasResult = _internshipResult != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildRiskCard(a, riskColor)),
            const SizedBox(width: 20),
            Expanded(child: _buildScoreCard(a, riskColor)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(a),
        // ===== EN BENZER DEFTER KARTI (YENİ) =====
        if (a.hasSimilarMatch) ...[
          const SizedBox(height: 24),
          _buildSimilarMatchCard(a),
        ],
        if (a.plagiarismExplanation != null && a.plagiarismExplanation!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildExplanationCard(a),
        ],
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPdfButton(),
              const SizedBox(width: 12),
              _buildReanalyzeButton(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (hasResult) _buildResultBanner() else _buildResultButton(),
      ],
    );
  }

  Widget _buildRiskCard(AiAnalysis a, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [riskColor, riskColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(color: riskColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            a.riskLabel,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: riskColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text('İntihal Risk Seviyesi', style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScoreCard(AiAnalysis a, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(color: purpleGlow.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            '%${a.scorePercent}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text('En Yüksek Benzerlik Oranı', style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, const Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.summarize_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'AI Özet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            a.aiSummary ?? 'Özet bulunamadı.',
            style: const TextStyle(fontSize: 14, color: textPrimary, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ===== EN BENZER DEFTER KARTI  =====
  Widget _buildSimilarMatchCard(AiAnalysis a) {
    final score = a.scorePercent;
    final riskColor = _riskColor(a.riskLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            purpleGlow.withValues(alpha: 0.04),
            const Color(0xFF2563EB).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleGlow.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, const Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: purpleGlow.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En Benzer Defter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Yapay zeka ile tespit edildi',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Benzerlik yüzde rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [riskColor, riskColor.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '%$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Öğrenci bilgi kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (a.similarStudentName != null && a.similarStudentName!.isNotEmpty)
                          ? a.similarStudentName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.similarStudentName ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (a.similarStudentNumber != null) ...[
                            Icon(Icons.badge_outlined, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'No: ${a.similarStudentNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (a.similarCompanyName != null) ...[
                            Icon(Icons.business_outlined, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.similarCompanyName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bilgi notu
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: textMuted),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Bu defter, yukarıdaki öğrencinin staj defteriyle yüksek anlamsal benzerlik gösteriyor.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFDC2626), const Color(0xFFEA580C)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'İntihal Açıklaması',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC2626), letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            a.plagiarismExplanation ?? '',
            style: const TextStyle(fontSize: 14, color: textPrimary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isGeneratingPdf ? null : _downloadPdf,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryColor, purpleGlow]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: purpleGlow.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGeneratingPdf)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else
                const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _isGeneratingPdf ? 'Oluşturuluyor...' : 'PDF İndir',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReanalyzeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _startAnalysis,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: purpleGlow.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: purpleGlow, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Yeniden Analiz Et',
                style: TextStyle(color: purpleGlow, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== STAJ SONUÇLANDIR BUTONU  =====
  Widget _buildResultButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredResultButton = true),
      onExit: (_) => setState(() => _hoveredResultButton = false),
      child: GestureDetector(
        onTap: _isSubmittingResult ? null : _showResultBottomSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hoveredResultButton ? -4 : 0, 0),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: _hoveredResultButton ? 0.5 : 0.3),
                blurRadius: _hoveredResultButton ? 32 : 20,
                offset: Offset(0, _hoveredResultButton ? 14 : 8),
              ),
              BoxShadow(
                color: purpleGlow.withValues(alpha: _hoveredResultButton ? 0.25 : 0.15),
                blurRadius: _hoveredResultButton ? 48 : 32,
                offset: Offset(0, _hoveredResultButton ? 20 : 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stajı Sonuçlandır',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Akademik değerlendirmeni gir ve stajı tamamla',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSubmittingResult)
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SONUÇLANDIRILDI ROZETİ + YORUM  =====
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Staj Sonuçlandırıldı',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_available, size: 13, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Tamamlandı: $completedDateText',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFEEEEF2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: textMuted),
                    SizedBox(width: 4),
                    Text(
                      'KALICI',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.format_quote, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Akademisyen Değerlendirmesi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: Text(
              _academicianComment ?? '-',
              style: const TextStyle(
                fontSize: 14,
                color: textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FAILED =====
  Widget _buildFailedState(AiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analiz Başarısız',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            a.errorMessage ?? 'Bilinmeyen bir hata oluştu.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          _buildReanalyzeButton(),
        ],
      ),
    );
  }

  // ===== Yardımcılar =====
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEF2)),
      boxShadow: [
        BoxShadow(
          color: purpleGlow.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
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
}
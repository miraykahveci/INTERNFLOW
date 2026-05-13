import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicianStudentDetailWeb extends StatefulWidget {
  final Map<String, dynamic> internship;

  const AcademicianStudentDetailWeb({super.key, required this.internship});

  @override
  State<AcademicianStudentDetailWeb> createState() => _AcademicianStudentDetailWebState();
}

class _AcademicianStudentDetailWebState extends State<AcademicianStudentDetailWeb> {
  // Premium color palette
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];

  late String _studentName;
  late String _studentNumber;
  late String _department;
  late String _companyName;
  late String _status;
  late String _startDate;
  late String _endDate;
  late String _internId;

  int _hoveredOverview = -1;
  int _hoveredDoc = -1;
  bool _hoveredAi = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadDocuments();
  }

  void _initData() {
    final student = widget.internship['users'] as Map<String, dynamic>?;
    _studentName = student?['full_name'] ?? 'Bilinmeyen';
    _studentNumber = student?['student_number']?.toString() ?? '-';
    _department = student?['department'] ?? '-';
    _companyName = widget.internship['company_name'] ?? '-';
    _status = widget.internship['status'] ?? 'pending';
    _startDate = widget.internship['start_date'] ?? '';
    _endDate = widget.internship['end_date'] ?? '';
    _internId = widget.internship['intern_id'] ?? '';
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await Supabase.instance.client
          .from('documents')
          .select()
          .eq('intern_id', _internId)
          .order('uploaded_at', ascending: false);

      setState(() {
        _documents = List<Map<String, dynamic>>.from(docs);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Belgeler yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocument(String filePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('documents')
          .createSignedUrl(filePath, 3600);
      final uri = Uri.parse(signedUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge açılamadı: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_status) {
      case 'pending':
        return {'label': 'Onay Bekliyor', 'color': const Color(0xFFEA580C)};
      case 'approved':
        return {'label': 'Onaylandı', 'color': const Color(0xFF16A34A)};
      case 'active':
        return {'label': 'Stajda', 'color': const Color(0xFF2563EB)};
      case 'completed':
        return {'label': 'Tamamlandı', 'color': purpleGlow};
      case 'rejected':
        return {'label': 'Reddedildi', 'color': const Color(0xFFDC2626)};
      default:
        return {'label': _status, 'color': textSecondary};
    }
  }

  double _getProgress() {
    switch (_status) {
      case 'pending': return 0.15;
      case 'approved': return 0.4;
      case 'active': return 0.7;
      case 'completed': return 1.0;
      default: return 0.0;
    }
  }

  int _getDaysCompleted() {
    if (_startDate.isEmpty) return 0;
    try {
      final start = DateTime.parse(_startDate);
      final now = DateTime.now();
      if (now.isBefore(start)) return 0;
      int days = 0;
      DateTime current = start;
      final end = _endDate.isNotEmpty ? DateTime.parse(_endDate) : now;
      while (current.isBefore(now) && current.isBefore(end)) {
        if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
          days++;
        }
        current = current.add(const Duration(days: 1));
      }
      return days;
    } catch (_) {
      return 0;
    }
  }

  int _getTotalDays() {
    if (_startDate.isEmpty || _endDate.isEmpty) return 0;
    try {
      final start = DateTime.parse(_startDate);
      final end = DateTime.parse(_endDate);
      int days = 0;
      DateTime current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
          days++;
        }
        current = current.add(const Duration(days: 1));
      }
      return days;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getDocTypeName(String docType) {
    switch (docType) {
      case 'basvuru_formu': return 'Başvuru / Kabul Formu';
      case 'sgk_belgesi': return 'SGK Giriş Belgesi';
      case 'staj_defteri': return 'Staj Defteri';
      case 'anket': return 'Firma Değerlendirme Anketi';
      default: return docType;
    }
  }

  IconData _getDocTypeIcon(String docType) {
    switch (docType) {
      case 'basvuru_formu': return Icons.description_outlined;
      case 'sgk_belgesi': return Icons.security;
      case 'staj_defteri': return Icons.book_outlined;
      case 'anket': return Icons.poll_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _getDocTypeColor(String docType) {
    switch (docType) {
      case 'basvuru_formu': return const Color(0xFF2563EB);
      case 'sgk_belgesi': return purpleGlow;
      case 'staj_defteri': return primaryColor;
      case 'anket': return const Color(0xFF00838F);
      default: return textSecondary;
    }
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
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview cards
                      _buildOverviewCards(),
                      const SizedBox(height: 32),

                      // 2-column layout
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LEFT: AI banner + Documents
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAiBanner(),
                                  const SizedBox(height: 20),
                                  _buildDocumentsCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // RIGHT: Application details
                            Expanded(
                              flex: 5,
                              child: _buildApplicationDetailsCard(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HERO HEADER ==========
  Widget _buildHeroHeader() {
    final statusInfo = _getStatusInfo();
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
                  colors: [purpleGlow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 80, bottom: -40,
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
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Avatar
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _studentName.isNotEmpty ? _studentName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),

                  // Info
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: statusInfo['color'],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (statusInfo['color'] as Color).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusInfo['label'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildHeroChip(Icons.school, _department),
                            const SizedBox(width: 10),
                            _buildHeroChip(Icons.badge_outlined, 'No: $_studentNumber'),
                            const SizedBox(width: 10),
                            _buildHeroChip(Icons.business_outlined, _companyName),
                          ],
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

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ========== OVERVIEW CARDS ==========
  Widget _buildOverviewCards() {
    final statusInfo = _getStatusInfo();
    final daysCompleted = _getDaysCompleted();
    final totalDays = _getTotalDays();
    final progressPercent = (_getProgress() * 100).toInt();

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            0,
            Icons.percent_outlined,
            'İlerleme',
            '%$progressPercent',
            primaryColor,
            showProgress: true,
            progressValue: _getProgress(),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildOverviewCard(
            1,
            Icons.calendar_today_outlined,
            'Gün',
            totalDays > 0 ? '$daysCompleted / $totalDays' : '- / -',
            purpleGlow,
            subtitle: 'Tamamlandı',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildOverviewCard(
            2,
            Icons.flag_outlined,
            'Durum',
            statusInfo['label'],
            statusInfo['color'],
            isLong: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildOverviewCard(
            3,
            Icons.folder_outlined,
            'Belge',
            '${_documents.length}',
            const Color(0xFF2563EB),
            subtitle: 'Yüklendi',
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(int index, IconData icon, String label, String value, Color accentColor,
      {bool showProgress = false, double progressValue = 0, bool isLong = false, String? subtitle}) {
    final isHovered = _hoveredOverview == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOverview = index),
      onExit: (_) => setState(() => _hoveredOverview = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.06),
              blurRadius: isHovered ? 28 : 20,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.1) : purpleGlow.withValues(alpha: 0.04),
              blurRadius: isHovered ? 40 : 28,
              offset: Offset(0, isHovered ? 18 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovered
                      ? [accentColor, accentColor.withValues(alpha: 0.7)]
                      : [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 22),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                fontSize: isLong ? 17 : 26,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.6,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle ?? label,
              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: const Color(0xFFF4F4F5),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== AI BANNER ==========
  Widget _buildAiBanner() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAi = true),
      onExit: (_) => setState(() => _hoveredAi = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('AI Analiz modülü final döneminde aktifleşecektir.')),
                ],
              ),
              backgroundColor: Color(0xFF7C3AED),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hoveredAi ? -4 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                purpleGlow.withValues(alpha: _hoveredAi ? 0.1 : 0.06),
                const Color(0xFF2563EB).withValues(alpha: _hoveredAi ? 0.1 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hoveredAi ? purpleGlow.withValues(alpha: 0.4) : purpleGlow.withValues(alpha: 0.15),
              width: _hoveredAi ? 1.5 : 1,
            ),
            boxShadow: _hoveredAi
                ? [
                    BoxShadow(
                      color: purpleGlow.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: purpleGlow.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Analiz Paneli',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                        ),
                        SizedBox(width: 10),
                        _ComingSoonBadge(),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bu öğrencinin staj defteri için intihal kontrolü ve otomatik özet oluştur.',
                      style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: purpleGlow, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ========== DOCUMENTS CARD ==========
  Widget _buildDocumentsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.folder_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yüklenen Belgeler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Öğrencinin paylaştığı tüm dosyalar', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${_documents.length} dosya',
                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            )
          else if (_documents.isEmpty)
            _buildEmptyDocs()
          else
            Column(
              children: List.generate(_documents.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i < _documents.length - 1 ? 12 : 0),
                  child: _buildDocumentCard(_documents[i], i),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDocs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.04),
            purpleGlow.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.folder_open_outlined, size: 32, color: primaryColor),
          ),
          const SizedBox(height: 14),
          const Text(
            'Henüz belge yüklenmedi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Öğrenci dosya yüklediğinde burada görünecek',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, int index) {
    final docType = doc['doc_type'] as String? ?? '';
    final fileUrl = doc['file_url'] as String? ?? '';
    final uploadedAt = doc['uploaded_at']?.toString().split('T')[0] ?? '';
    final accentColor = _getDocTypeColor(docType);
    final isHovered = _hoveredDoc == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredDoc = index),
      onExit: (_) => setState(() => _hoveredDoc = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovered
                      ? [accentColor, accentColor.withValues(alpha: 0.7)]
                      : [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(_getDocTypeIcon(docType), color: isHovered ? Colors.white : accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDocTypeName(docType),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 11, color: textMuted),
                      const SizedBox(width: 5),
                      Text(
                        'Yüklendi: $uploadedAt',
                        style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PDF',
                          style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => _viewDocument(fileUrl),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('İncele', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== APPLICATION DETAILS CARD ==========
  Widget _buildApplicationDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Başvuru Detayları', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Staj başvuru bilgileri', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date range card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.04),
                  purpleGlow.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tarih Aralığı',
                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDate(_startDate)}  →  ${_formatDate(_endDate)}',
                        style: const TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildDetailGroup('STAJ BİLGİLERİ', [
            _buildDetailRow(Icons.work_outline, 'Staj Türü', widget.internship['internship_type'] == 'summer' ? 'Yaz Stajı' : 'Dönem İçi'),
          ]),
          const SizedBox(height: 14),
          _buildDetailGroup('KURUM BİLGİLERİ', [
            _buildDetailRow(Icons.business_outlined, 'Kurum Adı', _companyName),
            _buildDetailRow(Icons.category_outlined, 'Sektör', widget.internship['company_sector'] ?? '-'),
            _buildDetailRow(Icons.location_on_outlined, 'Adres', widget.internship['company_address'] ?? '-'),
            _buildDetailRow(Icons.email_outlined, 'E-posta', widget.internship['company_email'] ?? '-'),
          ]),
          const SizedBox(height: 14),
          _buildDetailGroup('YETKİLİ & SİGORTA', [
            _buildDetailRow(Icons.person_outline, 'Yetkili Mühendis', widget.internship['supervisor_name'] ?? '-'),
            _buildDetailRow(
              Icons.security_outlined,
              'SGK Durumu',
              widget.internship['has_sgk'] == true ? 'Öğrenciden (Müstehaklık var)' : 'Okul Tarafından Yapılacak',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailGroup(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== COMING SOON BADGE ==========
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'YAKINDA',
        style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }
}
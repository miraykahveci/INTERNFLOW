import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentResultsWeb extends StatefulWidget {
  const StudentResultsWeb({super.key});

  @override
  State<StudentResultsWeb> createState() => _StudentResultsWebState();
}

class _StudentResultsWebState extends State<StudentResultsWeb> {
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  bool _isLoading = true;
  List<Map<String, dynamic>> _completedInternships = [];

  int _hoveredStat = -1;
  int _hoveredCard = -1;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final response = await Supabase.instance.client
          .from('internship')
          .select('*, users!internship_academician_id_fkey(full_name, title)')
          .eq('student_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      setState(() {
        _completedInternships = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Sonuçlar yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  int get _successCount => _completedInternships.where((i) => i['result'] == 'success').length;
  int get _failCount => _completedInternships.where((i) => i['result'] == 'fail').length;
  int get _pendingCount => _completedInternships.where((i) => i['result'] == null).length;

  int get _totalWorkDays {
    int total = 0;
    for (var i in _completedInternships) {
      try {
        final start = DateTime.parse(i['start_date']);
        final end = DateTime.parse(i['end_date']);
        DateTime current = start;
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
            total++;
          }
          current = current.add(const Duration(days: 1));
        }
      } catch (_) {}
    }
    return total;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgCanvas,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

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
                  child: _completedInternships.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stat cards
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(0, Icons.school_outlined, '${_completedInternships.length}', 'Toplam Staj', primaryColor)),
                                const SizedBox(width: 20),
                                Expanded(child: _buildStatCard(1, Icons.check_circle_outline, '$_successCount', 'Başarılı', const Color(0xFF16A34A))),
                                const SizedBox(width: 20),
                                Expanded(child: _buildStatCard(2, Icons.cancel_outlined, '$_failCount', 'Başarısız', const Color(0xFFDC2626))),
                                const SizedBox(width: 20),
                                Expanded(child: _buildStatCard(3, Icons.calendar_today_outlined, '$_totalWorkDays', 'Toplam İş Günü', purpleGlow)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            _buildSectionTitle('Tamamlanan Stajlar', 'Tüm staj geçmişin ve değerlendirme sonuçların'),
                            const SizedBox(height: 20),

                            ...List.generate(_completedInternships.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildResultCard(_completedInternships[i], i),
                              );
                            }),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFBC02D).withValues(alpha: 0.2),
                                const Color(0xFFFBC02D).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events, color: Color(0xFFFBC02D), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'STAJ SONUÇLARIN',
                                style: TextStyle(color: Color(0xFFFBC02D), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sonuçlarım',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _completedInternships.isEmpty
                              ? 'Tamamladığın stajların değerlendirme sonuçları burada görünecek.'
                              : '${_completedInternships.length} tamamlanmış stajının sonuç ve değerlendirmeleri.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
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

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.04),
            purpleGlow.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  purpleGlow.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.school_outlined, size: 56, color: primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz tamamlanmış stajın yok 🎓',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            'İlk stajını tamamladığında sonuçların ve akademisyen değerlendirmelerin\nburada toplanacak. Yolculuğun başlangıcındasın!',
            style: TextStyle(fontSize: 14, color: textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Aktif başvurun varsa "Sürecim" sekmesinden takip edebilirsin',
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== STAT CARD ==========
  Widget _buildStatCard(int index, IconData icon, String value, String label, Color accentColor) {
    final isHovered = _hoveredStat == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredStat = index),
      onExit: (_) => setState(() => _hoveredStat = -1),
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.7, height: 1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: textSecondary),
        ),
      ],
    );
  }

  // ========== RESULT CARD ==========
  Widget _buildResultCard(Map<String, dynamic> internship, int index) {
    final result = internship['result'] as String?;
    final isSuccess = result == 'success';
    final hasResult = result != null;
    final companyName = internship['company_name'] ?? '-';
    final startDate = _formatDate(internship['start_date']);
    final endDate = _formatDate(internship['end_date']);
    final completedAt = _formatDate(internship['completed_at']?.toString().split('T')[0]);
    final comment = internship['academician_comment'] as String?;
    final academician = internship['users'];
    final academicianName = academician != null
        ? '${academician['title'] ?? ''} ${academician['full_name'] ?? ''}'.trim()
        : 'Değerlendirici';
    final internshipType = internship['internship_type'] == 'summer' ? 'Yaz Stajı' : 'Dönem İçi Staj';

    final accentColor = !hasResult
        ? textSecondary
        : isSuccess
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);

    final isHovered = _hoveredCard == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = index),
      onExit: (_) => setState(() => _hoveredCard = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.18) : accentColor.withValues(alpha: 0.05),
              blurRadius: isHovered ? 28 : 20,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.08) : purpleGlow.withValues(alpha: 0.04),
              blurRadius: isHovered ? 40 : 28,
              offset: Offset(0, isHovered ? 18 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Result icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasResult
                          ? [accentColor, accentColor.withValues(alpha: 0.7)]
                          : [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: hasResult
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    !hasResult ? Icons.hourglass_empty : isSuccess ? Icons.check_circle : Icons.cancel,
                    color: hasResult ? Colors.white : accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 18),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              internshipType.toUpperCase(),
                              style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: hasResult
                                  ? LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)])
                                  : null,
                              color: !hasResult ? accentColor.withValues(alpha: 0.1) : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  !hasResult ? Icons.schedule : isSuccess ? Icons.check : Icons.close,
                                  color: hasResult ? Colors.white : accentColor,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  !hasResult ? 'DEĞERLENDİRİLİYOR' : isSuccess ? 'BAŞARILI' : 'BAŞARISIZ',
                                  style: TextStyle(
                                    color: hasResult ? Colors.white : accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        companyName,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 13, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '$startDate  →  $endDate',
                            style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                          ),
                          if (completedAt != '-') ...[
                            const SizedBox(width: 14),
                            Icon(Icons.flag_outlined, size: 13, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Tamamlandı: $completedAt',
                              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Comment box
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.04),
                      purpleGlow.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.format_quote, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Akademisyen Değerlendirmesi',
                              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              academicianName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      comment,
                      style: const TextStyle(fontSize: 14, color: textPrimary, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
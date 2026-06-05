import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import 'ai_analysis_detail_page.dart';

class AcademicianAiAnalysisWeb extends StatefulWidget {
  const AcademicianAiAnalysisWeb({super.key});

  @override
  State<AcademicianAiAnalysisWeb> createState() => _AcademicianAiAnalysisWebState();
}

class _AcademicianAiAnalysisWebState extends State<AcademicianAiAnalysisWeb> {
 
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  final AiService _aiService = AiService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingDocs = [];
  List<Map<String, dynamic>> _completedAnalyses = [];
  String _activeTab = 'pending';
  String _riskFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _hoveredStat = -1;
  int _hoveredItem = -1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final academicianId = Supabase.instance.client.auth.currentUser!.id;
      final results = await Future.wait([
        _aiService.getPendingDocuments(academicianId),
        _aiService.getCompletedAnalyses(academicianId),
      ]);
      if (!mounted) return;
      setState(() {
        _pendingDocs = List<Map<String, dynamic>>.from(results[0]?['pending'] ?? []);
        _completedAnalyses = List<Map<String, dynamic>>.from(results[1]?['completed'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AI listesi yüklenemedi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Stat hesaplamaları =====
  int get _totalCount => _pendingDocs.length + _completedAnalyses.length;
  int get _pendingCount => _pendingDocs.length;
  int get _highRiskCount => _completedAnalyses.where((a) => a['risk_level'] == 'high').length;
  int get _mediumRiskCount => _completedAnalyses.where((a) => a['risk_level'] == 'medium').length;
  int get _lowRiskCount => _completedAnalyses.where((a) => a['risk_level'] == 'low').length;

  List<Map<String, dynamic>> get _filteredAnalyses {
    var list = List<Map<String, dynamic>>.from(_completedAnalyses);

    
    if (_riskFilter != 'all') {
      list = list.where((a) => a['risk_level'] == _riskFilter).toList();
    }

    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final name = (a['student_name'] ?? '').toString().toLowerCase();
        final number = (a['student_number'] ?? '').toString().toLowerCase();
        final company = (a['company_name'] ?? '').toString().toLowerCase();
        return name.contains(q) || number.contains(q) || company.contains(q);
      }).toList();
    }

    return list;
  }

  
  List<Map<String, dynamic>> get _filteredPending {
    var list = List<Map<String, dynamic>>.from(_pendingDocs);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final name = (d['student_name'] ?? '').toString().toLowerCase();
        final number = (d['student_number'] ?? '').toString().toLowerCase();
        final company = (d['company_name'] ?? '').toString().toLowerCase();
        return name.contains(q) || number.contains(q) || company.contains(q);
      }).toList();
    }


    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgCanvas,
        body: Center(child: CircularProgressIndicator(color: purpleGlow)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildStatGrid()),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _buildDonutCard()),
                        ],
                      ),
                      const SizedBox(height: 32),

                      
                      _buildSearchAndSort(),
                      const SizedBox(height: 20),

                      
                      Row(
                        children: [
                          _buildTabSwitcher(),
                          const Spacer(),
                          if (_activeTab == 'completed' && _riskFilter != 'all')
                            _buildActiveFilterChip(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      
                      if (_activeTab == 'pending')
                        _buildPendingList()
                      else
                        _buildCompletedList(),
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
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 100, bottom: -40,
            child: Container(
              width: 160, height: 160,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                                'AI ANALİZ LABORATUVARI',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'AI Analiz Laboratuvarı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Staj defterleri için intihal kontrolü, anlamsal benzerlik analizi ve otomatik özet üretimi.',
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

  // ===== STAT KARTLAR (2x2 grid) =====
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(
              0, Icons.description_outlined, 'Toplam Defter', '$_totalCount', purpleGlow,
              onTap: () => setState(() {
                _activeTab = 'completed';
                _riskFilter = 'all';
              }),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(
              1, Icons.pending_actions_outlined, 'Bekleyen', '$_pendingCount', const Color(0xFFEA580C),
              onTap: () => setState(() => _activeTab = 'pending'),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              2, Icons.warning_amber_rounded, 'Yüksek Risk', '$_highRiskCount', const Color(0xFFDC2626),
              onTap: () => setState(() {
                _activeTab = 'completed';
                _riskFilter = 'high';
              }),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(
              3, Icons.check_circle_outline, 'Düşük Risk', '$_lowRiskCount', const Color(0xFF16A34A),
              onTap: () => setState(() {
                _activeTab = 'completed';
                _riskFilter = 'low';
              }),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(int index, IconData icon, String label, String value, Color accentColor, {VoidCallback? onTap}) {
    final isHovered = _hoveredStat == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStat = index),
      onExit: (_) => setState(() => _hoveredStat = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? accentColor.withValues(alpha: 0.4) : const Color(0xFFEEEEF2),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? accentColor.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.06),
                blurRadius: isHovered ? 28 : 18,
                offset: Offset(0, isHovered ? 12 : 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHovered
                        ? [accentColor, accentColor.withValues(alpha: 0.7)]
                        : [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 21),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== DONUT CHART =====
  Widget _buildDonutCard() {
    final total = _highRiskCount + _mediumRiskCount + _lowRiskCount;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.06),
            blurRadius: 20,
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
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Risk Dağılımı',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Henüz analiz yok', style: TextStyle(fontSize: 13, color: textMuted)),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130, height: 130,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      high: _highRiskCount.toDouble(),
                      medium: _mediumRiskCount.toDouble(),
                      low: _lowRiskCount.toDouble(),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
                          ),
                          const Text(
                            'Toplam',
                            style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(const Color(0xFFDC2626), 'Yüksek', _highRiskCount, total),
                      const SizedBox(height: 10),
                      _buildLegendItem(const Color(0xFFEA580C), 'Orta', _mediumRiskCount, total),
                      const SizedBox(height: 10),
                      _buildLegendItem(const Color(0xFF16A34A), 'Düşük', _lowRiskCount, total),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$count (%$pct)',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===== ARAMA + SIRALAMA BARI =====
  Widget _buildSearchAndSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFEEEEF2)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'İsim, numara veya firma ara...',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.search, color: primaryColor, size: 18),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close, color: textSecondary, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== AKTİF FİLTRE GÖSTERGESİ =====
  Widget _buildActiveFilterChip() {
    final color = _riskColor(_riskFilter);
    final label = _riskLabel(_riskFilter);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            'Filtre: $label',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _riskFilter = 'all'),
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  // ===== SEKME SWITCHER =====
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('pending', Icons.pending_actions_outlined, 'Bekleyen', _pendingCount, const Color(0xFFEA580C)),
          const SizedBox(width: 6),
          _buildTabButton('completed', Icons.fact_check_outlined, 'Analiz Edilen', _completedAnalyses.length, const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, IconData icon, String label, int count, Color accentColor) {
    final isActive = _activeTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() {
          _activeTab = tab;
          if (tab == 'pending') _riskFilter = 'all';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [primaryColor, primaryDark]) : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? Colors.white : accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BEKLEYEN LİSTE =====
  Widget _buildPendingList() {
    final list = _filteredPending;
    if (list.isEmpty) {
      String title, subtitle;
      if (_searchQuery.isNotEmpty) {
        title = 'Eşleşen defter bulunamadı';
        subtitle = 'Farklı bir arama terimi deneyin.';
      } else {
        title = 'Bekleyen defter yok';
        subtitle = 'Tüm öğrencilerinizin defterleri analiz edilmiş 🎉';
      }
      return _buildEmptyState(Icons.check_circle_outline, title, subtitle, const Color(0xFF16A34A));
    }
    return Column(
      children: List.generate(list.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildPendingCard(list[i], i),
        );
      }),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> doc, int index) {
    final isHovered = _hoveredItem == index;
    final studentName = doc['student_name'] ?? 'Bilinmeyen';
    final studentNumber = doc['student_number']?.toString() ?? '-';
    final companyName = doc['company_name'] ?? '-';
    const accentColor = Color(0xFFEA580C);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItem = index),
      onExit: (_) => setState(() => _hoveredItem = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? accentColor.withValues(alpha: 0.4) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? accentColor.withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.05),
              blurRadius: isHovered ? 24 : 16,
              offset: Offset(0, isHovered ? 10 : 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 88,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor, Color(0xFFFB923C)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_empty, color: accentColor, size: 11),
                                    SizedBox(width: 4),
                                    Text(
                                      'ANALİZ BEKLİYOR',
                                      style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 12, color: textMuted),
                              const SizedBox(width: 5),
                              Text('No: $studentNumber', style: const TextStyle(fontSize: 12, color: textSecondary)),
                              const SizedBox(width: 12),
                              Icon(Icons.business_outlined, size: 12, color: textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(fontSize: 12, color: textSecondary),
                                  overflow: TextOverflow.ellipsis,
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
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AiAnalysisDetailPage(
                                documentId: doc['document_id'].toString(),
                                studentName: studentName,
                              ),
                            ),
                          );
                          _loadAllData();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [primaryColor, purpleGlow]),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: isHovered
                                ? [BoxShadow(color: purpleGlow.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              SizedBox(width: 8),
                              Text(
                                'Analize Başlat',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== TAMAMLANAN LİSTE =====
  Widget _buildCompletedList() {
    final list = _filteredAnalyses;
    if (list.isEmpty) {
      String title, subtitle;
      if (_searchQuery.isNotEmpty) {
        title = 'Eşleşen analiz bulunamadı';
        subtitle = 'Farklı bir arama terimi deneyin.';
      } else if (_riskFilter != 'all') {
        title = 'Bu risk seviyesinde analiz yok';
        subtitle = 'Filtreyi kaldırıp tüm analizleri görebilirsiniz.';
      } else {
        title = 'Henüz analiz yapılmadı';
        subtitle = 'Bekleyen sekmesinden bir defter seçip analize başlayabilirsiniz.';
      }
      return _buildEmptyState(Icons.science_outlined, title, subtitle, purpleGlow);
    }
    return Column(
      children: List.generate(list.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildCompletedCard(list[i], i),
        );
      }),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> a, int index) {
    final isHovered = _hoveredItem == index + 1000;
    final studentName = a['student_name'] ?? 'Bilinmeyen';
    final studentNumber = a['student_number']?.toString() ?? '-';
    final companyName = a['company_name'] ?? '-';
    final riskLevel = a['risk_level'] as String?;
    final score = (a['plagiarism_score'] as num?)?.toDouble() ?? 0.0;
    final riskColor = _riskColor(riskLevel);
    final riskLabel = _riskLabel(riskLevel);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItem = index + 1000),
      onExit: (_) => setState(() => _hoveredItem = -1),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiAnalysisDetailPage(
                documentId: a['document_id'].toString(),
                studentName: studentName,
              ),
            ),
          );
          _loadAllData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? riskColor.withValues(alpha: 0.4) : const Color(0xFFEEEEF2),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? riskColor.withValues(alpha: 0.15) : riskColor.withValues(alpha: 0.04),
                blurRadius: isHovered ? 24 : 16,
                offset: Offset(0, isHovered ? 10 : 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [riskColor, riskColor.withValues(alpha: 0.6)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: riskColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5, height: 5,
                                        decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        riskLabel.toUpperCase(),
                                        style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 12, color: textMuted),
                                const SizedBox(width: 5),
                                Text('No: $studentNumber', style: const TextStyle(fontSize: 12, color: textSecondary)),
                                const SizedBox(width: 12),
                                Icon(Icons.business_outlined, size: 12, color: textMuted),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: const TextStyle(fontSize: 12, color: textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '%${(score * 100).toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: riskColor, letterSpacing: -0.5),
                          ),
                          const Text(
                            'Benzerlik',
                            style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.arrow_forward, color: riskColor, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(IconData icon, String title, String subtitle, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accentColor, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===== Yardımcılar =====
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

  String _riskLabel(String? risk) {
    switch (risk) {
      case 'high':
        return 'Yüksek Risk';
      case 'medium':
        return 'Orta Risk';
      case 'low':
        return 'Düşük Risk';
      default:
        return 'Tümü';
    }
  }
}

// ===== DONUT CHART PAINTER =====
class _DonutPainter extends CustomPainter {
  final double high;
  final double medium;
  final double low;

  _DonutPainter({required this.high, required this.medium, required this.low});

  @override
  void paint(Canvas canvas, Size size) {
    final total = high + medium + low;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 18.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;

    void drawArc(double value, Color color) {
      if (value == 0) return;
      final sweep = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    drawArc(high, const Color(0xFFDC2626));
    drawArc(medium, const Color(0xFFEA580C));
    drawArc(low, const Color(0xFF16A34A));
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.high != high ||
      oldDelegate.medium != medium ||
      oldDelegate.low != low;
}
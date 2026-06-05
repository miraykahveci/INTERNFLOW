import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import 'ai_analysis_detail_page.dart';

class AcademicianAiAnalysisMobile extends StatefulWidget {
  const AcademicianAiAnalysisMobile({super.key});

  @override
  State<AcademicianAiAnalysisMobile> createState() => _AcademicianAiAnalysisMobileState();
}

class _AcademicianAiAnalysisMobileState extends State<AcademicianAiAnalysisMobile> {
  // ===== Renk paleti =====
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatGrid(),
                  const SizedBox(height: 16),
                  _buildDonutCard(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildTabSwitcher(),
                  if (_activeTab == 'completed' && _riskFilter != 'all') ...[
                    const SizedBox(height: 12),
                    _buildActiveFilterChip(),
                  ],
                  const SizedBox(height: 16),
                  if (_activeTab == 'pending')
                    _buildPendingList()
                  else
                    _buildCompletedList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HERO HEADER  =====
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'AI ANALİZ',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'AI Analiz Laboratuvarı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Staj defteri intihal kontrolü ve özet üretimi.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== STAT GRID  =====
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(
              Icons.description_outlined, 'Toplam', '$_totalCount', purpleGlow,
              onTap: () => setState(() {
                _activeTab = 'completed';
                _riskFilter = 'all';
              }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              Icons.pending_actions_outlined, 'Bekleyen', '$_pendingCount', const Color(0xFFEA580C),
              onTap: () => setState(() => _activeTab = 'pending'),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              Icons.warning_amber_rounded, 'Yüksek Risk', '$_highRiskCount', const Color(0xFFDC2626),
              onTap: () => setState(() {
                _activeTab = 'completed';
                _riskFilter = 'high';
              }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              Icons.check_circle_outline, 'Düşük Risk', '$_lowRiskCount', const Color(0xFF16A34A),
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

  Widget _buildStatCard(IconData icon, String label, String value, Color accentColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEF2)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accentColor, size: 17),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DONUT CHART KARTI =====
  Widget _buildDonutCard() {
    final total = _highRiskCount + _mediumRiskCount + _lowRiskCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              const Text(
                'Risk Dağılımı',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Henüz analiz yok', style: TextStyle(fontSize: 12, color: textMuted)),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 110, height: 110,
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
                          ),
                          const Text(
                            'Toplam',
                            style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w500),
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
                      const SizedBox(height: 8),
                      _buildLegendItem(const Color(0xFFEA580C), 'Orta', _mediumRiskCount, total),
                      const SizedBox(height: 8),
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
          width: 9, height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$count (%$pct)',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===== ARAMA KUTUSU =====
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(fontSize: 13, color: textPrimary),
        decoration: InputDecoration(
          hintText: 'İsim, numara, firma...',
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
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
    );
  }

  // ===== AKTİF FİLTRE CHIP =====
  Widget _buildActiveFilterChip() {
    final color = _riskColor(_riskFilter);
    final label = _riskLabel(_riskFilter);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_outlined, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            'Filtre: $label',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () => setState(() => _riskFilter = 'all'),
            child: Icon(Icons.close, size: 12, color: color),
          ),
        ],
      ),
    );
  }

  // ===== SEKME SWITCHER =====
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('pending', Icons.pending_actions_outlined, 'Bekleyen', _pendingCount, const Color(0xFFEA580C))),
          const SizedBox(width: 5),
          Expanded(child: _buildTabButton('completed', Icons.fact_check_outlined, 'Edilen', _completedAnalyses.length, const Color(0xFF16A34A))),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, IconData icon, String label, int count, Color accentColor) {
    final isActive = _activeTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() {
          _activeTab = tab;
          if (tab == 'pending') _riskFilter = 'all';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [primaryColor, primaryDark]) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : accentColor, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : accentColor,
                    fontSize: 10,
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
      return _buildEmptyState(
        Icons.check_circle_outline,
        _searchQuery.isNotEmpty ? 'Eşleşen defter yok' : 'Bekleyen defter yok',
        _searchQuery.isNotEmpty ? 'Farklı bir terim deneyin.' : 'Tüm defterler analiz edilmiş 🎉',
        const Color(0xFF16A34A),
      );
    }
    return Column(
      children: List.generate(list.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPendingCard(list[i]),
        );
      }),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> doc) {
    final studentName = doc['student_name'] ?? 'Bilinmeyen';
    final studentNumber = doc['student_number']?.toString() ?? '-';
    final companyName = doc['company_name'] ?? '-';
    const accentColor = Color(0xFFEA580C);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 110,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accentColor, Color(0xFFFB923C)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text(
                            studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty, color: accentColor, size: 9),
                                  SizedBox(width: 3),
                                  Text(
                                    'ANALİZ BEKLİYOR',
                                    style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 11, color: textMuted),
                      const SizedBox(width: 4),
                      Text('No: $studentNumber', style: const TextStyle(fontSize: 11, color: textSecondary)),
                      const SizedBox(width: 10),
                      Icon(Icons.business_outlined, size: 11, color: textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          companyName,
                          style: const TextStyle(fontSize: 11, color: textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
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
                      icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      label: const Text('Analize Başlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purpleGlow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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

  // ===== TAMAMLANAN LİSTE =====
  Widget _buildCompletedList() {
    final list = _filteredAnalyses;
    if (list.isEmpty) {
      String title, subtitle;
      if (_searchQuery.isNotEmpty) {
        title = 'Eşleşen analiz yok';
        subtitle = 'Farklı bir terim deneyin.';
      } else if (_riskFilter != 'all') {
        title = 'Bu seviyede analiz yok';
        subtitle = 'Filtreyi kaldırın.';
      } else {
        title = 'Henüz analiz yok';
        subtitle = 'Bekleyen sekmesinden başlayın.';
      }
      return _buildEmptyState(Icons.science_outlined, title, subtitle, purpleGlow);
    }
    return Column(
      children: List.generate(list.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCompletedCard(list[i]),
        );
      }),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> a) {
    final studentName = a['student_name'] ?? 'Bilinmeyen';
    final studentNumber = a['student_number']?.toString() ?? '-';
    final companyName = a['company_name'] ?? '-';
    final riskLevel = a['risk_level'] as String?;
    final score = (a['plagiarism_score'] as num?)?.toDouble() ?? 0.0;
    final riskColor = _riskColor(riskLevel);
    final riskLabel = _riskLabel(riskLevel);

    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEF2)),
          boxShadow: [
            BoxShadow(
              color: riskColor.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 95,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [riskColor, riskColor.withValues(alpha: 0.6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  riskLabel.toUpperCase(),
                                  style: TextStyle(color: riskColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 10, color: textMuted),
                              const SizedBox(width: 3),
                              Text('No: $studentNumber', style: const TextStyle(fontSize: 10, color: textSecondary)),
                              const SizedBox(width: 8),
                              Icon(Icons.business_outlined, size: 10, color: textMuted),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(fontSize: 10, color: textSecondary),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: riskColor, letterSpacing: -0.5),
                        ),
                        const Text(
                          'Benzerlik',
                          style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Icon(Icons.arrow_forward, color: riskColor, size: 14),
                      ],
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

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(IconData icon, String title, String subtitle, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textSecondary, fontSize: 12),
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
    final radius = math.min(size.width, size.height) / 2 - 5;
    const strokeWidth = 14.0;

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
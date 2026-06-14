import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'academician_student_detail_page.dart';

class AcademicianStudentsWeb extends StatefulWidget {
  const AcademicianStudentsWeb({super.key});

  @override
  State<AcademicianStudentsWeb> createState() => _AcademicianStudentsWebState();
}

class _AcademicianStudentsWebState extends State<AcademicianStudentsWeb> {
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String _activeFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _pendingCount = 0;
  int _activeCount = 0;
  int _completedCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  int _hoveredStat = -1;
  int _hoveredStudent = -1;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final response = await Supabase.instance.client
          .from('internship')
          .select('*, users!internship_student_id_fkey(full_name, student_number, department)')
          .eq('academician_id', userId)
          .order('created_at', ascending: false);

      final allInternships = List<Map<String, dynamic>>.from(response);

      final Map<String, Map<String, dynamic>> uniqueStudents = {};
      for (var intern in allInternships) {
        final studentId = intern['student_id'] as String;
        if (!uniqueStudents.containsKey(studentId)) {
          uniqueStudents[studentId] = intern;
        }
      }

      final students = uniqueStudents.values.toList();
      
      int pending = 0, approved = 0, active = 0, completed = 0, rejected = 0;
      for (var s in students) {
        final status = s['status'];
        final result = s['result'];
        
        if (status == 'completed' && result == 'fail') {
          rejected++;
        } else {
          switch (status) {
            case 'pending': pending++; break;
            case 'approved': approved++; break;
            case 'active': active++; break;
            case 'completed': completed++; break; 
            case 'rejected': rejected++; break;
          }
        }
      }

      setState(() {
        _allStudents = students;
        _pendingCount = pending;
        _approvedCount = approved;
        _activeCount = active;
        _completedCount = completed;
        _rejectedCount = rejected;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Öğrenci listesi yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = _allStudents;

    if (_activeFilter != 'all') {
      result = result.where((s) {
        final status = s['status'];
        final stajResult = s['result'];
        
        if (_activeFilter == 'rejected') {
          return status == 'rejected' || (status == 'completed' && stajResult == 'fail');
        }
        
        if (_activeFilter == 'completed') {
          return status == 'completed' && stajResult != 'fail';
        }

        return status == _activeFilter;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((s) {
        final name = (s['users']?['full_name'] ?? '').toString().toLowerCase();
        final number = (s['users']?['student_number'] ?? '').toString().toLowerCase();
        final company = (s['company_name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || number.contains(query) || company.contains(query);
      }).toList();
    }

    setState(() => _filteredStudents = result);
  }

  Map<String, dynamic> _getStatusInfo(String status, {String? result}) {
    if (status == 'completed' && result == 'fail') {
      return {'label': 'Başarısız', 'color': const Color(0xFFDC2626)};
    }
    
    switch (status) {
      case 'pending':
        return {'label': 'Onay Bekliyor', 'color': const Color(0xFFEA580C)};
      case 'approved':
        return {'label': 'Onaylandı', 'color': const Color(0xFF16A34A)};
      case 'active':
        return {'label': 'Stajda', 'color': const Color(0xFF2563EB)};
      case 'completed':
        return {'label': 'Başarılı', 'color': purpleGlow};
      case 'rejected':
        return {'label': 'Reddedildi', 'color': const Color(0xFFDC2626)};
      default:
        return {'label': status, 'color': textSecondary};
    }
  }

  double _getProgress(String status) {
    switch (status) {
      case 'pending': return 0.2;
      case 'approved': return 0.4;
      case 'active': return 0.7;
      case 'completed': return 1.0;
      default: return 0.0;
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
                      // Stat overview
                      _buildStatCards(),
                      const SizedBox(height: 32),

                      // Search + filters
                      _buildSearchAndFilters(),
                      const SizedBox(height: 28),

                      // Section title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildSectionTitle(
                            _activeFilter == 'all' ? 'Tüm Öğrenciler' : _getStatusInfo(_activeFilter)['label'],
                            '${_filteredStudents.length} öğrenci listeleniyor',
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Student list
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator(color: primaryColor)),
                        )
                      else if (_filteredStudents.isEmpty)
                        _buildEmptyState()
                      else
                        Column(
                          children: List.generate(_filteredStudents.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildStudentCard(_filteredStudents[i], i),
                            );
                          }),
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_outlined, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'ÖĞRENCİ YÖNETİMİ',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Öğrencilerim',
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
                          'Toplam ${_allStudents.length} kayıtlı öğrencinin staj sürecini buradan yönetebilirsiniz.',
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

  // ========== STAT CARDS ==========
  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(0, Icons.people_outline, 'Toplam', '${_allStudents.length}', primaryColor)),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(1, Icons.pending_actions_outlined, 'Onay Bekleyen', '$_pendingCount', const Color(0xFFEA580C))),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(2, Icons.work_outline, 'Aktif Stajyer', '$_activeCount', const Color(0xFF2563EB))),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(3, Icons.check_circle_outline, 'Tamamlanan', '$_completedCount', const Color(0xFF16A34A))),
      ],
    );
  }

  Widget _buildStatCard(int index, IconData icon, String label, String value, Color accentColor) {
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

  // ========== SEARCH + FILTERS ==========
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              style: const TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'İsim, numara veya firma ara...',
                hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.search, color: primaryColor, size: 20),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                        icon: const Icon(Icons.close, color: textSecondary, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all', _allStudents.length, primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('Onay Bekleyen', 'pending', _pendingCount, const Color(0xFFEA580C)),
                const SizedBox(width: 8),
                _buildFilterChip('Onaylanan', 'approved', _approvedCount, const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _buildFilterChip('Stajda', 'active', _activeCount, const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildFilterChip('Tamamlanan', 'completed', _completedCount, purpleGlow),
                const SizedBox(width: 8),
                _buildFilterChip('Reddedilen', 'rejected', _rejectedCount, const Color(0xFFDC2626)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, int count, Color accentColor) {
    final isActive = _activeFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          setState(() => _activeFilter = filter);
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: filter == 'all'
                        ? [primaryColor, primaryDark]
                        : [accentColor, accentColor.withValues(alpha: 0.8)],
                  )
                : null,
            color: !isActive ? const Color(0xFFFAFAFC) : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isActive ? Colors.transparent : const Color(0xFFEEEEF2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (filter == 'all' ? primaryColor : accentColor).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
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

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
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
                colors: [
                  primaryColor.withValues(alpha: 0.1),
                  purpleGlow.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.person_search_outlined, color: primaryColor, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aramanızla eşleşen öğrenci bulunamadı' : 'Bu kategoride öğrenci yok',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty ? 'Farklı bir arama terimi deneyin' : 'Filtre değiştirip tekrar deneyin',
            style: const TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ========== STUDENT CARD ==========
  Widget _buildStudentCard(Map<String, dynamic> internship, int index) {
    final student = internship['users'] as Map<String, dynamic>?;
    final studentName = student?['full_name'] ?? 'Bilinmeyen';
    final studentNumber = student?['student_number']?.toString() ?? '-';
    final department = student?['department'] ?? '-';
    final companyName = internship['company_name'] ?? '-';
    final status = internship['status'] as String? ?? 'pending';
    final stajResult = internship['result'] as String?;
    final statusInfo = _getStatusInfo(status, result: stajResult);
    final progress = _getProgress(status);
    final startDate = internship['start_date'] ?? '';
    final isHovered = _hoveredStudent == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStudent = index),
      onExit: (_) => setState(() => _hoveredStudent = -1),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AcademicianStudentDetailPage(internship: internship),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
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
                color: isHovered ? primaryColor.withValues(alpha: 0.18) : statusInfo['color'].withValues(alpha: 0.05),
                blurRadius: isHovered ? 28 : 18,
                offset: Offset(0, isHovered ? 12 : 6),
              ),
              BoxShadow(
                color: isHovered ? primaryColor.withValues(alpha: 0.08) : purpleGlow.withValues(alpha: 0.03),
                blurRadius: isHovered ? 40 : 26,
                offset: Offset(0, isHovered ? 18 : 10),
              ),
            ],
          ),
          child: Column(
            children: [
              
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                studentName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusInfo['color'].withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      color: statusInfo['color'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusInfo['label'].toString().toUpperCase(),
                                    style: TextStyle(color: statusInfo['color'], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                            Text(
                              'No: $studentNumber',
                              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.school_outlined, size: 12, color: textMuted),
                            const SizedBox(width: 5),
                            Text(
                              department,
                              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Detail button
                  AnimatedContainer(
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
                        Text(
                          'Detay',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Divider
              Container(height: 1, color: const Color(0xFFEEEEF2)),
              const SizedBox(height: 16),

              // Bottom row: company + date + progress
              Row(
                children: [
                  // Company
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_outlined, size: 16, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kurum',
                                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                companyName,
                                style: const TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Date
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: purpleGlow.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today_outlined, size: 14, color: purpleGlow),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Başlangıç',
                                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _formatDate(startDate),
                                style: const TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Progress
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'İlerleme',
                              style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              '%${(progress * 100).toInt()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusInfo['color'],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF4F4F5),
                            valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
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
      ),
    );
  }
}
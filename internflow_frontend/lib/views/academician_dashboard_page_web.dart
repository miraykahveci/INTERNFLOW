import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'academician_students_page.dart';
import 'academician_profile_page.dart';
import 'login_page.dart';
import 'academician_ai_analysis_page.dart';

class AcademicianDashboardWeb extends StatefulWidget {
  const AcademicianDashboardWeb({super.key});

  @override
  State<AcademicianDashboardWeb> createState() => _AcademicianDashboardWebState();
}

class _AcademicianDashboardWebState extends State<AcademicianDashboardWeb> {
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  String _fullName = '';
  String _title = '';
  bool _isLoading = true;

  int _pendingCount = 0;
  int _sgkPendingCount = 0;
  int _activeCount = 0;
  int _totalStudents = 0;
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _pendingItems = [];
  String _activeFilter = 'all';

  int _hoveredStat = -1;
  int _hoveredItem = -1;
  bool _hoveredAiCard = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, title')
          .eq('user_id', userId)
          .single();

      final internships = await Supabase.instance.client
          .from('internship')
          .select('*, users!internship_student_id_fkey(full_name, student_number, department)')
          .eq('academician_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allInternships =
    List<Map<String, dynamic>>.from(internships);


final Map<String, Map<String, dynamic>> uniqueStudents = {};
for (var intern in allInternships) {
  final studentId = intern['student_id'] as String;
  if (!uniqueStudents.containsKey(studentId)) {
    uniqueStudents[studentId] = intern;
  }
}
final uniqueList = uniqueStudents.values.toList();


int pending = 0;
int sgkPending = 0;
int active = 0;
List<Map<String, dynamic>> items = [];

for (var intern in uniqueList) {
  final status = intern['status'] as String;

  if (status == 'pending') {
    pending++;
    items.add({'type': 'pending', 'data': intern});
  } else if (status == 'approved') {
    sgkPending++;
    items.add({'type': 'sgk', 'data': intern});
  } else if (status == 'active') {
    active++;
  }
}

setState(() {
  _fullName = userResponse['full_name'] ?? '';
  _title = userResponse['title'] ?? 'Akademisyen';
  _pendingCount = pending;
  _sgkPendingCount = sgkPending;
  _activeCount = active;
  _totalStudents = uniqueList.length;
  _pendingItems = items;
  _isLoading = false;
});



    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenemedi: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String get _firstName => _fullName.split(' ').first;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await Supabase.instance.client.auth.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_activeFilter == 'all') return _pendingItems;
    return _pendingItems.where((item) => item['type'] == _activeFilter).toList();
  }

  Future<void> _updateInternshipStatus(String internId, String newStatus, {String? reason}) async {
    try {
      await Supabase.instance.client
          .from('internship')
          .update({'status': newStatus})
          .eq('intern_id', internId);

      final intern = _pendingItems.firstWhere(
        (item) => item['data']['intern_id'] == internId,
      );
      final studentId = intern['data']['student_id'];

      String message;
      String type;
      if (newStatus == 'approved') {
        message = 'Staj başvurunuz onaylandı! SGK belgelerinizi yükleyiniz.';
        type = 'success';
      } else {
        message = 'Staj başvurunuz reddedildi. ${reason ?? ''}';
        type = 'error';
      }

      await Supabase.instance.client.from('notifications').insert({
        'user_id': studentId,
        'type': type,
        'message': message,
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved' ? 'Başvuru onaylandı ✅' : 'Başvuru reddedildi ❌'),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> internData) {
    final studentName = internData['users']?['full_name'] ?? 'Öğrenci';
    final studentNumber = internData['users']?['student_number']?.toString() ?? '-';
    final studentDepartment = internData['users']?['department'] ?? '-';
    final companyName = internData['company_name'] ?? '-';
    final internId = internData['intern_id'];
    final rejectReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Başvuru Değerlendirmesi',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.4)),
                          SizedBox(height: 2),
                          Text('Detayları inceleyin ve karar verin',
                              style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Student info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withValues(alpha: 0.04), purpleGlow.withValues(alpha: 0.04)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No: $studentNumber  •  $studentDepartment',
                              style: const TextStyle(color: textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details grid
                _buildDetailGroup('Staj Bilgileri', [
                  _buildDetailRow('Staj Türü', internData['internship_type'] == 'summer' ? 'Yaz Stajı' : 'Dönem İçi'),
                  _buildDetailRow('Tarih Aralığı', '${internData['start_date']} → ${internData['end_date']}'),
                ]),
                const SizedBox(height: 14),
                _buildDetailGroup('Kurum Bilgileri', [
                  _buildDetailRow('Kurum Adı', companyName),
                  _buildDetailRow('Sektör', internData['company_sector'] ?? '-'),
                  _buildDetailRow('Adres', internData['company_address'] ?? '-'),
                  _buildDetailRow('E-posta', internData['company_email'] ?? '-'),
                ]),
                const SizedBox(height: 14),
                _buildDetailGroup('Yetkili & Sigorta', [
                  _buildDetailRow('Yetkili Mühendis', internData['supervisor_name'] ?? '-'),
                  _buildDetailRow('SGK Durumu',
                      internData['has_sgk'] == true ? 'Var (Müstehaklık)' : 'Yok (Okul yapacak)'),
                ]),
                const SizedBox(height: 20),

                // Rejection reason
                TextField(
                  controller: rejectReasonController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Red Gerekçesi (opsiyonel)',
                    hintText: 'Sadece reddetme durumunda doldurunuz...',
                    labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateInternshipStatus(internId, 'rejected', reason: rejectReasonController.text.trim());
                          },
                          icon: const Icon(Icons.close, color: Color(0xFFDC2626)),
                          label: const Text('Reddet', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateInternshipStatus(internId, 'approved');
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 6,
                            shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
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
      ),
    );
  }

  Widget _buildDetailGroup(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
      body: Column(
        children: [
          _buildTopNav(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // ========== TOP NAVIGATION ==========
  Widget _buildTopNav() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEF2), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'InternFlow',
                  style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(width: 60),

            _buildNavItem(0, Icons.dashboard_outlined, 'Ana Sayfa'),
            const SizedBox(width: 8),
            _buildNavItem(1, Icons.people_outlined, 'Öğrenciler'),
            const SizedBox(width: 8),
            _buildNavItem(2, Icons.auto_awesome_outlined, 'AI Analiz'),

            const Spacer(),

            _buildIconButton(Icons.notifications_outlined, () {}),
            const SizedBox(width: 12),

            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => setState(() => _selectedIndex = 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FB),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFEEEEF2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _firstName,
                        style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, color: textSecondary, size: 16),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            _buildIconButton(Icons.logout, _signOut),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FB),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFEEEEF2)),
          ),
          child: Icon(icon, color: textPrimary, size: 19),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [primaryColor, primaryDark]) : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.white : textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 1: return const AcademicianStudentsPage();
      case 2: return const AcademicianAiAnalysisPage();
      case 3: return const AcademicianProfilePage();
      default: return _buildHomeContent();
    }
  }

  // ========== HOME CONTENT ==========
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 36, 40, 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(0, Icons.pending_actions_outlined, 'Bekleyen Başvuru', '$_pendingCount', primaryColor)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(1, Icons.shield_outlined, 'SGK Belgesi', '$_sgkPendingCount', purpleGlow)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(2, Icons.work_outline, 'Aktif Stajyer', '$_activeCount', const Color(0xFF16A34A))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(3, Icons.people_outline, 'Toplam Öğrenci', '$_totalStudents', const Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // AI Analiz banner + filter row
                    _buildAiBanner(),
                    const SizedBox(height: 36),

                    // Section title + filters
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildSectionTitle('Bekleyen İşlemler', 'Onayını bekleyen başvurular ve eksik belgeler')),
                        _buildFilterChip('Tümü', 'all', _pendingItems.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Başvurular', 'pending', _pendingCount),
                        const SizedBox(width: 8),
                        _buildFilterChip('SGK', 'sgk', _sgkPendingCount),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Items list
                    if (_filteredItems.isEmpty)
                      _buildEmptyState()
                    else
                      ...List.generate(_filteredItems.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildPendingItemCard(_filteredItems[i], i),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HERO SECTION ==========
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 56, 40, 56),
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
            right: -80, top: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 100, bottom: -60,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: 40, bottom: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.15), Colors.transparent],
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_outlined, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _title.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${_getGreeting()}, $_firstName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.4,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_pendingCount başvuru ve $_sgkPendingCount SGK belgesi onayınızı bekliyor.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero stats card
                  Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: purpleGlow.withValues(alpha: 0.2),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF5F3FF)]),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.dashboard_customize, color: primaryColor, size: 30),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kontrol Paneli',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalStudents öğrenci yönetiminizde',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildHeroStat('$_pendingCount', 'Onay'),
                                  const SizedBox(width: 16),
                                  _buildHeroStat('$_activeCount', 'Aktif'),
                                ],
                              ),
                            ],
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

  Widget _buildHeroStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ========== STAT CARD ==========
  Widget _buildStatCard(int index, IconData icon, String label, String value, Color accentColor) {
    final isHovered = _hoveredStat == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredStat = index),
      onExit: (_) => setState(() => _hoveredStat = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -8 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.06),
              blurRadius: isHovered ? 32 : 20,
              offset: Offset(0, isHovered ? 14 : 8),
            ),
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.12) : purpleGlow.withValues(alpha: 0.04),
              blurRadius: isHovered ? 48 : 28,
              offset: Offset(0, isHovered ? 20 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46, height: 46,
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
              child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 22),
            ),
            const SizedBox(height: 22),
            Text(
              value,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.8, height: 1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ========== AI BANNER ==========
  Widget _buildAiBanner() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAiCard = true),
      onExit: (_) => setState(() => _hoveredAiCard = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hoveredAiCard ? -4 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                purpleGlow.withValues(alpha: _hoveredAiCard ? 0.08 : 0.05),
                const Color(0xFF2563EB).withValues(alpha: _hoveredAiCard ? 0.08 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hoveredAiCard ? purpleGlow.withValues(alpha: 0.4) : purpleGlow.withValues(alpha: 0.15),
              width: _hoveredAiCard ? 1.5 : 1,
            ),
            boxShadow: _hoveredAiCard
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
                          'AI Analiz Laboratuvarı',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Staj defterleri için intihal kontrolü ve otomatik özet üretimi.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
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

  // ========== FILTER CHIP ==========
  Widget _buildFilterChip(String label, String filter, int count) {
    final isActive = _activeFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [primaryColor, primaryDark]) : null,
            color: !isActive ? Colors.white : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isActive ? Colors.transparent : const Color(0xFFEEEEF2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
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
                  color: isActive ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : primaryColor,
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
                  const Color(0xFF16A34A).withValues(alpha: 0.15),
                  const Color(0xFF16A34A).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bekleyen işlem bulunmuyor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tüm başvurular değerlendirildi 🎉',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ========== PENDING ITEM CARD ==========
  Widget _buildPendingItemCard(Map<String, dynamic> item, int index) {
    final data = item['data'] as Map<String, dynamic>;
    final type = item['type'] as String;
    final studentName = data['users']?['full_name'] ?? 'Bilinmeyen';
    final companyName = data['company_name'] ?? '';
    final createdAt = data['created_at']?.toString().split('T')[0] ?? '';

    final isHovered = _hoveredItem == index;
    final isPending = type == 'pending';

    final accentColor = isPending ? const Color(0xFFEA580C) : purpleGlow;
    final icon = isPending ? Icons.description_outlined : Icons.shield_outlined;
    final subtitle = isPending ? 'Staj Yeri Kabul Formu' : 'SGK Belgesi Bekleniyor';
    final statusLabel = isPending ? 'ONAY BEKLİYOR' : 'BELGE EKSİK';
    final actionLabel = isPending ? 'Değerlendir' : 'Hatırlat';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItem = index),
      onExit: (_) => setState(() => _hoveredItem = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.18) : accentColor.withValues(alpha: 0.05),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                borderRadius: BorderRadius.circular(13),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary, letterSpacing: -0.2),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: accentColor, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
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
                      Icon(Icons.business_outlined, size: 12, color: textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$subtitle  •  $companyName',
                          style: const TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 11, color: textMuted),
                      const SizedBox(width: 5),
                      Text(
                        createdAt,
                        style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () {
                  if (isPending) _showApprovalDialog(data);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                  child: Row(
                    children: [
                      Icon(isPending ? Icons.gavel_outlined : Icons.notifications_active_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        actionLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
}


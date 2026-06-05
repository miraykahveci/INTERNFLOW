import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'application_form_page.dart';
import 'student_process_page.dart';
import 'student_files_page.dart';
import 'student_profile_page.dart';
import 'login_page.dart';
import 'student_results_page.dart';

class StudentDashboardWeb extends StatefulWidget {
  const StudentDashboardWeb({super.key});

  @override
  State<StudentDashboardWeb> createState() => _StudentDashboardWebState();
}

class _StudentDashboardWebState extends State<StudentDashboardWeb> {
  
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color primaryLight = Color(0xFF8B1818);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  int _selectedIndex = 0;
  int _hoveredStat = -1;
  int _hoveredDoc = -1;
  int _hoveredAnnouncement = -1;

  bool _hoveredApplication = false;
  bool _hoveredRoadmap = false;
  bool _hoveredHeroCard = false;

  String _fullName = '';
  String _department = '';
  bool _isLoading = true;

  Map<String, dynamic>? _internshipData;
  String _internshipStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _downloadTemplate(String fileName) async {
    final url = '${Supabase.instance.client.rest.url.replaceAll('/rest/v1', '')}/storage/v1/object/public/templates/$fileName';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, department')
          .eq('user_id', userId)
          .single();

      final internshipResponse = await Supabase.instance.client
          .from('internship')
          .select()
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _fullName = userResponse['full_name'] ?? '';
        _department = userResponse['department'] ?? '';
        _internshipData = internshipResponse;
        _internshipStatus = internshipResponse?['status'] ?? 'none';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Map<String, dynamic> _getStatusInfo() {
    switch (_internshipStatus) {
      case 'pending':
        return {'label': 'Onay Bekliyor', 'color': const Color(0xFFEA580C)};
      case 'approved':
        return {'label': 'Onaylandı', 'color': const Color(0xFF16A34A)};
      case 'active':
        return {'label': 'Stajda', 'color': const Color(0xFF2563EB)};
      case 'completed':
        return {'label': 'Tamamlandı', 'color': const Color(0xFF7C3AED)};
      case 'rejected':
        return {'label': 'Reddedildi', 'color': const Color(0xFFDC2626)};
      default:
        return {'label': 'Başvuru Yok', 'color': textSecondary};
    }
  }

  int _getStepCount() {
    switch (_internshipStatus) {
      case 'pending': return 1;
      case 'approved': return 2;
      case 'active': return 4;
      case 'completed': return 5;
      default: return 0;
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
            // Logo
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 60),

            // Menu items
            _buildNavItem(0, Icons.home_outlined, 'Ana Sayfa'),
            const SizedBox(width: 8),
            _buildNavItem(1, Icons.timeline_outlined, 'Sürecim'),
            const SizedBox(width: 8),
            _buildNavItem(2, Icons.folder_outlined, 'Dosyalar'),
            const SizedBox(width: 8),
            _buildNavItem(3, Icons.emoji_events_outlined, 'Sonuçlarım'),
            const Spacer(),

            
            _buildIconButton(Icons.notifications_outlined, () {}),
            const SizedBox(width: 12),

            // User profile 
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => setState(() => _selectedIndex = 4),
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

            // Logout
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
            gradient: isActive
                ? const LinearGradient(colors: [primaryColor, primaryDark])
                : null,
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
              Icon(
                icon,
                color: isActive ? Colors.white : textSecondary,
                size: 18,
              ),
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
      case 1: return const StudentProcessPage();
      case 2: return const StudentFilesPage();
      case 3: return const StudentResultsPage();
      case 4: return const StudentProfilePage();
      default: return _buildHomeContent();
    }
  }

  // ========== HOME ==========
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),

          // CONTENT (centered)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 36, 40, 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(0, Icons.assignment_outlined, 'Aktif Başvuru', _internshipStatus == 'none' ? '0' : '1', primaryColor)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(1, Icons.timeline_outlined, 'Süreç Adımı', '${_getStepCount()}/5', purpleGlow)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(2, Icons.description_outlined, 'Belge Şablonu', '4', const Color(0xFF2563EB))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard(3, Icons.school_outlined, 'Bölüm', _department.length > 12 ? '${_department.substring(0, 12)}...' : (_department.isNotEmpty ? _department : 'Bilg. Müh.'), const Color(0xFF16A34A))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: _buildApplicationCard()),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: _buildRoadmapCard()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),

                    _buildSectionTitle('Belge Şablonları', 'İndirilebilir formlar ve resmi belgeler'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildDocCard(0, Icons.book_outlined, 'Staj Defteri', 'PDF Şablon', primaryColor, () => _downloadTemplate('staj_gunlugu.pdf'))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDocCard(1, Icons.description_outlined, 'Kabul Formu', 'PDF Şablon', const Color(0xFF2563EB), () => _downloadTemplate('kabul_formu.pdf'))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDocCard(2, Icons.assignment_outlined, 'Sicil Fişi', 'PDF Şablon', const Color(0xFFC62828), () => _downloadTemplate('staj_sicil.pdf'))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDocCard(3, Icons.shield_outlined, 'Sigorta', 'Bilgi Sayfası', const Color(0xFF16A34A), () => setState(() => _selectedIndex = 2))),
                      ],
                    ),
                    const SizedBox(height: 44),

                    _buildSectionTitle('Duyurular', 'Güncel staj bildirimleri ve önemli tarihler'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildAnnouncementCard(0, Icons.campaign_outlined, '2026 Yaz Stajı', 'Başvurular 6 Temmuz\'da sona erecektir. Bu tarihten önce staja başlayamazsınız.', const Color(0xFF2563EB))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildAnnouncementCard(1, Icons.shield_outlined, 'SGK Bilgilendirmesi', 'Staj başlamadan önce SGK girişinizin yapılmış olması gerekmektedir.', const Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HERO CARD ==========
  Widget _buildHeroSection() {
    final statusInfo = _getStatusInfo();
    final isRejected = _internshipStatus == 'rejected';

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
          // Decorative orbs
          Positioned(
            right: -80, top: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    purpleGlow.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
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
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
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
                  colors: [
                    purpleGlow.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
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
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: statusInfo['color'] == textSecondary ? Colors.white : statusInfo['color'],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (statusInfo['color'] == textSecondary ? Colors.white : statusInfo['color'] as Color).withValues(alpha: 0.6),
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
                          'Staj sürecini buradan kolayca takip edebilirsin.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            _buildHeroChip(Icons.school, _department.isNotEmpty ? _department : 'Bilgisayar Mühendisliği'),
                            const SizedBox(width: 12),
                            _buildHeroChip(Icons.calendar_today, '2025-2026 Bahar'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hero progress card 
                  MouseRegion(
                    onEnter: (_) => setState(() => _hoveredHeroCard = true),
                    onExit: (_) => setState(() => _hoveredHeroCard = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(0, _hoveredHeroCard ? -6 : 0, 0),
                      width: 380,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: _hoveredHeroCard ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: _hoveredHeroCard ? 0.4 : 0.2),
                          width: _hoveredHeroCard ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isRejected ? const Color(0xFFDC2626) : purpleGlow)
                                .withValues(alpha: _hoveredHeroCard ? 0.4 : 0.2),
                            blurRadius: _hoveredHeroCard ? 40 : 32,
                            offset: Offset(0, _hoveredHeroCard ? 16 : 12),
                          ),
                          if (_hoveredHeroCard)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: isRejected
                          ? _buildHeroRejectedContent()
                          : _buildHeroProgressContent(),
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

  // ========== HERO PROGRESS CONTENT  ==========
  Widget _buildHeroProgressContent() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF5F3FF)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hoveredHeroCard ? 0.25 : 0.15),
                blurRadius: _hoveredHeroCard ? 24 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.rocket_launch, color: primaryColor, size: 30),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Staj Yolculuğun',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              Text(
                '${_getStepCount()} / 5 Adım',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _getStepCount() / 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '%${(_getStepCount() / 5 * 100).toInt()} Tamamlandı',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== HERO REJECTED CONTENT ==========
  Widget _buildHeroRejectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                    blurRadius: _hoveredHeroCard ? 24 : 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Başvurun Reddedildi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Yeni bir başvuru oluşturarak\nsüreci yeniden başlatabilirsin.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApplicationFormPage()),
              );
              if (result == true) _loadAllData();
            },
            icon: const Icon(Icons.add, size: 16, color: primaryColor),
            label: const Text(
              'Yeni Başvuru Yap',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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

  // ========== STAT CARD WITH HOVER ==========
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
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.25)
                  : accentColor.withValues(alpha: 0.06),
              blurRadius: isHovered ? 32 : 20,
              offset: Offset(0, isHovered ? 14 : 8),
            ),
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.12)
                  : purpleGlow.withValues(alpha: 0.04),
              blurRadius: isHovered ? 48 : 28,
              offset: Offset(0, isHovered ? 20 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Icon(
                    icon,
                    color: isHovered ? Colors.white : accentColor,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.8,
                height: 1,
              ),
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

  // ========== APPLICATION CARD WITH HOVER ==========
  Widget _buildApplicationCard() {
    final statusInfo = _getStatusInfo();
    final isEmpty = _internshipStatus == 'none' || _internshipStatus == 'rejected';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredApplication = true),
      onExit: (_) => setState(() => _hoveredApplication = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hoveredApplication ? -6 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hoveredApplication ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: _hoveredApplication ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hoveredApplication
                  ? primaryColor.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.06),
              blurRadius: _hoveredApplication ? 32 : 24,
              offset: Offset(0, _hoveredApplication ? 14 : 8),
            ),
            BoxShadow(
              color: _hoveredApplication
                  ? primaryColor.withValues(alpha: 0.1)
                  : purpleGlow.withValues(alpha: 0.04),
              blurRadius: _hoveredApplication ? 48 : 32,
              offset: Offset(0, _hoveredApplication ? 20 : 12),
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
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Staj Başvurun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.4)),
                      SizedBox(height: 2),
                      Text('Başvuru süreç bilgileri', style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
                if (!isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      statusInfo['label'],
                      style: TextStyle(color: statusInfo['color'], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            if (isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.inbox_outlined, size: 32, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz aktif başvurun yok',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Staj sürecini başlatmak için yeni bir başvuru oluştur',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplicationFormPage()));
                    if (result == true) _loadAllData();
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Yeni Başvuru Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 8,
                    shadowColor: primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFAFAFC), Color(0xFFF8F7FB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.business_outlined, size: 20, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _internshipData?['company_name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                              ),
                              const SizedBox(height: 2),
                              const Text('Staj Kurumu', style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: const Color(0xFFEEEEF2),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          '${_internshipData?['start_date'] ?? ''}  →  ${_internshipData?['end_date'] ?? ''}',
                          style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  icon: const Icon(Icons.timeline_outlined, color: Colors.white, size: 18),
                  label: const Text('Süreci Görüntüle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 8,
                    shadowColor: primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== ROADMAP CARD WITH HOVER ==========
  Widget _buildRoadmapCard() {
    final steps = [
      {'title': 'Başvuru Oluştur', 'icon': Icons.edit_note},
      {'title': 'Akademisyen Onayı', 'icon': Icons.person_search},
      {'title': 'SGK / Sigorta', 'icon': Icons.security},
      {'title': 'Staj Dönemi', 'icon': Icons.work_history},
      {'title': 'Defter & AI Analiz', 'icon': Icons.auto_awesome},
    ];
    final currentStep = _getStepCount();

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRoadmap = true),
      onExit: (_) => setState(() => _hoveredRoadmap = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hoveredRoadmap ? -6 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hoveredRoadmap ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: _hoveredRoadmap ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hoveredRoadmap
                  ? primaryColor.withValues(alpha: 0.2)
                  : purpleGlow.withValues(alpha: 0.08),
              blurRadius: _hoveredRoadmap ? 32 : 24,
              offset: Offset(0, _hoveredRoadmap ? 14 : 8),
            ),
            BoxShadow(
              color: _hoveredRoadmap
                  ? primaryColor.withValues(alpha: 0.1)
                  : primaryColor.withValues(alpha: 0.04),
              blurRadius: _hoveredRoadmap ? 48 : 32,
              offset: Offset(0, _hoveredRoadmap ? 20 : 12),
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
                    gradient: LinearGradient(colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: purpleGlow.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.route, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yol Haritası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.4)),
                      SizedBox(height: 2),
                      Text('Staj sürecindeki adımların', style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            ...List.generate(steps.length, (i) {
              final isCompleted = i < currentStep;
              final isCurrent = i == currentStep;
              final isLast = i == steps.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)])
                            : isCurrent
                                ? const LinearGradient(colors: [primaryColor, primaryDark])
                                : null,
                        color: !isCompleted && !isCurrent ? const Color(0xFFF4F4F5) : null,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isCompleted || isCurrent
                            ? [
                                BoxShadow(
                                  color: (isCompleted ? const Color(0xFF16A34A) : primaryColor).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Icon(
                                steps[i]['icon'] as IconData,
                                color: isCurrent ? Colors.white : textMuted,
                                size: 18,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        steps[i]['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted || isCurrent ? textPrimary : textMuted,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Şu an',
                          style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            }),
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.6),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: textSecondary),
        ),
      ],
    );
  }

  // ========== DOC CARD WITH HOVER ==========
  Widget _buildDocCard(int index, IconData icon, String title, String type, Color accentColor, VoidCallback onTap) {
    final isHovered = _hoveredDoc == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredDoc = index),
      onExit: (_) => setState(() => _hoveredDoc = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isHovered ? -8 : 0, 0),
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
                color: isHovered
                    ? primaryColor.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.06),
                blurRadius: isHovered ? 28 : 18,
                offset: Offset(0, isHovered ? 12 : 6),
              ),
              BoxShadow(
                color: isHovered
                    ? primaryColor.withValues(alpha: 0.1)
                    : purpleGlow.withValues(alpha: 0.03),
                blurRadius: isHovered ? 40 : 26,
                offset: Offset(0, isHovered ? 18 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHovered
                        ? [accentColor, accentColor.withValues(alpha: 0.7)]
                        : [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
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
                child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 24),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Text(type, style: const TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 12, color: accentColor),
                    const SizedBox(width: 4),
                    Text('İndir', style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== ANNOUNCEMENT CARD WITH HOVER ==========
  Widget _buildAnnouncementCard(int index, IconData icon, String title, String description, Color accentColor) {
    final isHovered = _hoveredAnnouncement == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAnnouncement = index),
      onExit: (_) => setState(() => _hoveredAnnouncement = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
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
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.2)
                  : accentColor.withValues(alpha: 0.06),
              blurRadius: isHovered ? 28 : 18,
              offset: Offset(0, isHovered ? 12 : 6),
            ),
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.1)
                  : purpleGlow.withValues(alpha: 0.03),
              blurRadius: isHovered ? 40 : 26,
              offset: Offset(0, isHovered ? 18 : 10),
            ),
          ],
        ),
        child: Row(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
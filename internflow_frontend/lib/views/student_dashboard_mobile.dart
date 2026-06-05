import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'application_form_page.dart';
import 'student_process_page.dart';
import 'student_profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_files_page.dart';
import 'student_results_page.dart';

class StudentDashboardMobile extends StatefulWidget {
  const StudentDashboardMobile({super.key});

  @override
  State<StudentDashboardMobile> createState() => _StudentDashboardMobileState();
}

class _StudentDashboardMobileState extends State<StudentDashboardMobile> {
  
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color textSecondary = Color(0xFF64748B);

  int _selectedIndex = 0;
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
    final url =
        '${Supabase.instance.client.rest.url.replaceAll('/rest/v1', '')}/storage/v1/object/public/templates/$fileName';
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const StudentProcessPage();
      case 2:
        return const StudentFilesPage();
      case 3:
      return const StudentResultsPage();
       case 4:
      return const StudentProfilePage();
      default:
        return _buildHomeContent();
    }
  }


  bool _isStepCompleted(int step) {
    switch (step) {
      case 1:
        return _internshipStatus != 'none';
      case 2:
        return ['approved', 'active', 'completed'].contains(_internshipStatus);
      case 3:
        return ['active', 'completed'].contains(_internshipStatus);
      default:
        return false;
    }
  }

  bool _isCurrentStep(int step) {
    switch (step) {
      case 1:
        return _internshipStatus == 'none';
      case 2:
        return _internshipStatus == 'pending';
      case 3:
        return _internshipStatus == 'approved';
      default:
        return false;
    }
  }

  String _getStatusText() {
    switch (_internshipStatus) {
      case 'pending':
        return 'Başvurunuz danışman onayı bekliyor...';
      case 'approved':
        return 'Başvurunuz onaylandı! SGK belgelerinizi yükleyiniz.';
      case 'rejected':
        return 'Başvurunuz reddedildi. Yeni başvuru yapabilirsiniz.';
      case 'active':
        return 'Stajınız aktif olarak devam ediyor.';
      case 'completed':
        return 'Staj süreciniz tamamlandı.';
      default:
        return '';
    }
  }

  Color _getStatusColor() {
    switch (_internshipStatus) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'active':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_internshipStatus) {
      case 'pending':
        return Icons.hourglass_top;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'active':
        return Icons.work;
      case 'completed':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      body: _getSelectedPage(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: const Color(0xFFBDBDBD),
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: const [
            BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
           BottomNavigationBarItem(
           icon: Icon(Icons.timeline_outlined),
           activeIcon: Icon(Icons.timeline),
           label: 'Sürecim',
           ),
          BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Dosyalar',
         ),
         BottomNavigationBarItem(
         icon: Icon(Icons.emoji_events_outlined),
        activeIcon: Icon(Icons.emoji_events),
         label: 'Sonuçlar',
        ),
          BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
       ],
          ),
        ),
      ),
    );
  }

  // ========== ANA İÇERİK ==========
  Widget _buildHomeContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroHeader(),
          _buildHeroProgressCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildApplicationCard(),
                const SizedBox(height: 28),

                _buildSectionHeader('Staj Yol Haritası', Icons.route),
                const SizedBox(height: 14),
                _buildRoadmapCard(),
                const SizedBox(height: 28),

                _buildSectionHeader('Belge Şablonları', Icons.file_copy),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDocumentCard(
                        icon: Icons.book,
                        title: 'Staj Defteri',
                        subtitle: 'PDF',
                        color: primaryColor,
                        bgColor: const Color(0xFFFBE9E7),
                        onTap: () => _downloadTemplate('staj_gunlugu.pdf'),
                      ),
                      _buildDocumentCard(
                        icon: Icons.description,
                        title: 'Kabul Formu',
                        subtitle: 'PDF',
                        color: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFE3F2FD),
                        onTap: () => _downloadTemplate('kabul_formu.pdf'),
                      ),
                      _buildDocumentCard(
                        icon: Icons.shield,
                        title: 'Sigorta',
                        subtitle: 'Bilgi',
                        color: const Color(0xFF2E7D32),
                        bgColor: const Color(0xFFE8F5E9),
                        onTap: () => _onItemTapped(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _buildSectionHeader('Duyurular', Icons.campaign),
                const SizedBox(height: 10),
                _buildAnnouncementCard(),
                const SizedBox(height: 12),
                _buildSgkAnnouncementCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== HERO HEADER  ==========
  Widget _buildHeroHeader() {
    final statusInfo = _getStatusInfo();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          
          Positioned(
            right: -50, top: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 60, bottom: -30,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),

          // İçerik
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: status rozeti + bildirim ikonu
              Row(
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
                            color: statusInfo['color'] == textSecondary
                                ? Colors.white
                                : statusInfo['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          statusInfo['label'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              
              Text(
                '${_getGreeting()}, $_firstName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Staj sürecini buradan kolayca takip edebilirsin.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              
              Row(
                children: [
                  _buildHeroChip(
                    Icons.school,
                    _department.isNotEmpty
                        ? (_department.length > 18
                            ? '${_department.substring(0, 18)}...'
                            : _department)
                        : 'Bölüm',
                  ),
                  const SizedBox(width: 8),
                  _buildHeroChip(Icons.calendar_today, '2025-2026'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========== HERO PROGRESS CARD  ==========
  Widget _buildHeroProgressCard() {
    final stepCount = _getStepCount();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryDark],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: purpleGlow.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // REDDEDİLME DURUMU KONTROLÜ
        child: _internshipStatus == 'rejected'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Başvurun Reddedildi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mevcut başvurun onaylanmadı. Sayfanın altından yeni bir başvuru oluşturabilirsin.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              )
            
            : Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF5F3FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch, color: primaryColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staj Yolculuğun',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$stepCount / 5 Adım',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: stepCount / 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '%${(stepCount / 5 * 100).toInt()} Tamamlandı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== BÖLÜM BAŞLIĞI ==========
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2E),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ========== BAŞVURU KARTI ==========
  Widget _buildApplicationCard() {
    if (_internshipStatus == 'none' || _internshipStatus == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_internshipStatus == 'rejected')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Önceki başvurunuz reddedildi. Yeni başvuru yapabilirsiniz.',
                        style: TextStyle(color: Color(0xFFC62828), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yeni Staj Başlat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Staj sürecini başlatmak için başvurunu oluştur.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApplicationFormPage()),
                  );
                  if (result == true) _loadAllData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Başvuru Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Formu gönderdikten sonra düzenleme yapılamaz.', style: TextStyle(color: Color(0xFFC0C0C0), fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _internshipData?['company_name'] ?? '',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2E), letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _internshipStatus == 'pending'
                                  ? 'ONAY BEKLİYOR'
                                  : _internshipStatus == 'approved'
                                      ? 'ONAYLANDI'
                                      : _internshipStatus.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor().withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: _getStatusColor()),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_getStatusText(), style: TextStyle(color: _getStatusColor(), fontSize: 12))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_internshipData != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: Color(0xFF90A4AE)),
                  const SizedBox(width: 6),
                  Text(
                    '${_internshipData!['start_date']} — ${_internshipData!['end_date']}',
                    style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Row(
                      children: [
                        Text('Süreci Gör', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========== YOL HARİTASI KARTI ==========
  Widget _buildRoadmapCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRoadmapStep(1, 'Başvuru Oluştur', Icons.edit_note),
          _buildRoadmapLine(1),
          _buildRoadmapStep(2, 'Akademisyen Onayı', Icons.person_search),
          _buildRoadmapLine(2),
          _buildRoadmapStep(3, 'SGK / Sigorta', Icons.security),
          _buildRoadmapLine(3),
          _buildRoadmapStep(4, 'Staj Dönemi', Icons.work_history),
          _buildRoadmapLine(4),
          _buildRoadmapStep(5, 'Defter & AI Analiz', Icons.auto_awesome),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep(int step, String text, IconData icon) {
    final completed = _isStepCompleted(step);
    final current = _isCurrentStep(step);
    final locked = !completed && !current;

    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: completed
                ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)])
                : current
                    ? const LinearGradient(colors: [primaryColor, primaryDark])
                    : null,
            color: locked ? const Color(0xFFF0F0F0) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: (completed || current)
                ? [
                    BoxShadow(
                      color: (completed ? const Color(0xFF2E7D32) : primaryColor).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            completed ? Icons.check_rounded : icon,
            color: locked ? const Color(0xFFBDBDBD) : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: (completed || current) ? FontWeight.w600 : FontWeight.w400,
              color: completed
                  ? const Color(0xFF2E7D32)
                  : current
                      ? primaryColor
                      : const Color(0xFFBDBDBD),
            ),
          ),
        ),
        if (current)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Şu an', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        if (completed)
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 14),
          ),
        if (locked)
          const Icon(Icons.lock_outline, color: Color(0xFFE0E0E0), size: 18),
      ],
    );
  }

  Widget _buildRoadmapLine(int step) {
    final completed = _isStepCompleted(step) && _isStepCompleted(step + 1 > 3 ? step : step + 1);
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 20,
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFA5D6A7) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ========== BELGE ŞABLONU KARTI ==========
  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2E))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  // ========== DUYURU KARTLARI ==========
  Widget _buildAnnouncementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3F2FD)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2026 Yaz Stajı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
                SizedBox(height: 4),
                Text(
                  'Başvurular 6 Temmuz\'da sona erecektir. Bu tarihten önce staja başlayamazsınız.',
                  style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF90CAF9)),
        ],
      ),
    );
  }

  Widget _buildSgkAnnouncementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.new_releases, color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SGK Bilgilendirmesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
                SizedBox(height: 4),
                Text(
                  'Staj başlamadan önce SGK girişinizin yapılmış olması gerekmektedir. Detaylar için Dosyalar sekmesini inceleyiniz.',
                  style: TextStyle(color: Color(0xFF81C784), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA5D6A7)),
        ],
      ),
    );
  }
}
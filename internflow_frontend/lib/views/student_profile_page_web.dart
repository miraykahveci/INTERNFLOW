import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

class StudentProfileWeb extends StatefulWidget {
  const StudentProfileWeb({super.key});

  @override
  State<StudentProfileWeb> createState() => _StudentProfileWebState();
}

class _StudentProfileWebState extends State<StudentProfileWeb> {
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
  String _fullName = '';
  String _department = '';
  String _email = '';
  String _internshipStatus = 'none';

  int _hoveredStat = -1;
  int _hoveredBadge = -1;
  int _hoveredMenu = -1;
  bool _hoveredLogout = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final email = Supabase.instance.client.auth.currentUser!.email ?? '';

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, department')
          .eq('user_id', userId)
          .single();

      final internshipResponse = await Supabase.instance.client
          .from('internship')
          .select('status')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _fullName = userResponse['full_name'] ?? 'Öğrenci';
        _department = userResponse['department'] ?? 'Bölüm Bilgisi Yok';
        _email = email;
        _internshipStatus = internshipResponse?['status'] ?? 'none';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profil verisi çekilemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_internshipStatus) {
      case 'pending':
        return {'label': 'Onay Bekliyor', 'color': const Color(0xFFEA580C)};
      case 'approved':
        return {'label': 'Belge Bekleniyor', 'color': const Color(0xFFFBC02D)};
      case 'active':
        return {'label': 'Stajda', 'color': const Color(0xFF16A34A)};
      case 'completed':
        return {'label': 'Tamamlandı', 'color': const Color(0xFF2563EB)};
      case 'rejected':
        return {'label': 'Reddedildi', 'color': const Color(0xFFDC2626)};
      default:
        return {'label': 'Başvuru Bekleniyor', 'color': textSecondary};
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await Supabase.instance.client.auth.signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showKvkkModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Gizlilik ve KVKK',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'InternFlow, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında kişisel verilerinizi koruma altına almaktadır.',
                style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Kişisel verileriniz yalnızca staj süreç yönetimi amacıyla işlenmektedir.\n'
                '• Verileriniz üçüncü taraflarla paylaşılmamaktadır.\n'
                '• Staj defterlerindeki kişisel bilgiler AI analizinden önce maskelenmektedir.\n'
                '• Tüm veri iletişimi HTTPS protokolü üzerinden şifreli olarak gerçekleşmektedir.\n'
                '• Verilerinizin silinmesini talep etme hakkınız saklıdır.',
                style: TextStyle(fontSize: 12, height: 1.8, color: textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: const Text('Anladım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(0, Icons.assignment_outlined, '1/2', 'Staj Sayısı', primaryColor)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(1, Icons.calendar_month_outlined, '20', 'İş Günü', purpleGlow)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(2, Icons.trending_up, '%85', 'Başarı Oranı', const Color(0xFF16A34A))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(3, Icons.school_outlined, '3.20', 'GANO', const Color(0xFF2563EB))),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 2-column layout
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LEFT: Profile info + Badges
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _buildProfileInfoCard(),
                                  const SizedBox(height: 20),
                                  _buildBadgesCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // RIGHT: Settings
                            Expanded(
                              flex: 7,
                              child: _buildSettingsCard(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout
                      _buildLogoutCard(),
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
                  // Avatar
                  Stack(
                    children: [
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
                            _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [purpleGlow, purpleGlow.withValues(alpha: 0.7)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
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
                                  color: statusInfo['color'] == textSecondary ? Colors.white : statusInfo['color'],
                                  shape: BoxShape.circle,
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
                        const SizedBox(height: 12),
                        Text(
                          _fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildHeroChip(Icons.school, _department),
                            const SizedBox(width: 10),
                            if (_email.isNotEmpty) _buildHeroChip(Icons.email_outlined, _email),
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

  // ========== STAT CARD WITH HOVER ==========
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
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.2)
                  : accentColor.withValues(alpha: 0.06),
              blurRadius: isHovered ? 28 : 20,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.1)
                  : purpleGlow.withValues(alpha: 0.04),
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.7,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ========== PROFILE INFO CARD ==========
  Widget _buildProfileInfoCard() {
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
                child: const Icon(Icons.badge_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hesap Bilgileri', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Kişisel ve akademik detaylar', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildInfoRow(Icons.person_outline, 'Ad Soyad', _fullName),
          _buildInfoDivider(),
          _buildInfoRow(Icons.school_outlined, 'Bölüm', _department),
          _buildInfoDivider(),
          _buildInfoRow(Icons.email_outlined, 'E-posta', _email.isNotEmpty ? _email : 'Belirtilmemiş'),
          _buildInfoDivider(),
          _buildInfoRow(Icons.calendar_today_outlined, 'Akademik Yıl', '2025-2026 Bahar'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 14),
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
                  style: const TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFEEEEF2),
    );
  }

  // ========== BADGES CARD ==========
  Widget _buildBadgesCard() {
    final badges = [
      {
        'icon': Icons.star,
        'title': 'İlk Adım',
        'subtitle': 'Başvuru tamamlandı',
        'color': const Color(0xFFFBC02D),
        'isActive': _internshipStatus != 'none',
      },
      {
        'icon': Icons.work,
        'title': 'Stajyer',
        'subtitle': 'Süreç aktif',
        'color': const Color(0xFF2563EB),
        'isActive': _internshipStatus == 'active' || _internshipStatus == 'completed',
      },
      {
        'icon': Icons.school,
        'title': 'Mezun Adayı',
        'subtitle': 'Belgeler bekleniyor',
        'color': purpleGlow,
        'isActive': _internshipStatus == 'completed',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.04),
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
                child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kariyer Rozetleri', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Staj sürecinde kazandıkların', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: List.generate(badges.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < badges.length - 1 ? 12 : 0),
                  child: _buildBadge(i, badges[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int index, Map<String, dynamic> badge) {
    final isActive = badge['isActive'] as bool;
    final isHovered = _hoveredBadge == index && isActive;
    final color = badge['color'] as Color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredBadge = index),
      onExit: (_) => setState(() => _hoveredBadge = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? cardBg : const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isHovered ? color.withValues(alpha: 0.4) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isHovered ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05),
                    blurRadius: isHovered ? 20 : 12,
                    offset: Offset(0, isHovered ? 8 : 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                    : null,
                color: !isActive ? const Color(0xFFF4F4F5) : null,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge['icon'] as IconData,
                color: isActive ? Colors.white : textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge['title'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? textPrimary : textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              badge['subtitle'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SETTINGS CARD ==========
  Widget _buildSettingsCard() {
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
                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ayarlar ve Bilgiler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Hesabını yönet ve gizliliğini koru', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section: Hesap
          _buildSectionLabel('HESAP BİLGİLERİ'),
          const SizedBox(height: 10),
          _buildMenuTile(0, Icons.history, 'Staj Geçmişi', 'Önceki başvurularını görüntüle', () {}),
          const SizedBox(height: 10),

          _buildSectionLabel('UYGULAMA AYARLARI'),
          const SizedBox(height: 10),
          _buildMenuTile(1, Icons.notifications_outlined, 'Bildirim Ayarları', 'E-posta ve uygulama bildirimleri', () {}),
          const SizedBox(height: 10),
          _buildMenuTile(2, Icons.shield_outlined, 'Gizlilik ve KVKK', 'Veri işleme politikası', _showKvkkModal),
          const SizedBox(height: 10),
          _buildMenuTile(3, Icons.account_balance_outlined, 'E-Devlet Kapısı', 'Resmi belge işlemleri', () async {
            final uri = Uri.parse('https://giris.turkiye.gov.tr/Giris/');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildMenuTile(int index, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isHovered = _hoveredMenu == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredMenu = index),
      onExit: (_) => setState(() => _hoveredMenu = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHovered ? primaryColor.withValues(alpha: 0.04) : const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isHovered ? primaryColor.withValues(alpha: 0.2) : const Color(0xFFEEEEF2),
              width: isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: isHovered
                      ? const LinearGradient(colors: [primaryColor, primaryDark])
                      : null,
                  color: !isHovered ? primaryColor.withValues(alpha: 0.08) : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: isHovered ? Colors.white : primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: isHovered ? primaryColor : textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ========== LOGOUT CARD ==========
  Widget _buildLogoutCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLogout = true),
      onExit: (_) => setState(() => _hoveredLogout = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hoveredLogout ? -3 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFDC2626).withValues(alpha: 0.04),
              const Color(0xFFDC2626).withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hoveredLogout
                ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                : const Color(0xFFDC2626).withValues(alpha: 0.15),
            width: _hoveredLogout ? 1.5 : 1,
          ),
          boxShadow: _hoveredLogout
              ? [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesaptan Çıkış Yap',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Oturumunuz güvenli bir şekilde kapatılacaktır',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: _signOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
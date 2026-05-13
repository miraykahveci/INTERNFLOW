import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AcademicianProfileWeb extends StatefulWidget {
  const AcademicianProfileWeb({super.key});

  @override
  State<AcademicianProfileWeb> createState() => _AcademicianProfileWebState();
}

class _AcademicianProfileWebState extends State<AcademicianProfileWeb> {
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
  String _email = '';
  String _title = '';
  String _department = '';

  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _pendingCount = 0;
  int _totalCount = 0;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  int _hoveredStat = -1;
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
      final userEmail = Supabase.instance.client.auth.currentUser!.email ?? '';

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, title, department, email')
          .eq('user_id', userId)
          .single();

      final internships = await Supabase.instance.client
          .from('internship')
          .select('status')
          .eq('academician_id', userId);

      int approved = 0, rejected = 0, pending = 0;
      for (var intern in internships) {
        switch (intern['status']) {
          case 'approved':
          case 'active':
          case 'completed':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'pending':
            pending++;
            break;
        }
      }

      setState(() {
        _fullName = userResponse['full_name'] ?? '';
        _email = userResponse['email'] ?? userEmail;
        _title = userResponse['title'] ?? 'Akademisyen';
        _department = userResponse['department'] ?? '';
        _approvedCount = approved;
        _rejectedCount = rejected;
        _pendingCount = pending;
        _totalCount = internships.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profil verisi yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
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
                          Expanded(child: _buildStatCard(0, Icons.pending_actions_outlined, '$_pendingCount', 'Onay Bekleyen', const Color(0xFFEA580C))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(1, Icons.check_circle_outline, '$_approvedCount', 'Onaylanan', const Color(0xFF16A34A))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(2, Icons.cancel_outlined, '$_rejectedCount', 'Reddedilen', const Color(0xFFDC2626))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildStatCard(3, Icons.people_outline, '$_totalCount', 'Toplam Başvuru', purpleGlow)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 2-column layout
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LEFT: Profile info
                            Expanded(flex: 5, child: _buildProfileInfoCard()),
                            const SizedBox(width: 20),
                            // RIGHT: Preferences
                            Expanded(flex: 7, child: _buildPreferencesCard()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout
                      _buildLogoutCard(),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'InternFlow v1.0.0',
                          style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12, fontWeight: FontWeight.w500),
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBC02D), Color(0xFFF9A825)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 14),
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
                              Icon(Icons.star, color: Color(0xFFFBC02D), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'STAJ KOMİSYON BAŞKANI',
                                style: TextStyle(color: Color(0xFFFBC02D), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '$_title $_fullName',
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
          _buildInfoRow(Icons.badge_outlined, 'Unvan', _title),
          _buildInfoDivider(),
          _buildInfoRow(Icons.school_outlined, 'Akademik Birim', _department),
          _buildInfoDivider(),
          _buildInfoRow(Icons.email_outlined, 'E-posta', _email.isNotEmpty ? _email : 'Belirtilmemiş'),
          _buildInfoDivider(),
          _buildInfoRow(Icons.workspace_premium_outlined, 'Görev', 'Staj Komisyon Başkanı'),
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
    return Container(height: 1, color: const Color(0xFFEEEEF2));
  }

  // ========== PREFERENCES CARD ==========
  Widget _buildPreferencesCard() {
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
                    Text('Tercihler ve Ayarlar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Bildirim ve tema ayarlarınızı yönetin', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionLabel('BİLDİRİMLER'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            Icons.notifications_outlined,
            'Bildirimler',
            'Yeni staj başvurularında uyar',
            _notificationsEnabled,
            (val) => setState(() => _notificationsEnabled = val),
          ),
          const SizedBox(height: 10),
          _buildSwitchTile(
            Icons.email_outlined,
            'E-posta Bildirimleri',
            'Önemli güncellemeler için e-posta gönder',
            true,
            (val) {},
          ),
          const SizedBox(height: 16),

          _buildSectionLabel('GÖRÜNÜM'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            Icons.dark_mode_outlined,
            'Karanlık Mod',
            'Koyu tema görünümünü etkinleştir',
            _darkModeEnabled,
            (val) => setState(() => _darkModeEnabled = val),
          ),
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

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: value ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: value ? primaryColor : textMuted, size: 20),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
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
                onTap: _logout,
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
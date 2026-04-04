import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
 
class AcademicianProfilePage extends StatefulWidget {
  const AcademicianProfilePage({super.key});
 
  @override
  State<AcademicianProfilePage> createState() => _AcademicianProfilePageState();
}
 
class _AcademicianProfilePageState extends State<AcademicianProfilePage> {
  final Color primaryColor = const Color(0xFF6A0F0F);
 
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _title = '';
  String _department = '';
 
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _pendingCount = 0;
 
  bool _notificationsEnabled = true;
 
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: Color(0xFF7F8C8D))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Color(0xFF95A5A6), fontWeight: FontWeight.bold)),
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
              backgroundColor: const Color(0xFFD32F2F),
              elevation: 0,
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
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }
 
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('Profilim', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // İsim
                Text(
                  '$_title $_fullName',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                // Unvan badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBC02D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Color(0xFFFBC02D), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'STAJ KOMİSYON BAŞKANI',
                        style: TextStyle(color: Color(0xFFFBC02D), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ONAY BEKLEYEN KART
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFE0B2), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Onay Bekleyen İşlem', style: TextStyle(color: Color(0xFFE65100), fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '$_pendingCount',
                                style: const TextStyle(color: Color(0xFFE65100), fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text('Aksiyon almanız bekleniyor', style: TextStyle(color: Color(0xFFFB8C00), fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.notifications_active, color: Color(0xFFF57C00), size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), 
 
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          value: _approvedCount.toString(),
                          label: 'Onaylanan',
                          color: const Color(0xFF2E7D32),
                          bgColor: Colors.white,
                          borderColor: const Color(0xFFC8E6C9),
                        ),
                      ),
                      const SizedBox(width: 16), 
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.cancel,
                          value: _rejectedCount.toString(),
                          label: 'Reddedilen',
                          color: const Color(0xFFC62828),
                          bgColor: Colors.white,
                          borderColor: const Color(0xFFFFCDD2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
 
                  // HESAP & BİLGİLER
                  _buildSectionTitle('Hesap & Bilgiler'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: 'E-Posta Adresi',
                          subtitle: _email,
                          showDivider: true,
                        ),
                        _buildInfoTile(
                          icon: Icons.school_outlined,
                          title: 'Akademik Birim',
                          subtitle: _department,
                          showDivider: true,
                        ),
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          title: 'Unvan',
                          subtitle: _title,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
 
                  // TERCİHLER
                  _buildSectionTitle('Tercihler'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_none_outlined,
                          title: 'Bildirimler',
                          subtitle: 'Yeni staj başvurularında uyar',
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
 
                  // ÇIKIŞ BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 22),
                      label: const Text(
                        'ÇIKIŞ YAP',
                        style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // VERSİYON
                  const Center(
                    child: Text('InternFlow v1.0.0', style: TextStyle(color: Color(0xFF95A5A6), fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ========== BÖLÜM BAŞLIĞI ==========
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), letterSpacing: 0.3),
        ),
      ],
    );
  }
 
  // ========== İSTATİSTİK KARTI ==========
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
 
  // ========== BİLGİ SATIRI ==========
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Icon(icon, color: const Color(0xFF7F8C8D), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 80, color: const Color(0xFFF1F2F6), thickness: 1.5),
      ],
    );
  }
 
  // ========== SWITCH SATIRI ==========
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Icon(icon, color: const Color(0xFF7F8C8D), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: primaryColor,
                activeTrackColor: primaryColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 80, color: const Color(0xFFF1F2F6), thickness: 1.5),
      ],
    );
  }
}
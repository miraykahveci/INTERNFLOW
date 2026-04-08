import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart'; 

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  bool _isLoading = true;
  String _fullName = '';
  String _department = '';
  String _internshipStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
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
          .select('status')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _fullName = userResponse['full_name'] ?? 'Öğrenci';
        _department = userResponse['department'] ?? 'Bölüm Bilgisi Yok';
        _internshipStatus = internshipResponse?['status'] ?? 'none';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profil verisi çekilemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  
  String _getStatusBadgeText() {
    switch (_internshipStatus) {
      case 'none':
        return '⚪ Başvuru Bekleniyor';
      case 'pending':
        return '🟠 Onay Bekliyor';
      case 'approved':
        return '🟡 Belge Bekleniyor';
      case 'active':
        return '🟢 Staj Sürecinde';
      case 'completed':
        return '🔵 Staj Tamamlandı';
      default:
        return '⚪ Durum Bilinmiyor';
    }
  }

  Future<void> _signOut() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: BoxDecoration(
                   color: primaryColor,
                   borderRadius: const BorderRadius.only(
                   bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      const Text(
                        'Profilim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {}, 
                      )
                    ],
                  ),
                ),

               
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        

                        Card(
                          elevation: 8,
                          color: const Color(0xFF37474F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        _fullName.isNotEmpty ? _fullName[0] : '?',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFB8C00),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _department,
                                        style: const TextStyle(
                                          color: Color(0xFFCFD8DC),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF3E0),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusBadgeText(),
                                              style: const TextStyle(
                                                color: Color(0xFFF57C00),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF546E7A),
                                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: const [
                                                Text('GANO:', style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 10, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 4),
                                                Text('3.20', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        
                        Row(
                          children: [
                            _buildStatCard(value: '1/2', label: 'Staj', valueColor: const Color(0xFFB71C1C), labelColor: const Color(0xFFE57373), bgColor: const Color(0xFFFFEBEE)),
                            const SizedBox(width: 8),
                            _buildStatCard(value: '20', label: 'İş Günü', valueColor: const Color(0xFFE65100), labelColor: const Color(0xFFFFB74D), bgColor: const Color(0xFFFFF3E0)),
                            const SizedBox(width: 8),
                            _buildStatCard(value: '%85', label: 'Başarı', valueColor: const Color(0xFF1B5E20), labelColor: const Color(0xFF81C784), bgColor: const Color(0xFFE8F5E9)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        
                        const Text(
                          'Kariyer Rozetleri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBadgeItem(icon: Icons.star, title: 'İlk Adım', subtitle: 'Başvuru\nTamamlandı', iconColor: const Color(0xFFFFD700), bgColor: const Color(0xFFFFF8E1), isActive: _internshipStatus != 'none'),
                            _buildBadgeItem(icon: Icons.work, title: 'Stajyer', subtitle: 'Süreç\nAktif', iconColor: const Color(0xFF2196F3), bgColor: const Color(0xFFE3F2FD), isActive: _internshipStatus == 'active' || _internshipStatus == 'completed'),
                            _buildBadgeItem(icon: Icons.school, title: 'Mezun Adayı', subtitle: 'Belgeler\nBekleniyor', iconColor: const Color(0xFFBDBDBD), bgColor: const Color(0xFFEEEEEE), isActive: false),
                          ],
                        ),
                        const SizedBox(height: 24),

                        
                        Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Text('Hesap Bilgileri', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              _buildMenuItem(icon: Icons.history, title: 'Staj Geçmişi'),
                              
                              const Divider(height: 1, color: Color(0xFFF5F5F5)),
                              
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Text('Uygulama Ayarları', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              _buildMenuItem(icon: Icons.notifications_active, title: 'Bildirim Ayarları'),
                              const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 16, endIndent: 16),
                              _buildMenuItem(icon: Icons.lock_outline, title: 'Gizlilik ve KVKK'),
                              const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 16, endIndent: 16),
                              _buildMenuItem(icon: Icons.account_balance, title: 'E-Devlet Kapısı'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEE),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ÇIKIŞ YAP',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Oturumunuz güvenli bir şekilde kapatılacaktır.',
                            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  

  Widget _buildStatCard({required String value, required String label, required Color valueColor, required Color labelColor, required Color bgColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: labelColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem({required IconData icon, required String title, required String subtitle, required Color iconColor, required Color bgColor, required bool isActive}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? bgColor : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isActive ? iconColor : Colors.grey[400], size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF424242) : Colors.grey)),
        const SizedBox(height: 2),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF455A64)),
      title: Text(title, style: const TextStyle(color: Color(0xFF424242), fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFBDBDBD)),
      onTap: () {},
    );
  }
}
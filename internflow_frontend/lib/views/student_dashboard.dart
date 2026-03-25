import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'application_form_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  String _fullName = '';
  String _department = '';
  bool _isLoading = true;

  // Başvuru durumu
  Map<String, dynamic>? _internshipData;
  String _internshipStatus = 'none'; // none, pending, approved, rejected, active, completed

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Kullanıcı bilgilerini çek
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, department')
          .eq('user_id', userId)
          .single();

      // En son başvuruyu çek
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

  // Yol haritası adımlarının durumunu belirle
  bool _isStepCompleted(int step) {
    switch (step) {
      case 1: // Başvuru Oluştur
        return _internshipStatus != 'none';
      case 2: // Akademisyen Onayı
        return _internshipStatus == 'approved' ||
            _internshipStatus == 'active' ||
            _internshipStatus == 'completed';
      case 3: // SGK / Sigorta Girişi
        return _internshipStatus == 'active' ||
            _internshipStatus == 'completed';
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
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ÜST HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, $_firstName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _department,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Text(
                          _firstName.isNotEmpty ? _firstName[0] : '?',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE İÇERİK
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BAŞVURU DURUMU VEYA YENİ BAŞVURU
                        _buildApplicationCard(),
                        const SizedBox(height: 24),

                        // STAJ YOL HARİTASI
                        const Text(
                          'Staj Yol Haritası',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildRoadmapItem(
                                step: 1,
                                text: '1. Başvuru Oluştur',
                              ),
                              _buildRoadmapDivider(),
                              _buildRoadmapItem(
                                step: 2,
                                text: '2. Akademisyen Onayı',
                              ),
                              _buildRoadmapDivider(),
                              _buildRoadmapItem(
                                step: 3,
                                text: '3. SGK / Sigorta Girişi',
                              ),
                              _buildRoadmapDivider(),
                              _buildRoadmapItem(
                                step: 4,
                                text: '4. Staj Dönemi',
                              ),
                              _buildRoadmapDivider(),
                              _buildRoadmapItem(
                                step: 5,
                                text: '5. Defter Teslimi & AI Analiz',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // BELGE ŞABLONLARI
                        const Text(
                          'Belge Şablonları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDocumentCard(
                                icon: Icons.edit_document,
                                title: 'Staj Defteri',
                                subtitle: 'Word İndir',
                                color: primaryColor,
                              ),
                              _buildDocumentCard(
                                icon: Icons.picture_as_pdf,
                                title: 'Kabul Formu',
                                subtitle: 'PDF İndir',
                                color: const Color(0xFF1976D2),
                              ),
                              _buildDocumentCard(
                                icon: Icons.info_outline,
                                title: 'Sigorta',
                                subtitle: 'Bilgi Al',
                                color: const Color(0xFF388E3C),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DUYURULAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Duyurular',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Tümünü Gör',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '📢 2026 Yaz Stajı başvuruları 15 Mayıs\'ta sona erecektir.',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // ALT NAVİGASYON
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
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

  // ========== BAŞVURU KARTI ==========
  Widget _buildApplicationCard() {
    // Başvuru yoksa veya reddedildiyse → Yeni başvuru butonu
    if (_internshipStatus == 'none' || _internshipStatus == 'rejected') {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_internshipStatus == 'rejected') ...[
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
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Önceki başvurunuz reddedildi. Yeni başvuru yapabilirsiniz.',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                'Yeni Staj Başlat',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yaz dönemi veya dönem içi staj sürecini başlatmak için başvurunu oluştur.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApplicationFormPage(),
                      ),
                    );
                    if (result == true) {
                      _loadAllData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Başvuru Formunu Gönder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Formu gönderdikten sonra düzenleme yapılamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    // Başvuru varsa → Durum kartı
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _internshipData?['company_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.15),
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
                color: _getStatusColor().withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: _getStatusColor()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_internshipData != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${_internshipData!['start_date']} - ${_internshipData!['end_date']}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== YOL HARİTASI ==========
  Widget _buildRoadmapItem({
    required int step,
    required String text,
  }) {
    final isCompleted = _isStepCompleted(step);
    final isCurrent = _isCurrentStep(step);

    IconData icon;
    Color iconColor;

    if (isCompleted) {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF2E7D32);
    } else if (isCurrent) {
      icon = Icons.radio_button_checked;
      iconColor = primaryColor;
    } else {
      icon = Icons.lock;
      iconColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isCompleted || isCurrent ? 16 : 15,
              fontWeight:
                  isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted
                  ? const Color(0xFF2E7D32)
                  : isCurrent
                      ? primaryColor
                      : Colors.grey,
            ),
          ),
        ),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Şu an',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoadmapDivider() {
    return Container(
      width: 2,
      height: 20,
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      color: Colors.grey[300],
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 140,
      height: 100,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}